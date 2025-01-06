const ziglua = @import("ziglua");

const Lua = ziglua.Lua;

const keyboard = @import("./input/keyboard.zig");
const mouse = @import("./input/mouse.zig");

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    L.newTable();

    _ = L.pushStringZ("Keyboard");
    L.newTable();
    keyboard.registerLuaFunctions(L);
    L.setTable(-3);

    _ = L.pushStringZ("Mouse");
    L.newTable();
    mouse.registerLuaFunctions(L);
    L.setTable(-3);

    L.setGlobal(libraryName);
}