const std = @import("std");
const rl = @import("raylib");
const ziglua = @import("ziglua");

const renderer = @import("./renderer.zig");
const lua_api = @import("./lua_api/api.zig");

const Lua = ziglua.Lua;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "fxd");
    defer rl.closeWindow();

    rl.setWindowState(.{
        .window_resizable = true,
    });

    //const font = rl.loadFont("./resources/JetBrainsMonoNerdFont.ttf");

    rl.setTargetFPS(240);

    try renderer.init(alloc);
    defer renderer.deinit();

    var L = try Lua.init(alloc);
    defer L.deinit();

    L.openLibs();
    lua_api.loadLibraries(L);

    lua_api.doFile(L,"editor/core/init.luau", null) catch |err| {
        std.debug.print("lua err: {}\n", .{err});
    };

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        //try renderer.beginRedraw();
        //try renderer.drawText(rl.textFormat("fps: %i", .{rl.getFPS()}), 200, 220, font, 32, rl.Color.black);

        //rl.drawTextEx(font, rl.textFormat("fps: %i", .{rl.getFPS()}), .{.x = 200, .y = 220}, 32, 1, rl.Color.black);
        renderer.drawFrame();
    }
}