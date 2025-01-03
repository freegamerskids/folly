const std = @import("std");
const ziglua = @import("ziglua");
const rl = @import("raylib");

const Lua = ziglua.Lua;

var mainLoopRef: i32 = 0;

pub fn callMainLoop(L: *Lua) bool {
    if (mainLoopRef == 0) @panic("Main loop not set!");

    _ = L.rawGetIndex(ziglua.registry_index, mainLoopRef);

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

const funcs = [_]ziglua.FnReg{
    .{ .name = "setMainLoop", .func = ziglua.wrap(lSetMainLoop) },
};

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    L.registerFns(libraryName, &funcs);
}