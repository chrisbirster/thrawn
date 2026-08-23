const std = @import("std");
const th = @import("thrawn");

const status_command: th.Command = .{ .name = "status", .handler = status };
const fleet_command: th.Command = .{ .name = "fleet", .children = &.{&status_command} };
const root_command: th.Command = .{ .name = "nested-example", .children = &.{&fleet_command} };

pub fn main(init: std.process.Init) !void {
    const code = try th.run(init, &root_command);
    if (code != 0) std.process.exit(code);
}

fn status(ctx: *th.Context) !void {
    try ctx.print("Fleet ready.\n", .{});
}
