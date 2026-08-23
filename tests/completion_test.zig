const std = @import("std");
const th = @import("thrawn");

test "internal completion protocol uses public command tree" {
    const deploy: th.Command = .{
        .name = "deploy",
        .complete = completeShips,
        .handler = ignore,
    };
    const fleet: th.Command = .{ .name = "fleet", .children = &.{&deploy} };
    const root: th.Command = .{ .name = "demo", .children = &.{&fleet} };
    const args = [_][]const u8{ "--thrawn-complete", "fleet", "deploy", "d" };

    var stdout_buffer: [1024]u8 = undefined;
    var stderr_buffer: [1024]u8 = undefined;
    var stdout: std.Io.Writer = .fixed(&stdout_buffer);
    var stderr: std.Io.Writer = .fixed(&stderr_buffer);

    const code = try th.runArgs(std.testing.allocator, &root, &args, &stdout, &stderr);
    try std.testing.expectEqual(th.errors.success, code);
    try std.testing.expectEqualStrings("destroyer\n", stdout.buffered());
    try std.testing.expectEqual(@as(usize, 0), stderr.buffered().len);
}

test "all supported shells generate scripts using the completion protocol" {
    inline for (.{ th.completion.Shell.bash, th.completion.Shell.zsh, th.completion.Shell.fish }) |shell| {
        var buffer: [4096]u8 = undefined;
        var writer: std.Io.Writer = .fixed(&buffer);
        try th.completion.writeScript(&writer, shell, "demo");
        try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "--thrawn-complete") != null);
        try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "demo") != null);
    }
}

fn completeShips(ctx: *th.CompletionContext) !void {
    try ctx.candidate("destroyer");
    try ctx.candidate("cruiser");
}

fn ignore(_: *th.Context) !void {}
