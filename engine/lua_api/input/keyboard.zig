const ziglua = @import("ziglua");
const rl = @import("raylib");

const Lua = ziglua.Lua;

fn lPollKey(L: *Lua) i32 {
    L.pushInteger(@intFromEnum(rl.getKeyPressed()));

    return 1;
}

fn lPollChar(L: *Lua) i32 {
    L.pushInteger(rl.getCharPressed());

    return 1;
}

const funcs = [_]ziglua.FnReg{
    .{ .name = "pollKey", .func = ziglua.wrap(lPollKey) },
    .{ .name = "pollChar", .func = ziglua.wrap(lPollChar) },
};

pub fn registerLuaFunctions(L: *Lua) void {
    L.registerFns(null, &funcs);
}