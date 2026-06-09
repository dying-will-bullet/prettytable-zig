const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "external-uucode-consumer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const prettytable = b.dependency("prettytable", .{
        .target = target,
        .optimize = optimize,
        .unicode_backend = .external_uucode,
    });
    const uucode = b.dependency("uucode", .{
        .target = target,
        .optimize = optimize,
        .fields = @as([]const []const u8, &.{
            "east_asian_width",
            "grapheme_break",
            "general_category",
            "is_emoji_presentation",
        }),
    });

    const prettytable_mod = prettytable.module("prettytable");
    prettytable_mod.addImport("uucode", uucode.module("uucode"));

    exe.root_module.addImport("prettytable", prettytable_mod);

    b.installArtifact(exe);
}
