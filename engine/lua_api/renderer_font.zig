const std = @import("std");
const ziglua = @import("ziglua");
const rl = @import("raylib");

const api = @import("./api.zig");
const renderer = @import("../renderer.zig");

const Lua = ziglua.Lua;

fn lLoad(L: *Lua) i32 {
    const filename = L.checkString(1);
    
    const fontId = renderer.loadFont(filename) catch return 0;
    L.pushInteger(@intCast(fontId));
    
    return 1;
}

const funcs = [_]ziglua.FnReg{
    .{ .name = "load", .func = ziglua.wrap(lLoad) },
};

pub fn registerLuaFunctions(L: *Lua) i32 {
    L.setFuncs(&funcs, 0);
    L.pushValue(-1);
    L.setField(-2, "__index");
    return 1;
}