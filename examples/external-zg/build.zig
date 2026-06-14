const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "external-zg-consumer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const prettytable = b.dependency("prettytable", .{
        .target = target,
        .optimize = optimize,
        .unicode_backend = .external_zg,
    });
    const zg = b.dependency("zg", .{
        .target = target,
        .optimize = optimize,
    });

    const prettytable_mod = prettytable.module("prettytable");
    prettytable_mod.addImport("DisplayWidth", zg.module("DisplayWidth"));

    exe.root_module.addImport("prettytable", prettytable_mod);

    b.installArtifact(exe);
}
