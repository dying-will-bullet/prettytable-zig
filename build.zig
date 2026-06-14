const std = @import("std");
const Module = std.Build.Module;
const Mode = std.builtin.OptimizeMode;
const ResolvedTarget = std.Build.ResolvedTarget;

pub const UnicodeBackend = enum {
    zg,
    external_zg,
    uucode,
    external_uucode,
};

const UnicodeModules = struct {
    display_width: ?*Module = null,
    uucode: ?*Module = null,
};

fn resolveUnicodeModules(b: *std.Build, target: ResolvedTarget, optimize: Mode, unicode_backend: UnicodeBackend) UnicodeModules {
    return switch (unicode_backend) {
        .zg => blk: {
            const zg = b.dependency("zg", .{});
            break :blk .{ .display_width = zg.module("DisplayWidth") };
        },
        .uucode => blk: {
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
            break :blk .{ .uucode = uucode.module("uucode") };
        },
        .external_zg, .external_uucode => .{},
    };
}

fn addPrettytableImports(module: *Module, options_module: *Module, unicode_modules: UnicodeModules) void {
    module.addImport("options", options_module);
    if (unicode_modules.display_width) |display_width| {
        module.addImport("DisplayWidth", display_width);
    }
    if (unicode_modules.uucode) |uucode| {
        module.addImport("uucode", uucode);
    }
}

fn createPrettytableRootModule(b: *std.Build, target: ResolvedTarget, optimize: Mode, source_path: []const u8, options_module: *Module, unicode_modules: UnicodeModules) *Module {
    const root_module = b.createModule(.{
        .root_source_file = b.path(source_path),
        .target = target,
        .optimize = optimize,
    });
    addPrettytableImports(root_module, options_module, unicode_modules);
    return root_module;
}

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

    const unicode_backend = b.option(
        UnicodeBackend,
        "unicode_backend",
        "Unicode backend used for string display width calculations",
    ) orelse .zg;

    const options = b.addOptions();
    options.addOption(UnicodeBackend, "unicode_backend", unicode_backend);
    const options_module = options.createModule();

    const unicode_modules = resolveUnicodeModules(b, target, optimize, unicode_backend);

    const module = b.addModule("prettytable", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    addPrettytableImports(module, options_module, unicode_modules);

    // External backend mode is for dependency consumers that manually provide
    // the required imports on `prettytable.module("prettytable")`.
    // Skip local docs/tests/examples because those entry points do not perform
    // that wiring.
    switch (unicode_backend) {
        .external_zg, .external_uucode => return,
        else => {},
    }

    const lib_root_module = createPrettytableRootModule(
        b,
        target,
        optimize,
        "src/lib.zig",
        options_module,
        unicode_modules,
    );

    const lib = b.addLibrary(.{
        .name = "prettytable-zig",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_module = lib_root_module,
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
        .root_module = createPrettytableRootModule(
            b,
            target,
            optimize,
            "src/lib.zig",
            options_module,
            unicode_modules,
        ),
    });
    const run_main_tests = b.addRunArtifact(main_tests);

    const format_tests = b.addTest(.{
        .root_module = createPrettytableRootModule(
            b,
            target,
            optimize,
            "src/format.zig",
            options_module,
            unicode_modules,
        ),
    });
    const run_format_tests = b.addRunArtifact(format_tests);

    const cell_tests = b.addTest(.{
        .root_module = createPrettytableRootModule(
            b,
            target,
            optimize,
            "src/cell.zig",
            options_module,
            unicode_modules,
        ),
    });
    const run_cell_tests = b.addRunArtifact(cell_tests);

    const row_tests = b.addTest(.{
        .root_module = createPrettytableRootModule(
            b,
            target,
            optimize,
            "src/row.zig",
            options_module,
            unicode_modules,
        ),
    });
    const run_row_tests = b.addRunArtifact(row_tests);

    const table_tests = b.addTest(.{
        .root_module = createPrettytableRootModule(
            b,
            target,
            optimize,
            "src/table.zig",
            options_module,
            unicode_modules,
        ),
    });
    const run_table_tests = b.addRunArtifact(table_tests);

    const style_tests = b.addTest(.{
        .root_module = createPrettytableRootModule(
            b,
            target,
            optimize,
            "src/style.zig",
            options_module,
            unicode_modules,
        ),
    });
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

    const examples_step = b.step("examples", "Run all examples");
    buildExample(b, optimize, target, module, examples_step, &.{ "basic", "format", "multiline", "align", "read", "style", "unicode" });
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn buildExample(b: *std.Build, optimize: Mode, target: ResolvedTarget, module: *Module, examples_step: *std.Build.Step, comptime source: []const []const u8) void {
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

        // This declares intent for the executable to be installed into the
        // standard location when the user invokes the "install" step (the default
        // step when running `zig build`).
        b.installArtifact(exe);

        const run = b.addRunArtifact(exe);
        examples_step.dependOn(&run.step);
    }
}
