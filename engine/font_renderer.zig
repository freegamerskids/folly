const std = @import("std");
const rl = @import("raylib");
const freetype = @import("freetype");
const harfbuzz = @import("harfbuzz");
const Atlas = @import("./atlas/Atlas.zig");

const px_per_pt = 4.0 / 3.0;

var ft: freetype.Library = undefined;
var ft_ready = false;

pub fn initFreetype() !void {
    if (!ft_ready) {
        ft = try freetype.Library.init();
        ft_ready = true;
    }
}

const RGBA32 = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

const Glyph = struct {
    glyph_index: u32,
    cluster: u32,
    advance: rl.Vector2,
    offset: rl.Vector2,
};

pub const RenderedGlyph = struct {
    bitmap: ?[]const RGBA32,
    width: u32,
    height: u32,
};

const BuiltGlyph = struct {
    pos: rl.Vector2,
    size: rl.Vector2,
    uv: Atlas.Region,
};

const GlyphKey = struct {
    index: u32,
    size: u32,
};

const RegionMap = std.AutoArrayHashMapUnmanaged(GlyphKey, Atlas.Region);

const TextRun = struct {
    font_size: f32 = 16.0,
    pixel_density: u8 = 1,

    buffer: harfbuzz.Buffer,
    index: usize = 0,
    infos: []harfbuzz.GlyphInfo = undefined,
    positions: []harfbuzz.GlyphPosition = undefined,

    pub fn init() !TextRun {
        return .{
            .buffer = harfbuzz.Buffer.init().?,
        };
    }

    pub fn deinit(self: *const TextRun) void {
        self.buffer.deinit();
    }

    pub fn addText(self: *const TextRun, text: []const u8) void {
        self.buffer.addUTF8(text, 0, null);
    }

    pub fn next(self: *TextRun) ?Glyph {
        if (self.index >= self.infos.len) {
            return null;
        }

        const info = self.infos[self.index];
        const pos = self.positions[self.index];
        
        self.index += 1;

        return Glyph{
            .glyph_index = info.codepoint,
            .cluster = info.cluster,
            .advance = rl.Vector2.init(@as(f32, @floatFromInt(pos.x_advance)), @as(f32, @floatFromInt(pos.y_advance))).divide(rl.Vector2.init(64.0, 64.0)),
            .offset = rl.Vector2.init(@as(f32, @floatFromInt(pos.x_offset)), @as(f32, @floatFromInt(pos.y_offset))).divide(rl.Vector2.init(64.0, 64.0)),
        };
    }
};

