const std = @import("std");
const rl = @import("raylib");
const lua = @import("lua");

const renderer = @import("./renderer.zig");
const lua_api = @import("./lua_api/api.zig");
const lua_app_api = @import("./lua_api/app.zig");

const Lua = lua.Lua;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const screenWidth = 800;
    const screenHeight = 450;

    rl.setConfigFlags(.{
        .vsync_hint = true,
        .msaa_4x_hint = true,
        .window_highdpi = true,
    });

    rl.initWindow(screenWidth, screenHeight, "folly");
    defer rl.closeWindow();

    rl.setWindowState(.{
        .window_resizable = true,
    });

    try renderer.init(alloc);
    defer renderer.deinit();

    var L = try Lua.init(alloc);
    defer L.deinit();

    L.openLibs();
    lua_api.loadLibraries(L);

    lua_api.doFile(L, "editor/core/init.luau", null) catch |err| {
        std.debug.print("lua err: {}\n", .{err});
    };

    rl.pollInputEvents();

    while (!rl.windowShouldClose()) {
        if (lua_app_api.callMainLoop(L)) renderer.endRedraw();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        renderer.drawFrame();
    }
}
