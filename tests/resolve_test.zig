const std = @import("std");
const th = @import("thrawn");

test "resolution retains root for nested paths" {
    const deploy: th.Command = .{ .name = "deploy", .handler = ignore };
    const fleet: th.Command = .{ .name = "fleet", .children = &.{&deploy} };
    const root: th.Command = .{ .name = "demo", .children = &.{&fleet} };
    const args = [_][]const u8{ "fleet", "deploy" };

    switch (th.resolve(&root, &args)) {
        .execute => |selected| {
            try std.testing.expect(selected.root == &root);
            try std.testing.expect(selected.command == &deploy);
        },
        else => return error.UnexpectedResolution,
    }
}

fn ignore(_: *th.Context) !void {}
