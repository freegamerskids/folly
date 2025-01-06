const ziglua = @import("ziglua");
const rl = @import("raylib");

const Lua = ziglua.Lua;

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

const funcs = [_]ziglua.FnReg{
    .{ .name = "getPosition", .func = ziglua.wrap(lGetMousePosition) },
    .{ .name = "getWheelMove", .func = ziglua.wrap(lGetMouseWheelMove) },
};

pub fn registerLuaFunctions(L: *Lua) void {
    L.registerFns(null, &funcs);
}