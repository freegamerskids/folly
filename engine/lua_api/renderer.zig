const lua = @import("lua");
const rl = @import("raylib");

const api = @import("./api.zig");
const renderer = @import("../renderer.zig");
const font_renderer = @import("../font_renderer.zig");

const Lua = lua.Lua;

fn getColor(L: *Lua, argIndex: i32, default: u8) rl.Color {
    if (L.isNoneOrNil(argIndex)) {
        return rl.Color.init(default, default, default, 255);
    }

    _ = L.getField(argIndex, "red");
    _ = L.getField(argIndex, "green");
    _ = L.getField(argIndex, "blue");
    _ = L.getField(argIndex, "alpha");

    defer L.pop(4);

    return rl.Color.init(@as(u8, @intFromFloat(L.checkNumber(-4))), @as(u8, @intFromFloat(L.checkNumber(-3))), @as(u8, @intFromFloat(L.checkNumber(-2))), @as(u8, @intFromFloat(L.optNumber(-1) orelse 255)));
}

fn lDrawText(L: *Lua) i32 {
    renderer.drawText(L.checkString(2), @floatCast(L.checkNumber(3)), @floatCast(L.checkNumber(4)), @as(u32, if (L.checkInteger(1) < 0) 0 else @intCast(L.checkInteger(1))), @intFromFloat(L.checkNumber(5)), getColor(L, 6, 255)) catch return 0;

    return 0;
}

fn lDrawRect(L: *Lua) i32 {
    renderer.drawRect(@as(i32, @intFromFloat(L.checkNumber(1))), @as(i32, @intFromFloat(L.checkNumber(2))), @as(i32, @intFromFloat(L.checkNumber(3))), @as(i32, @intFromFloat(L.checkNumber(4))), getColor(L, 5, 255)) catch return 0;

    return 0;
}

fn lDrawRectOutline(L: *Lua) i32 {
    renderer.drawRectOutline(@floatCast(L.checkNumber(1)), @floatCast(L.checkNumber(2)), @floatCast(L.checkNumber(3)), @floatCast(L.checkNumber(4)), @floatCast(L.checkNumber(5)), getColor(L, 6, 255)) catch return 0;

    return 0;
}

fn lDrawRectRound(L: *Lua) i32 {
    renderer.drawRectRound(@floatCast(L.checkNumber(1)), @floatCast(L.checkNumber(2)), @floatCast(L.checkNumber(3)), @floatCast(L.checkNumber(4)), @floatCast(L.checkNumber(5)), getColor(L, 6, 255)) catch return 0;

    return 0;
}

fn lDrawRectRoundOutline(L: *Lua) i32 {
    renderer.drawRectRoundOutline(@floatCast(L.checkNumber(1)), @floatCast(L.checkNumber(2)), @floatCast(L.checkNumber(3)), @floatCast(L.checkNumber(4)), @floatCast(L.checkNumber(5)), @floatCast(L.checkNumber(6)), getColor(L, 7, 255)) catch return 0;

    return 0;
}

fn lDrawCircle(L: *Lua) i32 {
    renderer.drawCircle(@as(i32, @intFromFloat(L.checkNumber(1))), @as(i32, @intFromFloat(L.checkNumber(2))), @floatCast(L.checkNumber(3)), getColor(L, 4, 255)) catch return 0;

    return 0;
}

fn lDrawCircleOutline(L: *Lua) i32 {
    renderer.drawCircleOutline(@as(i32, @intFromFloat(L.checkNumber(1))), @as(i32, @intFromFloat(L.checkNumber(2))), @floatCast(L.checkNumber(3)), getColor(L, 4, 255)) catch return 0;

    return 0;
}

fn lMeasureText(L: *Lua) i32 {
    const font_id = @as(u32, @intCast(L.checkInteger(1)));
    const text = L.checkString(2);
    const size = @as(u32, @intCast(L.checkInteger(3)));

    const result = font_renderer.measureText(font_id, text, size) catch return 0;

    _ = L.pushNumber(result.x);
    _ = L.pushNumber(result.y);

    return 2;
}

const funcs = [_]lua.FnReg{
    .{ .name = "drawRect", .func = lua.wrap(lDrawRect) },
    .{ .name = "drawRectOutline", .func = lua.wrap(lDrawRectOutline) },
    .{ .name = "drawRectRound", .func = lua.wrap(lDrawRectRound) },
    .{ .name = "drawRectRoundOutline", .func = lua.wrap(lDrawRectRoundOutline) },

    .{ .name = "drawCircle", .func = lua.wrap(lDrawCircle) },
    .{ .name = "drawCircleOutline", .func = lua.wrap(lDrawCircleOutline) },

    .{ .name = "drawText", .func = lua.wrap(lDrawText) },
    .{ .name = "measureText", .func = lua.wrap(lMeasureText) },
};

const renderer_font = @import("./renderer_font.zig");

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    L.registerFns(libraryName, &funcs);
    _ = renderer_font.registerLuaFunctions(L);
    L.setField(-1, "Font");
}
