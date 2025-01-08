const std = @import("std");
const ziglua = @import("ziglua");
const rl = @import("raylib");

const api = @import("api.zig");

const Lua = ziglua.Lua;

// TODO: use this function to import fonts
fn lRequire(L: *Lua) i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const path: [:0]const u8 = L.checkString(1);
    if (path.len == 0) return 0;

    if (!std.mem.eql(u8, path[0..1], "@")) { // require in cwd
        var info: ziglua.DebugInfo = undefined;

        L.getInfo(1, .{ .s = true }, &info);

        const full_src_path = alloc.dupeZ(u8, info.source) catch return 0;
        defer alloc.free(full_src_path);

        const dir = std.fs.path.dirname(full_src_path).?;
            
        const full_path = std.fmt.allocPrintZ(alloc, "editor/{s}/{s}.luau", .{ dir, path }) 
            catch |err| return api.make_lua_err("allocPrintZ full_path cwd", err);
        defer alloc.free(full_path);

        api.doFile(L, full_path, .{
            .args = 0,
            .results = 1,
            .msg_handler = 0
        }) catch |err| return api.make_lua_err("dofile cwd", err);
        
        return 1;
    }

    const full_path = std.fmt.allocPrintZ(alloc, "editor/{s}.luau", .{ path[1..] }) 
        catch |err| return api.make_lua_err("allocPrintZ full_path @", err);
    defer alloc.free(full_path);

    api.doFile(L, full_path, .{
        .args = 0,
        .results = 1,
        .msg_handler = 0
    }) catch |err| return api.make_lua_err("dofile @", err);

    return 1;
}

fn lWait(L: *Lua) i32 {
    std.time.sleep(@as(u64, @intFromFloat((L.optNumber(1) orelse rl.getFrameTime()) * std.time.ns_per_s)));

    return 0;
}

const funcs = [_]ziglua.FnReg{
    .{ .name = "require", .func = ziglua.wrap(lRequire) },
    .{ .name = "wait", .func = ziglua.wrap(lWait) },
};

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    _ = libraryName;

    for (funcs) |func| {
        L.register(func.name, func.func.?);
    }
}