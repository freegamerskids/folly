const std = @import("std");
const ziglua = @import("ziglua");

const api = @import("api.zig");

const Lua = ziglua.Lua;

fn lReadFile(L: *Lua) i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const path = L.checkString(1);

    const realPath = std.fs.cwd().realpathAlloc(alloc, path) catch |err| return api.make_lua_err("realpathAlloc read", err);
    defer alloc.free(realPath);

    std.debug.print("realPath: {s}\n", .{realPath});

    const file = std.fs.openFileAbsolute(realPath, .{}) catch return 0;

    const fileContents = file.readToEndAlloc(alloc, 1_024*1_024*1_024) catch return 0; // 1 GiB
    defer alloc.free(fileContents);

    _ = L.pushString(fileContents);

    return 1;
}

fn lWriteFile(L: *Lua) i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const path = L.checkString(1);

    const realPath = std.fs.cwd().realpathAlloc(alloc, path) catch return 0;
    defer alloc.free(realPath);

    const file = std.fs.openFileAbsolute(realPath, .{}) catch return 0;

    const contents = L.checkString(2);
    file.writeAll(contents[0..contents.len-1]) catch return 0;

    return 0;
}

const funcs = [_]ziglua.FnReg{
    .{ .name = "read", .func = ziglua.wrap(lReadFile) },
    .{ .name = "write", .func = ziglua.wrap(lWriteFile) },
};

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    L.registerFns(libraryName, &funcs);
}