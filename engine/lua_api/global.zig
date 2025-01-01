const std = @import("std");
const ziglua = @import("ziglua");

const api = @import("api.zig");

const Lua = ziglua.Lua;

fn make_lua_err(func: [:0]const u8, err: anytype) i32 {
    std.debug.print("lua_err in func {s}: {any}\n", .{func, err});
    return 0;
}

// TODO: use this function to import fonts
fn lRequire(L: *Lua) i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const path: [:0]const u8 = L.checkString(1);
    if (path.len == 0) return 0;

    if (!std.mem.eql(u8, path[0..1], "@")) { // require in cwd
        var info: ziglua.DebugInfo = undefined;

        L.getInfo(1, .{
            .s = true
        }, &info);

        var dir = alloc.dupeZ(u8, info.source) catch return 0;
        defer alloc.free(dir);

        if (std.mem.lastIndexOf(u8, dir, "/")) |last_slash_pos| {
            const trimmed = dir[0..last_slash_pos];

            const dirZ = alloc.dupeZ(u8, trimmed) 
                catch |err| return make_lua_err("dupeZ dirZ", err);
            defer alloc.free(dirZ);
            
            const full_path = std.fmt.allocPrintZ(alloc, "editor/{s}/{s}.luau", .{ dirZ, path }) 
                catch |err| return make_lua_err("allocPrintZ full_path cwd", err);
            defer alloc.free(full_path);

            api.doFile(L, full_path, .{
                .args = 0,
                .results = 1,
                .msg_handler = 0
            }) catch |err| return make_lua_err("dofile cwd", err);
            return 1;
        }
    }

    const full_path = std.fmt.allocPrintZ(alloc, "editor/{s}.luau", .{ path[1..] }) 
        catch |err| return make_lua_err("allocPrintZ full_path @", err);
    defer alloc.free(full_path);

    api.doFile(L, full_path, .{
        .args = 0,
        .results = 1,
        .msg_handler = 0
    }) catch |err| return make_lua_err("dofile @", err);

    return 1;
}

const funcs = [_]ziglua.FnReg{
    .{ .name = "require", .func = ziglua.wrap(lRequire) },
};

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    _ = libraryName;

    for (funcs) |func| {
        L.register(func.name, func.func.?);
    }
}