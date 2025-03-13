const lua = @import("lua");
const rl = @import("raylib");

const Lua = lua.Lua;

fn lIsKeyDown(L: *Lua) i32 {
    L.pushBoolean(rl.isKeyDown(@enumFromInt(L.checkInteger(1))));

    return 1;
}

fn lPollChar(L: *Lua) i32 {
    L.pushInteger(rl.getCharPressed());

    return 1;
}

const funcs = [_]lua.FnReg{
    .{ .name = "isKeyDown", .func = lua.wrap(lIsKeyDown) },
    .{ .name = "pollChar", .func = lua.wrap(lPollChar) },
};

pub fn registerLuaFunctions(L: *Lua) void {
    L.registerFns(null, &funcs);
}
