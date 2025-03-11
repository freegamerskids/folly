const std = @import("std");
const lua = @import("lua");
const rl = @import("raylib");

const api = @import("api.zig");
const http = @import("../http.zig");

const Lua = lua.Lua;

// TODO: use this function to import fonts
fn lRequire(L: *Lua) i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const path: [:0]const u8 = L.checkString(1);
    if (path.len == 0) return 0;

    if (!std.mem.eql(u8, path[0..1], "@")) { // require in cwd
        var info: lua.DebugInfo = undefined;

        L.getInfo(1, .{ .s = true }, &info);

        const full_src_path = alloc.dupeZ(u8, info.source) catch return 0;
        defer alloc.free(full_src_path);

        const dir = std.fs.path.dirname(full_src_path).?;

        const full_path = std.fmt.allocPrintZ(alloc, "editor/{s}/{s}.luau", .{ dir, path }) catch |err| return api.make_lua_err("allocPrintZ full_path cwd", err);
        defer alloc.free(full_path);

        api.doFile(L, full_path, .{ .args = 0, .results = 1, .msg_handler = 0 }) catch |err| return api.make_lua_err("dofile cwd", err);

        return 1;
    }

    const full_path = std.fmt.allocPrintZ(alloc, "editor/{s}.luau", .{path[1..]}) catch |err| return api.make_lua_err("allocPrintZ full_path @", err);
    defer alloc.free(full_path);

    api.doFile(L, full_path, .{ .args = 0, .results = 1, .msg_handler = 0 }) catch |err| return api.make_lua_err("dofile @", err);

    return 1;
}

fn lWait(L: *Lua) i32 {
    std.time.sleep(@as(u64, @intFromFloat((L.optNumber(1) orelse rl.getFrameTime()) * std.time.ns_per_s)));

    return 0;
}

fn lFetch(L: *Lua) i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const url = std.Uri.parse(L.checkString(1)) catch return api.make_lua_err("invalid url", error.InvalidUri);
    if (L.isNoneOrNil(2)) {
        return 0;
    }

    _ = L.getField(2, "method");
    var method: std.http.Method = @enumFromInt(std.http.Method.parse(L.checkString(-1)));
    L.pop(1);

    _ = L.getField(2, "headers");

    L.pushNil();
    var is_ua_set = false;
    var headers = std.ArrayList(std.http.Header).init(alloc);
    while (L.next(-2)) {
        const key = L.checkString(-2);
        const value = L.checkString(-1);
        if (std.ascii.eqlIgnoreCase(key, "user-agent")) {
            is_ua_set = true;
        }
        headers.append(.{ .name = key, .value = value }) catch return api.make_lua_err("fetch headers", error.OutOfMemory);
        L.pop(1);
    }
    defer headers.deinit();
    L.pop(1);

    _ = L.getField(2, "body");
    const body: ?[:0]const u8 = if (L.isNoneOrNil(-1)) null else L.checkString(-1);
    if (body == null) {
        method = .GET;
    }
    L.pop(1);

    var server_header_buffer: [16 * 1024]u8 = undefined;

    var req = std.http.Client.open(http.getClient(), method, url, .{
        .server_header_buffer = &server_header_buffer,
        .headers = .{
            .user_agent = if (is_ua_set) .omit else .default,
            .authorization = .omit,
        },
        .extra_headers = headers.items,
    }) catch return api.make_lua_err("failed to open client", error.OpenFailed);
    defer req.deinit();

    if (body) |payload| req.transfer_encoding = .{ .content_length = payload.len };

    req.send() catch return api.make_lua_err("failed to send request", error.SendFailed);

    if (body) |payload| req.writeAll(payload) catch return api.make_lua_err("failed to write payload", error.WriteFailed);

    req.finish() catch return api.make_lua_err("failed to finish request", error.FinishFailed);
    req.wait() catch return api.make_lua_err("failed to wait for request", error.WaitFailed);

    const max_append_size = 2 * 1024 * 1024;
    var list = std.ArrayList(u8).init(alloc);
    defer list.deinit();
    req.reader().readAllArrayList(@constCast(&list), max_append_size) catch return api.make_lua_err("failed to read all", error.ReadAllFailed);

    L.newTable();

    _ = L.pushString("status");
    _ = L.pushInteger(@intFromEnum(req.response.status));
    L.setTable(-3);

    _ = L.pushString("body");
    _ = L.pushString(list.items);
    L.setTable(-3);

    _ = L.pushString("headers");
    L.newTable();

    var iter = req.response.iterateHeaders();
    while (iter.next()) |header| {
        _ = L.pushString(header.name);
        _ = L.pushString(header.value);
        L.setTable(-3);
    }
    
    L.setTable(-3);

    return 1;
}

const funcs = [_]lua.FnReg{
    .{ .name = "require", .func = lua.wrap(lRequire) },
    .{ .name = "wait", .func = lua.wrap(lWait) },
    .{ .name = "fetch", .func = lua.wrap(lFetch) },
};

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    _ = libraryName;

    for (funcs) |func| {
        L.register(func.name, func.func.?);
    }
}
