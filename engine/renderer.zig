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
        font: FontWrapper,
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

var alloc: ?std.mem.Allocator = null;
var commandBuf: ?std.ArrayList(RenderCommand) = null;

pub fn init(allocator: std.mem.Allocator) !void {
    alloc = allocator;
    
    commandBuf = std.ArrayList(RenderCommand).init(alloc.?);
}

pub fn deinit() void {
    if (commandBuf == null) @panic("Command buffer not initialized!");
    commandBuf.?.deinit();
}

pub fn drawText(content: [*:0]const u8, x: f32, y: f32, font: rl.Font, fontSize: f32, color: rl.Color) !void {
    if (alloc == null) @panic("Allocator not initialized!");

    try commandBuf.?.append(RenderCommand {
        .text = .{
            .content = content,
            .x = x, .y = y,
            .font = .{ .font = font }, .fontSize = fontSize,
            .color = color,
        }
    });
}

pub fn drawRect(x: i32, y: i32, width: i32, height: i32, color: rl.Color) !void {
    if (alloc == null) @panic("Allocator not initialized!");

    try commandBuf.?.append(RenderCommand {
        .rect = .{
            .x = x, .y = y,
            .width = width, .height = height,
            .color = color
        }
    });
}

pub fn beginRedraw() !void {
    if (alloc == null) @panic("Allocator not initialized!");

    commandBuf.?.clearAndFree();
}

pub fn drawFrame() void {
    for (commandBuf.?.items) |command| {
        switch (command) {
            .text => |cmd| {
                rl.drawTextEx(
                    cmd.font.font,
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