const std = @import("std");
const Module = std.Build.Module;
const Mode = std.builtin.OptimizeMode;
const ResolvedTarget = std.Build.ResolvedTarget;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const zg = b.dependency("zg", .{});

    const module = b.addModule("prettytable", .{
        .root_source_file = b.path("src/lib.zig"),
    });

    module.addImport("DisplayWidth", zg.module("DisplayWidth"));

    const lib = b.addLibrary(.{
        .name = "prettytable-zig",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Docs
    const docs_step = b.step("docs", "Emit docs");
    const docs_install = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&docs_install.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const main_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    main_tests.root_module.addImport("DisplayWidth", zg.module("DisplayWidth"));

    const run_main_tests = b.addRunArtifact(main_tests);

    const format_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/format.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    format_tests.root_module.addImport("DisplayWidth", zg.module("DisplayWidth"));
    const run_format_tests = b.addRunArtifact(format_tests);

    const cell_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cell.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    cell_tests.root_module.addImport("DisplayWidth", zg.module("DisplayWidth"));
    const run_cell_tests = b.addRunArtifact(cell_tests);

    const row_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/row.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    row_tests.root_module.addImport("DisplayWidth", zg.module("DisplayWidth"));
    const run_row_tests = b.addRunArtifact(row_tests);

    const table_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/table.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    table_tests.root_module.addImport("DisplayWidth", zg.module("DisplayWidth"));
    const run_table_tests = b.addRunArtifact(table_tests);

    const style_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/style.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    style_tests.root_module.addImport("DisplayWidth", zg.module("DisplayWidth"));
    const run_style_tests = b.addRunArtifact(style_tests);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build test`
    // This will evaluate the `test` step rather than the default, which is "install".
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
    test_step.dependOn(&run_format_tests.step);
    test_step.dependOn(&run_cell_tests.step);
    test_step.dependOn(&run_row_tests.step);
    test_step.dependOn(&run_table_tests.step);
    test_step.dependOn(&run_style_tests.step);

    buildExample(b, optimize, target, module, zg, &.{ "basic", "format", "multiline", "align", "read", "style", "unicode" });
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn buildExample(b: *std.Build, optimize: Mode, target: ResolvedTarget, module: *Module, zg: *std.Build.Dependency, comptime source: []const []const u8) void {
    inline for (source) |s| {
        const exe = b.addExecutable(.{
            .name = s,
            .root_module = b.createModule(.{
                .root_source_file = b.path("examples/" ++ s ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        exe.root_module.addImport("prettytable", module);
        exe.root_module.addImport("DisplayWidth", zg.module("DisplayWidth"));

        // This declares intent for the executable to be installed into the
        // standard location when the user invokes the "install" step (the default
        // step when running `zig build`).
        b.installArtifact(exe);

        // const ex = b.addRunArtifact(exe);
        // example_step.dependOn(&ex.step);
    }
}
