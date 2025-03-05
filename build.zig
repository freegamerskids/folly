const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("engine/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "folly",
        .root_module = exe_mod,
    });

    // Raylib (via raylib-zig)
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .opengl_version = .auto,
    });

    const raylib = raylib_dep.module("raylib");
    //const raygui = raylib_dep.module("raygui"); 
    const raylib_artifact = raylib_dep.artifact("raylib");

    exe.linkLibrary(raylib_artifact);
    exe_mod.addImport("raylib", raylib);
    //exe_mod.addImport("raygui", raygui);

    // Luau (via Ziglua)
    const ziglua = b.dependency("ziglua", .{
        .target = target,
        .optimize = optimize,
        .lang = .luau,
    });

    exe_mod.addImport("ziglua", ziglua.module("ziglua"));

    // Freetype and Harfbuzz (via mach_freetype)
    const freetype_dep = b.dependency("mach_freetype", .{
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("freetype", freetype_dep.module("mach-freetype"));
    exe_mod.addImport("harfbuzz", freetype_dep.module("mach-harfbuzz"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
