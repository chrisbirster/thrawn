const std = @import("std");
const th = @import("thrawn");

const State = struct { calls: usize = 0 };

fn useState(ctx: *th.Context) !void {
    const state = ctx.state(State) orelse return error.MissingState;
    state.calls += 1;
}

test "public runtime options expose typed state" {
    const root: th.Command = .{ .name = "demo", .handler = useState, .args = .{ .exact = 0 } };
    var state: State = .{};
    var stdout_buffer: [64]u8 = undefined;
    var stderr_buffer: [64]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buffer);
    var stderr = std.Io.Writer.fixed(&stderr_buffer);

    const code = try th.runArgsWithOptions(
        std.testing.allocator,
        &root,
        &.{},
        &stdout,
        &stderr,
        .{ .state = &state },
    );
    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expectEqual(@as(usize, 1), state.calls);
}

test "public resolve options allow literal help command" {
    const help_command: th.Command = .{ .name = "help", .handler = useState, .args = .{ .exact = 1 } };
    const root: th.Command = .{ .name = "demo", .children = &.{&help_command} };
    const args = [_][]const u8{ "help", "topic" };
    const result = th.resolveWithOptions(&root, &args, .{
        .help_tokens = .{ .command = null },
    });
    switch (result) {
        .execute => |selected| {
            try std.testing.expect(selected.command == &help_command);
            try std.testing.expectEqualStrings("topic", selected.args[0]);
        },
        else => return error.UnexpectedResolution,
    }
}
