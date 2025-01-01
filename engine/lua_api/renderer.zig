const ziglua = @import("ziglua");
const rl = @import("raylib");

const api = @import("./api.zig");
const renderer = @import("../renderer.zig");

const Lua = ziglua.Lua;

fn getColor(L: *Lua, argIndex: i32, default: u8) rl.Color {
    if (L.isNoneOrNil(argIndex)) {
        return rl.Color.init(default, default, default, 255);
    }

    _ = L.getField(argIndex, "red");
    _ = L.getField(argIndex, "green");
    _ = L.getField(argIndex, "blue");
    _ = L.getField(argIndex, "alpha");

    defer L.pop(4);

    return rl.Color.init(
        @as(u8,@intFromFloat(L.checkNumber(-4))),
        @as(u8,@intFromFloat(L.checkNumber(-3))),
        @as(u8,@intFromFloat(L.checkNumber(-2))),
        @as(u8,@intFromFloat(L.optNumber(-1) orelse 255))
    );
}

fn lDrawText(L: *Lua) i32 {
    const font = L.checkUserdata(renderer.FontWrapper, 1, api.font_type);
    renderer.drawText(
        L.checkString(2), 
        @floatCast(L.checkNumber(3)), 
        @floatCast(L.checkNumber(4)), 
        font.*.font, 
        @floatCast(L.checkNumber(5)), 
        getColor(L, 6, 255)
    ) catch return 0;

    return 0;
}

fn lDrawRect(L: *Lua) i32 {
    renderer.drawRect(
        @as(i32,@intFromFloat(L.checkNumber(1))), 
        @as(i32,@intFromFloat(L.checkNumber(2))), 
        @as(i32,@intFromFloat(L.checkNumber(3))),
        @as(i32,@intFromFloat(L.checkNumber(4))), 
        getColor(L, 5, 255)
    ) catch return 0;

    return 0;
}

fn lBeginRedraw(L: *Lua) i32 {
    _ = L;

    renderer.beginRedraw() catch return 0;

    return 0;
}

const funcs = [_]ziglua.FnReg{
    .{ .name = "draw_rect", .func = ziglua.wrap(lDrawRect) },
    .{ .name = "draw_text", .func = ziglua.wrap(lDrawText) },
    .{ .name = "begin_redraw", .func = ziglua.wrap(lBeginRedraw) },
};

const renderer_font = @import("./renderer_font.zig");

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    L.registerFns(libraryName, &funcs);
    _ = renderer_font.registerLuaFunctions(L);
    L.setField(-2, "font");
}