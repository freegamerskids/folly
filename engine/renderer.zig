const rl = @import("raylib");
const std = @import("std");

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

var drawCmdBuf: ?std.ArrayList(RenderCommand) = null;
var redrawCmdBuf: ?std.ArrayList(RenderCommand) = null;

var activeBuf: ?*std.ArrayList(RenderCommand) = null;
var passiveBuf: ?*std.ArrayList(RenderCommand) = null;

var stuffCmdBuf: ?std.ArrayList(StuffCommand) = null;

var fontList: ?std.ArrayList(rl.Font) = null;

pub fn init(allocator: std.mem.Allocator) !void {
    alloc = allocator;
    
    drawCmdBuf = std.ArrayList(RenderCommand).init(allocator);
    redrawCmdBuf = std.ArrayList(RenderCommand).init(allocator);

    passiveBuf = &(drawCmdBuf.?);
    activeBuf = &(redrawCmdBuf.?);

    stuffCmdBuf = std.ArrayList(StuffCommand).init(allocator);

    fontList = std.ArrayList(rl.Font).init(allocator);
}

pub fn deinit() void {
    if (drawCmdBuf == null) @panic("Command buffer not initialized!");
    
    drawCmdBuf.?.deinit();
    redrawCmdBuf.?.deinit();

    stuffCmdBuf.?.deinit();

    fontList.?.deinit();
}

pub fn drawText(content: [*:0]const u8, x: f32, y: f32, fontId: u32, fontSize: f32, color: rl.Color) !void {
    if (alloc == null) @panic("Allocator not initialized!");

    try activeBuf.?.*.append(RenderCommand {
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

    try activeBuf.?.*.append(RenderCommand {
        .rect = .{
            .x = x, .y = y,
            .width = width, .height = height,
            .color = color
        }
    });
}

pub fn endRedraw() void {
    if (alloc == null) @panic("Allocator not initialized!");

    std.mem.swap(*std.ArrayList(RenderCommand), &(passiveBuf.?), &(activeBuf.?));

    activeBuf.?.*.clearAndFree();
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
    for (passiveBuf.?.*.items) |command| {
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
