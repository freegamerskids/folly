const std = @import("std");
const ziglua = @import("ziglua");

// LIBRARIES
const globals = @import("global.zig");
const renderer_api = @import("renderer.zig");
const input_api = @import("input.zig");
const app_api = @import("app.zig");

const Lua = ziglua.Lua;

const libReg = struct {
    name: [:0]const u8,
    func: ?*const fn(L: *Lua, libraryName: [:0]const u8) void
};

const libraries = [_]libReg{
    .{ .name = "Global", .func = globals.registerLuaFunctions },
    .{ .name = "Renderer", .func = renderer_api.registerLuaFunctions },
    .{ .name = "Input", .func = input_api.registerLuaFunctions },
    .{ .name = "App", .func = app_api.registerLuaFunctions },
};

pub fn loadLibraries(L: *Lua) void {
    for (libraries) |lib| {
        lib.func.?(L, lib.name);
    }
}

fn doBytecode(L: *Lua, alloc: std.mem.Allocator, chunkname: []u8, bytecode: []const u8, pcall_args: Lua.ProtectedCallArgs) !void {
    const cn = try alloc.dupeZ(u8, chunkname);
    defer alloc.free(cn);

    try L.loadBytecode(cn, bytecode);
    try L.protectedCall(pcall_args);
}

pub fn doFile(L: *Lua, filename: [:0]const u8, pcall_args: ?Lua.ProtectedCallArgs) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const args: Lua.ProtectedCallArgs = pcall_args orelse .{
        .args = 0,
        .results = 0,
        .msg_handler = 0,
    };

    const src = std.fs.cwd().readFileAlloc(alloc, filename, std.math.maxInt(u32)) catch {
        std.log.err("failed to open lua file {s}", .{filename});
        return;
    };
    defer alloc.free(src);

    const srcZ = try alloc.dupeZ(u8, src);
    defer alloc.free(srcZ);

    const bytecode = try ziglua.compile(alloc, srcZ, .{});
    defer alloc.free(bytecode);

    const chunkname = try alloc.dupeZ(u8, filename);
    defer alloc.free(chunkname);

    if (std.mem.indexOf(u8, chunkname, "/")) |slash_pos| {
        const after_slash = chunkname[slash_pos+1..];
        
        if (std.mem.lastIndexOf(u8, after_slash, ".")) |dot_pos| {
            const trimmed = after_slash[0..dot_pos];
            
            var result = try alloc.alloc(u8, trimmed.len + 1);
            defer alloc.free(result);
            @memcpy(result[0..trimmed.len], trimmed); 
            result[trimmed.len] = 0;

            try doBytecode(L, alloc, result, bytecode, args);
        } else {
            const result = try alloc.dupeZ(u8, after_slash);
            defer alloc.free(result);
            std.debug.print("Result: {s}\n", .{result});

            try doBytecode(L, alloc, result, bytecode, args);
        }
    } else {
        try doBytecode(L, alloc, chunkname, bytecode, args);
    }
}