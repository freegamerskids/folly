const rl = @import("raylib");
const std = @import("std");

pub const FontWrapper = struct {
    font: rl.Font
};

pub const RenderCommand = union(enum) {
    text: Text,
    rect: Rect,

    pub const Text = struct {
        content: [*:0]const u8,
        x: f32,
        y: f32,
        fontId: u32,
        fontSize: f32,
        color: rl.Color,
    };

    pub const Rect = struct {
        x: i32,
        y: i32,
        width: i32,
        height: i32,
        color: rl.Color,
    };
};

// TODO: call this better (its 11 pm and i wanna sleep)
pub const StuffCommand = union(enum) {
    font: Font,

    pub const Font = struct {
        filename: [:0]const u8,
    };
};

var alloc: ?std.mem.Allocator = null;

var renCmdBuf: ?std.ArrayList(RenderCommand) = null;
var stuffCmdBuf: ?std.ArrayList(StuffCommand) = null;

var fontList: ?std.ArrayList(rl.Font) = null;

pub fn init(allocator: std.mem.Allocator) !void {
    alloc = allocator;
    
    renCmdBuf = std.ArrayList(RenderCommand).init(allocator);
    stuffCmdBuf = std.ArrayList(StuffCommand).init(allocator);

    fontList = std.ArrayList(rl.Font).init(allocator);
}

pub fn deinit() void {
    if (renCmdBuf == null) @panic("Command buffer not initialized!");
    
    renCmdBuf.?.deinit();
    stuffCmdBuf.?.deinit();

    fontList.?.deinit();
}

pub fn drawText(content: [*:0]const u8, x: f32, y: f32, fontId: u32, fontSize: f32, color: rl.Color) !void {
    if (alloc == null) @panic("Allocator not initialized!");

    try renCmdBuf.?.append(RenderCommand {
        .text = .{
            .content = content,
            .x = x, .y = y,
            .fontId = fontId, .fontSize = fontSize,
            .color = color,
        }
    });
}

pub fn drawRect(x: i32, y: i32, width: i32, height: i32, color: rl.Color) !void {
    if (alloc == null) @panic("Allocator not initialized!");

    try renCmdBuf.?.append(RenderCommand {
        .rect = .{
            .x = x, .y = y,
            .width = width, .height = height,
            .color = color
        }
    });
}

pub fn beginRedraw() !void {
    if (alloc == null) @panic("Allocator not initialized!");

    renCmdBuf.?.clearAndFree();
}

var loadedFonts: u32 = 0;

pub fn loadFont(filename: [:0]const u8) !u32 {
    if (alloc == null) @panic("Allocator not initialized!");

    try stuffCmdBuf.?.append(StuffCommand {
        .font = .{
            .filename = filename
        }
    });

    loadedFonts += 1;

    return loadedFonts - 1;
}

pub fn drawFrame() void {
    for (renCmdBuf.?.items) |command| {
        switch (command) {
            .text => |cmd| {
                rl.drawTextEx(
                    if (cmd.fontId + 1 > fontList.?.items.len) rl.getFontDefault() else fontList.?.items[cmd.fontId],
                    cmd.content,
                    .{ .x = cmd.x, .y = cmd.y },
                    cmd.fontSize,
                    1, // spacing
                    cmd.color
                );
            },
            .rect => |cmd| {
                rl.drawRectangle(
                    cmd.x, cmd.y,
                    cmd.width, cmd.height,
                    cmd.color
                );
            }
        }
    }
}

pub fn processStuffCmdBuf() void {
    for (stuffCmdBuf.?.items) |command| {
        switch (command) {
            .font => |cmd| {
                const rlFont = rl.loadFont(cmd.filename);
                fontList.?.append(rlFont) catch continue; // FIXME: this is dangerous
            }
        }
    }

    stuffCmdBuf.?.clearAndFree();
}
