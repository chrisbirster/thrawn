const std = @import("std");
const th = @import("thrawn");

test "public API executes nested command with options" {
    const deploy_command: th.Command = .{
        .name = "deploy",
        .usage = "deploy <ship> [--dry-run]",
        .args = .{ .exact = 1 },
        .options = &.{.{ .long = "dry-run", .short = 'n' }},
        .handler = deploy,
    };
    const fleet_command: th.Command = .{
        .name = "fleet",
        .children = &.{&deploy_command},
    };
    const root_command: th.Command = .{
        .name = "demo",
        .children = &.{&fleet_command},
    };

    const args = [_][]const u8{ "fleet", "deploy", "destroyer", "--dry-run" };
    var stdout_buffer: [1024]u8 = undefined;
    var stderr_buffer: [1024]u8 = undefined;
    var stdout: std.Io.Writer = .fixed(&stdout_buffer);
    var stderr: std.Io.Writer = .fixed(&stderr_buffer);

    const code = try th.runArgs(std.testing.allocator, &root_command, &args, &stdout, &stderr);
    try std.testing.expectEqual(th.errors.success, code);
    try std.testing.expectEqualStrings("Would deploy destroyer.\n", stdout.buffered());
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);
}

test "public API reports unknown nested command" {
    const status_command: th.Command = .{ .name = "status", .handler = status };
    const fleet_command: th.Command = .{ .name = "fleet", .children = &.{&status_command} };
    const root_command: th.Command = .{ .name = "demo", .children = &.{&fleet_command} };
    const args = [_][]const u8{ "fleet", "statsu" };

    var stdout_buffer: [1024]u8 = undefined;
    var stderr_buffer: [2048]u8 = undefined;
    var stdout: std.Io.Writer = .fixed(&stdout_buffer);
    var stderr: std.Io.Writer = .fixed(&stderr_buffer);

    const code = try th.runArgs(std.testing.allocator, &root_command, &args, &stdout, &stderr);
    try std.testing.expectEqual(th.errors.usage, code);
    try std.testing.expect(std.mem.indexOf(u8, stderr.buffered(), "Did you mean 'status'?") != null);
}

fn deploy(ctx: *th.Context) !void {
    if (ctx.hasOption("dry-run")) {
        try ctx.print("Would deploy {s}.\n", .{ctx.argument(0).?});
    }
}

fn status(_: *th.Context) !void {}
