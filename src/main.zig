const granite = @import("granite");

pub fn main() !void {
    var app = granite.App.init(800, 450, "folly", "editor");

    try app.run();
}
