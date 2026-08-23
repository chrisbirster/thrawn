const std = @import("std");
const th = @import("thrawn");

fn handler(ctx: *th.Context) !void {
    for (ctx.args) |arg| try ctx.print("[{s}]", .{arg});
}

const exec_command: th.Command = .{
    .name = "exec",
    .passthrough = true,
    .args = .{ .min = 1 },
    .handler = handler,
};
const root: th.Command = .{ .name = "demo", .children = &.{&exec_command} };

test "passthrough preserves option-looking arguments after first positional" {
    var result = try th.testing.run(std.testing.allocator, &root, &.{ "exec", "node", "--inspect", "index.js" });
    defer result.deinit();
    try result.expectExit(0);
    try result.expectStdout("[node][--inspect][index.js]");
}
