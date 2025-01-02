const std = @import("std");
const rl = @import("raylib");
const ziglua = @import("ziglua");

const renderer = @import("./renderer.zig");
const lua_api = @import("./lua_api/api.zig");

const Lua = ziglua.Lua;

fn startLua() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var L = try Lua.init(alloc);
    defer L.deinit();

    L.openLibs();
    lua_api.loadLibraries(L);

    lua_api.doFile(L,"editor/core/init.luau", null) catch |err| {
        std.debug.print("lua err: {}\n", .{err});
    };
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "folly");
    defer rl.closeWindow();

    rl.setWindowState(.{
        .window_resizable = true,
    });

    rl.setTargetFPS(60);

    try renderer.init(alloc);
    defer renderer.deinit();

    _ = try std.Thread.spawn(.{}, startLua, .{});

    rl.pollInputEvents();
    rl.enableEventWaiting();

    while (!rl.windowShouldClose()) {
        renderer.processStuffCmdBuf();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
        renderer.drawFrame();
    }
}