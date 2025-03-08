const std = @import("std");
const lua = @import("lua");
const rl = @import("raylib");

const Lua = lua.Lua;

var mainLoopRef: i32 = 0;

pub fn callMainLoop(L: *Lua) bool {
    if (mainLoopRef == 0) @panic("Main loop not set!");

    _ = L.rawGetIndex(lua.registry_index, mainLoopRef);

    L.remove(1);
    L.pushValue(-1);

    L.protectedCall(.{
        .args = 1,
        .results = 1,
        .msg_handler = 0,
    }) catch {
        const err = L.toString(-1) catch "";

        std.debug.print("main loop err: {s}\n", .{err});

        return false;
    };

    return L.toBoolean(-1);
}

fn lSetMainLoop(L: *Lua) i32 {
    const ref = L.ref(1) catch 0;
    mainLoopRef = ref;

    return 0;
}

fn lGetFPS(L: *Lua) i32 {
    L.pushNumber(@as(f64, @floatFromInt(rl.getFPS())));

    return 1;
}

fn lSetFPS(L: *Lua) i32 {
    const fps = L.checkInteger(1);

    rl.setTargetFPS(fps);

    return 0;
}

fn lGetWindowSize(L: *Lua) i32 {
    L.pushInteger(rl.getScreenWidth());
    L.pushInteger(rl.getScreenHeight());

    return 2;
}

const funcs = [_]lua.FnReg{
    .{ .name = "setMainLoop", .func = lua.wrap(lSetMainLoop) },
    .{ .name = "getFPS", .func = lua.wrap(lGetFPS) },
    .{ .name = "setFPS", .func = lua.wrap(lSetFPS) },
    .{ .name = "getWindowSize", .func = lua.wrap(lGetWindowSize) },
};

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    L.registerFns(libraryName, &funcs);
}
