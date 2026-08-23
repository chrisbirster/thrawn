const std = @import("std");
const package = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "version", package.version);

    const thrawn = b.addModule("thrawn", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    thrawn.addOptions("build_options", build_options);

    const demo = b.addExecutable(.{
        .name = "thrawn-demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "thrawn", .module = thrawn }},
        }),
    });
    b.installArtifact(demo);

    const run_demo = b.addRunArtifact(demo);
    run_demo.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_demo.addArgs(args);
    const run_step = b.step("run", "Run the Thrawn demonstration CLI");
    run_step.dependOn(&run_demo.step);

    const module_tests = b.addTest(.{ .root_module = thrawn });
    const run_module_tests = b.addRunArtifact(module_tests);

    const test_step = b.step("test", "Run unit and public API tests");
    test_step.dependOn(&run_module_tests.step);
    inline for (.{
        "tests/root.zig",
        "tests/resolve_test.zig",
        "tests/options_test.zig",
        "tests/help_test.zig",
        "tests/validation_test.zig",
        "tests/completion_test.zig",
    }) |path| {
        const tests = addTest(b, thrawn, target, optimize, path);
        test_step.dependOn(&tests.step);
    }

    const examples_step = b.step("examples", "Compile all Thrawn examples");
    addExample(b, examples_step, thrawn, target, optimize, "thrawn-example-basic", "examples/basic/main.zig");
    addExample(b, examples_step, thrawn, target, optimize, "thrawn-example-nested", "examples/nested/main.zig");
    addExample(b, examples_step, thrawn, target, optimize, "thrawn-example-options", "examples/options/main.zig");
    addExample(b, examples_step, thrawn, target, optimize, "thrawn-example-completion", "examples/completion/main.zig");
}

fn addTest(
    b: *std.Build,
    thrawn: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    path: []const u8,
) *std.Build.Step.Run {
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "thrawn", .module = thrawn }},
        }),
    });
    return b.addRunArtifact(tests);
}

fn addExample(
    b: *std.Build,
    step: *std.Build.Step,
    thrawn: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
    path: []const u8,
) void {
    const example = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "thrawn", .module = thrawn }},
        }),
    });
    step.dependOn(&example.step);
}
