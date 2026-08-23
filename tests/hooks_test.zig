const std = @import("std");
const th = @import("thrawn");

fn before(ctx: *th.Context) !void { try ctx.print("before\n", .{}); }
fn handler(ctx: *th.Context) !void { try ctx.print("handler\n", .{}); }
fn after(ctx: *th.Context) !void { try ctx.print("after\n", .{}); }

const leaf: th.Command = .{ .name = "run", .handler = handler };
const root: th.Command = .{ .name = "demo", .before = before, .after = after, .children = &.{&leaf} };

test "parent hooks wrap child handlers" {
    var result = try th.testing.run(std.testing.allocator, &root, &.{"run"});
    defer result.deinit();
    try result.expectExit(0);
    try result.expectStdout("before\nhandler\nafter\n");
}
