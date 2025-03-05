const rl = @import("raylib");
const std = @import("std");
const freetype = @import("freetype");

const fRenderer = @import("font_renderer.zig");

pub const RenderCommand = union(enum) {
    text: Text,
    rect: Rect,

    pub const Text = struct {
        text: fRenderer.Text,
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

var drawCmdBuf: ?std.ArrayList(RenderCommand) = null;
var redrawCmdBuf: ?std.ArrayList(RenderCommand) = null;

var activeBuf: ?*std.ArrayList(RenderCommand) = null;
var passiveBuf: ?*std.ArrayList(RenderCommand) = null;

pub fn init(allocator: std.mem.Allocator) !void {
    alloc = allocator;
    
    drawCmdBuf = std.ArrayList(RenderCommand).init(allocator);
    redrawCmdBuf = std.ArrayList(RenderCommand).init(allocator);

    passiveBuf = &(drawCmdBuf.?);
    activeBuf = &(redrawCmdBuf.?);
}

pub fn deinit() void {
    if (drawCmdBuf == null) @panic("Command buffer not initialized!");
    
    drawCmdBuf.?.deinit();
    redrawCmdBuf.?.deinit();

    fRenderer.deinitFonts();
}

pub fn drawText(content: [*:0]const u8, x: f32, y: f32, fontId: u32, size: u32, color: rl.Color) !void {
    if (alloc == null) @panic("Allocator not initialized!");
    
    var text = try fRenderer.Text.init(alloc.?);
    try text.setText(fontId, std.mem.span(content), .{ .x = x, .y = y }, size);

    try activeBuf.?.*.append(RenderCommand {
        .text = .{
            .text = text,
            .color = color
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

    for (activeBuf.?.*.items) |command| {
        if (command == .text) {
            var text = command.text.text;
            text.deinit();
        }
    }

    activeBuf.?.*.clearAndFree();
}

pub fn loadFont(filename: [:0]const u8) !u32 {
    if (alloc == null) @panic("Allocator not initialized!");

    const i = try fRenderer.loadFont(filename.ptr);

    return i;
}

pub fn drawFrame() void {
    for (passiveBuf.?.*.items) |command| {
        switch (command) {
            .text => |cmd| {
                cmd.text.draw(cmd.color);
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