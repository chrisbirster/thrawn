const std = @import("std");
const th = @import("thrawn");

const version_command: th.Command = .{
    .name = "version",
    .handler = version,
};

const root_command: th.Command = .{
    .name = "consumer-test",
    .children = &.{&version_command},
};

pub fn main(init: std.process.Init) !void {
    const code = try th.run(init, &root_command);
    if (code != th.errors.success) std.process.exit(code);
}

fn version(ctx: *th.Context) !void {
    try ctx.print("{s}\n", .{th.version});
}