const Font = struct {
    ft_face: freetype.Face,

    bitmap: std.ArrayListUnmanaged(RGBA32) = .{},

    pub fn init(path: [*:0]const u8) !Font {
        try initFreetype();
        return .{
            .ft_face = try ft.createFace(path, 0),
        };
    }

    pub fn deinit(self: *Font, allocator: std.mem.Allocator) void {
        self.ft_face.deinit();
        self.bitmap.deinit(allocator);
    }

    pub fn shape(self: *const Font, shaper: *TextRun) anyerror!void {
        shaper.buffer.guessSegmentProps();

        const font_size_pt = shaper.font_size / px_per_pt;
        const font_size_pt_frac: i32 = @intFromFloat(font_size_pt * 64.0);
        self.ft_face.setCharSize(font_size_pt_frac, font_size_pt_frac, 0, 0) catch return error.RenderError;

        const hb_face = harfbuzz.Face.fromFreetypeFace(self.ft_face);
        const hb_font = harfbuzz.Font.init(hb_face);
        defer hb_font.deinit();

        hb_font.setScale(font_size_pt_frac, font_size_pt_frac);
        hb_font.setPTEM(font_size_pt);

        hb_font.shape(shaper.buffer, null);

        shaper.index = 0;
        shaper.infos = shaper.buffer.getGlyphInfos();
        shaper.positions = shaper.buffer.getGlyphPositions() orelse return error.OutOfMemory;

        for (shaper.positions, shaper.infos) |*pos, info| {
            const glyph_index = info.codepoint;
            self.ft_face.loadGlyph(glyph_index, .{ .render = false }) catch return error.RenderError;
            const glyph = self.ft_face.glyph();
            const metrics = glyph.metrics();
            pos.*.x_offset += @intCast(metrics.horiBearingX);
            pos.*.y_offset += @intCast(metrics.horiBearingY);
        }
    }

    pub fn render(self: *Font, allocator: std.mem.Allocator, glyph_index: u32) anyerror!RenderedGlyph {
        self.ft_face.loadGlyph(glyph_index, .{ .render = true }) catch return error.RenderError;

        const glyph = self.ft_face.glyph();
        const glyph_bitmap = glyph.bitmap();
        const buffer = glyph_bitmap.buffer();
        const width = glyph_bitmap.width();
        const height = glyph_bitmap.rows();
        const margin = 1;

        if (buffer == null) return RenderedGlyph{
            .bitmap = null,
            .width = width + (margin * 2),
            .height = height + (margin * 2),
        };

        self.bitmap.clearRetainingCapacity();
        const num_pixels = (width + (margin * 2)) * (height + (margin * 2));

        self.bitmap.ensureTotalCapacity(allocator, num_pixels) catch return error.RenderError;
        self.bitmap.resize(allocator, num_pixels) catch return error.RenderError;
        for (self.bitmap.items, 0..) |*data, i| {
            const x = i % (width + (margin * 2));
            const y = i / (width + (margin * 2));
            if (x < margin or x > (width + margin) or y < margin or y > (height + margin)) {
                data.* = RGBA32{ .r = 0, .g = 0, .b = 0, .a = 0 };
            } else {
                const alpha = buffer.?[((y - margin) * width + (x - margin)) % buffer.?.len];
                data.* = RGBA32{ .r = 255, .g = 255, .b = 255, .a = alpha };
            }
        }

        return RenderedGlyph{
            .bitmap = self.bitmap.items,
            .width = width + (margin * 2),
            .height = height + (margin * 2),
        };
    }
};

var fonts: std.hash_map.AutoHashMap(u32, Font) = std.hash_map.AutoHashMap(u32, Font).init(std.heap.page_allocator);

pub fn loadFont(font_path: [*:0]const u8) !u32 {
    const font_id = fonts.count();
    std.debug.print("font_id: {}; font: {s}\n", .{font_id, std.mem.span(font_path)});
    const font = Font.init(font_path) catch |err| {
        std.debug.print("[ENGINE] (Font.init) error: {any}\n", .{err});
        return error.FontLoadError;
    };

    try fonts.put(font_id, font);
    return font_id;
}

pub fn deinitFonts() void {
    var it = fonts.valueIterator();
    while (it.next()) |font| font.deinit(std.heap.page_allocator);
    fonts.deinit();
}

