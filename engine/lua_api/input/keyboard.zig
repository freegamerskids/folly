const lua = @import("lua");
const rl = @import("raylib");

const Lua = lua.Lua;

fn lPollKey(L: *Lua) i32 {
    L.pushInteger(@intFromEnum(rl.getKeyPressed()));

    return 1;
}

fn lPollChar(L: *Lua) i32 {
    L.pushInteger(rl.getCharPressed());

    return 1;
}

const funcs = [_]lua.FnReg{
    .{ .name = "pollKey", .func = lua.wrap(lPollKey) },
    .{ .name = "pollChar", .func = lua.wrap(lPollChar) },
};

pub fn registerLuaFunctions(L: *Lua) void {
    L.registerFns(null, &funcs);
}
