const std = @import("std");
const lua = @import("lua");

const api = @import("api.zig");

const Lua = lua.Lua;

fn lParseJSON(L: *Lua) i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const json = L.checkString(1);

    const parsed = std.json.parseFromSlice(std.json.Value, alloc, json, .{}) catch return 0;
    defer parsed.deinit();

    pushJsonValue(L, parsed.value, alloc) catch return 0;

    return 1;
}

fn pushJsonValue(L: *Lua, value: std.json.Value, allocator: std.mem.Allocator) !void {
    switch (value) {
        .null => L.pushNil(),
        .bool => |b| L.pushBoolean(b),
        .integer => |i| L.pushInteger(@intCast(i)),
        .float => |f| L.pushNumber(f),
        .string => |s| _ = L.pushString(s),
        .array => |a| {
            L.createTable(@intCast(a.items.len), 0);
            for (a.items, 1..) |item, i| {
                try pushJsonValue(L, item, allocator);
                L.rawSetIndex(-2, @intCast(i));
            }
        },
        .object => |o| {
            L.createTable(0, @intCast(o.count()));
            var it = o.iterator();
            while (it.next()) |entry| {
                _ = L.pushString(entry.key_ptr.*);
                try pushJsonValue(L, entry.value_ptr.*, allocator);
                L.setTable(-3);
            }
        },
        .number_string => |s| {
            _ = L.pushString(s);
            _ = try L.toNumber(1);
        },
    }
}

fn lStringifyJSON(L: *Lua) i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const jsonValue = luaValueToJson(L, 1, alloc) catch return 0;
    defer freeJsonValue(jsonValue, alloc);

    const json = std.json.stringifyAlloc(alloc, jsonValue, .{}) catch return 0;
    defer alloc.free(json);

    _ = L.pushString(json);

    return 1;
}

fn luaValueToJson(L: *Lua, index: i32, allocator: std.mem.Allocator) !std.json.Value {
    switch (L.typeOf(index)) {
        .nil => return .null,
        .boolean => return .{ .bool = L.toBoolean(index) },
        .number => {
            const int = L.toInteger(index) catch {
                return .{ .float = try L.toNumber(index) };
            };
            return .{ .integer = int };
        },
        .string => {
            const str = try L.toString(index);
            const end = std.mem.indexOfSentinel(u8, 0, str);
            const duped = try allocator.dupe(u8, str[0..end]);
            return .{ .string = duped };
        },
        .table => {
            var isArray = true;
            var len: usize = 0;

            L.pushValue(index);
            L.pushNil();
            while (isArray and L.next(-2)) {
                L.pop(1);
                const int = L.toInteger(-1) catch blk: {
                    isArray = false;
                    break :blk 0;
                };
                if (int <= 0) {
                    isArray = false;
                }
                len += 1;
                L.pop(1);
            }
            L.pop(1);

            if (isArray) {
                var array = std.ArrayList(std.json.Value).init(allocator);
                errdefer {
                    for (array.items) |item| {
                        freeJsonValue(item, allocator);
                    }
                    array.deinit();
                }

                L.pushValue(index);
                for (1..len + 1) |i| {
                    L.pushInteger(@intCast(i));
                    _ = L.getTable(-2);
                    const value = try luaValueToJson(L, -1, allocator);
                    try array.append(value);
                    L.pop(1);
                }
                L.pop(1);

                return .{ .array = array };
            } else {
                var obj = std.json.ObjectMap.init(allocator);
                errdefer {
                    var it = obj.iterator();
                    while (it.next()) |entry| {
                        allocator.free(entry.key_ptr.*);
                        freeJsonValue(entry.value_ptr.*, allocator);
                    }
                    obj.deinit();
                }

                L.pushValue(index);
                L.pushNil();
                while (L.next(-2)) {
                    const value = try luaValueToJson(L, -1, allocator);

                    const key = try L.toString(-2);
                    const end = std.mem.indexOfSentinel(u8, 0, key);
                    const keyStr = try allocator.dupe(u8, key[0..end]);

                    try obj.put(keyStr, value);
                    L.pop(1);
                }
                L.pop(1);

                return .{ .object = obj };
            }
        },
        else => return error.UnsupportedType,
    }
}

fn freeJsonValue(value: std.json.Value, allocator: std.mem.Allocator) void {
    switch (value) {
        .string => |s| allocator.free(s),
        .array => |a| {
            for (a.items) |item| {
                freeJsonValue(item, allocator);
            }
            a.deinit();
        },
        .object => |o| {
            var it = o.iterator();
            while (it.next()) |entry| {
                allocator.free(entry.key_ptr.*);
                freeJsonValue(entry.value_ptr.*, allocator);
            }
            @constCast(&o).deinit();
        },
        else => {},
    }
}

const funcs = [_]lua.FnReg{
    .{ .name = "parse", .func = lua.wrap(lParseJSON) },
    .{ .name = "stringify", .func = lua.wrap(lStringifyJSON) },
};

pub fn registerLuaFunctions(L: *Lua, libraryName: [:0]const u8) void {
    L.registerFns(libraryName, &funcs);
}