pub const Text = struct {
    allocator: std.mem.Allocator,
    atlas: Atlas,
    atlas_texture: ?rl.Texture2D = null,
    text_run: ?TextRun = null,
    regions: RegionMap = .{},
    built_text: struct {
        glyphs: std.ArrayListUnmanaged(BuiltGlyph) = .{},
    } = .{},

    pub fn init(allocator: std.mem.Allocator) !Text {
        return .{
            .allocator = allocator,
            .atlas = try Atlas.init(allocator, 1024, .rgba), // TODO: configurable size
        };
    }

    pub fn deinit(self: *Text) void {
        self.atlas.deinit(self.allocator);
        self.regions.deinit(self.allocator);
        self.built_text.glyphs.deinit(self.allocator);
        if (self.atlas_texture) |texture| {
            texture.unload();
        }
        if (self.text_run) |text_run| {
            text_run.deinit();
        }
    }

    pub fn setText(self: *Text, font_id: u32, text: []const u8, pos: rl.Vector2, size: ?u32) !void {
        var font = fonts.get(font_id) orelse return error.FontNotFound;

        const newline_char_index = freetype.c.FT_Get_Char_Index(font.ft_face.handle, '\n');

        var text_run = try TextRun.init();
        errdefer text_run.deinit();
        text_run.font_size = @floatFromInt(size orelse 16);

        text_run.addText(text);
        try font.shape(&text_run);

        var texture_update = false;
        var cursor = pos;
        while (text_run.next()) |glyph| {
            if (glyph.glyph_index == newline_char_index) {
                cursor.x = pos.x;
                cursor.y += text_run.font_size;
                continue;
            }

            const region = try self.regions.getOrPut(self.allocator, .{ 
                .index = glyph.glyph_index, 
                .size = @intFromFloat(text_run.font_size)
            });

            if (!region.found_existing) {
                const rendered = try font.render(self.allocator, glyph.glyph_index);
                if (rendered.bitmap) |bitmap| {
                    var glyph_atlas_region = try self.atlas.reserve(self.allocator, rendered.width, rendered.height);
                    self.atlas.set(glyph_atlas_region, @as([*]const u8, @ptrCast(bitmap.ptr))[0 .. bitmap.len * 4]);
            
                    texture_update = true;

                    const margin = 1;
                    glyph_atlas_region.x += margin;
                    glyph_atlas_region.y += margin;
                    glyph_atlas_region.width -= margin * 2;
                    glyph_atlas_region.height -= margin * 2;
                    region.value_ptr.* = glyph_atlas_region;
                } else {
                    region.value_ptr.* = .{
                        .width = 0,
                        .height = 0,
                        .x = 0,
                        .y = 0,
                    };
                }
            }

            const r = region.value_ptr.*;
            const s = rl.Vector2.init(@floatFromInt(r.width), @floatFromInt(r.height));
            try self.built_text.glyphs.append(self.allocator, .{
                .pos = rl.Vector2.init(
                    cursor.x + glyph.offset.x,
                    cursor.y - glyph.offset.y,
                ),
                .size = s,
                .uv = r,
            });

            cursor.x += glyph.advance.x;
        }

        if (self.atlas_texture) |texture| {
            if (texture_update) {
                texture.unload();
                self.atlas_texture = rl.loadTextureFromImage(.{
                    .data = @constCast(self.atlas.data.ptr),
                    .width = @intCast(self.atlas.size),
                    .height = @intCast(self.atlas.size),
                    .format = .uncompressed_r8g8b8a8,
                    .mipmaps = 1,
                });
            }
        } else {
            self.atlas_texture = rl.loadTextureFromImage(.{
                .data = @constCast(self.atlas.data.ptr),
                .width = @intCast(self.atlas.size),
                .height = @intCast(self.atlas.size),
                .format = .uncompressed_r8g8b8a8,
                .mipmaps = 1,
            });
        }

        self.text_run = text_run;
    }

    pub fn draw(self: *const Text, color: rl.Color) void {
        if (self.atlas_texture) |texture| {
            for (self.built_text.glyphs.items) |glyph| {
                texture.drawPro(
                    rl.Rectangle.init(
                        @floatFromInt(glyph.uv.x), 
                        @floatFromInt(glyph.uv.y), 
                        @floatFromInt(glyph.uv.width), 
                        @floatFromInt(glyph.uv.height)
                    ),
                    rl.Rectangle.init(
                        glyph.pos.x, 
                        glyph.pos.y, 
                        glyph.size.x, 
                        glyph.size.y
                    ),
                    rl.Vector2.init(0.0,0.0), 
                    0.0, 
                    color
                );
            }
        }
    }
};

pub fn measureText(font_id: u32, text: []const u8, size: ?u32) !rl.Vector2 {
    var font = fonts.get(font_id) orelse return error.FontNotFound;

    const newline_char_index = freetype.c.FT_Get_Char_Index(font.ft_face.handle, '\n');

    var text_run = try TextRun.init();
    defer text_run.deinit();
    text_run.font_size = @floatFromInt(size orelse 16);

    text_run.addText(text);
    try font.shape(&text_run);

    var max_x: f32 = 0.0;
    var cursor = rl.Vector2.init(0.0, text_run.font_size);
    while (text_run.next()) |glyph| {
        if (glyph.glyph_index == newline_char_index) {
            if (cursor.x > max_x) {
                max_x = cursor.x;
            }
            cursor.x = 0.0;
            cursor.y += text_run.font_size;
            continue;
        }

        cursor.x += glyph.advance.x;
    }

    return cursor;
}