/// HTTP client singleton

const std = @import("std");

pub const Client = std.http.Client;

var client: ?Client = null;

pub fn init(allocator: std.mem.Allocator) void {
    client = .{
        .allocator = allocator
    };
}

pub fn deinit() void {
    if (client) |*c| {
        c.deinit();
    }
    client = null;
}

pub fn getClient() *Client {
    return &(client.?);
}