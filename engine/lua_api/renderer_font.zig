const ziglua = @import("ziglua");
const rl = @import("raylib");

const api = @import("./api.zig");
const renderer = @import("../renderer.zig");

const Lua = ziglua.Lua;

fn lLoad(L: *Lua) i32 {
    const filename = L.checkString(1);
    const font = L.newUserdata(renderer.FontWrapper);
    _ = L.getMetatableRegistry(api.font_type);
    L.setMetatable(-2);

    font.*.font = rl.loadFont(filename);

    return 1;
}

// Luau doesn't support __gc. FUCK YOU!!!
// fn lGc(L: *Lua) i32 {
//     const font = L.checkUserdata(renderer.FontWrapper, 1, api.font_type);
//     font.*.font.unload();
//     return 0;
// }

const funcs = [_]ziglua.FnReg{
    //.{ .name = "__gc", .func = ziglua.wrap(lGc) },
    .{ .name = "load", .func = ziglua.wrap(lLoad) },
    //.{ .name = null, .func = null }
};

pub fn registerLuaFunctions(L: *Lua) i32 {
    L.newMetatable(api.font_type) catch return 0;
    L.setFuncs(&funcs, 0);
    L.pushValue(-1);
    L.setField(-2, "__index");
    return 1;
}