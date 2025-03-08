const lua = @import("lua");
const rl = @import("raylib");

const Lua = lua.Lua;

fn lGetMousePosition(L: *Lua) i32 {
    const mousePos = rl.getMousePosition();

    L.pushNumber(@floatCast(mousePos.x));
    L.pushNumber(@floatCast(mousePos.y));

    return 2;
}

fn lGetMouseWheelMove(L: *Lua) i32 {
    const mouseWheelMove = rl.getMouseWheelMoveV();

    L.pushNumber(@floatCast(mouseWheelMove.x));
    L.pushNumber(@floatCast(mouseWheelMove.y));

    return 2;
}

const funcs = [_]lua.FnReg{
    .{ .name = "getPosition", .func = lua.wrap(lGetMousePosition) },
    .{ .name = "getWheelMove", .func = lua.wrap(lGetMouseWheelMove) },
};

pub fn registerLuaFunctions(L: *Lua) void {
    L.registerFns(null, &funcs);
}
