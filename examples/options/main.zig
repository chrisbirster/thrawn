const std = @import("std");
const th = @import("thrawn");

const greet_command: th.Command = .{
    .name = "greet",
    .usage = "greet <name> [--loud]",
    .args = .{ .exact = 1 },
    .options = &.{.{ .long = "loud", .short = 'l' }},
    .handler = greet,
};
const root_command: th.Command = .{ .name = "options-example", .children = &.{&greet_command} };

pub fn main(init: std.process.Init) !void {
    const code = try th.run(init, &root_command);
    if (code != 0) std.process.exit(code);
}

fn greet(ctx: *th.Context) !void {
    const name = ctx.argument(0).?;
    if (ctx.hasOption("loud")) {
        try ctx.print("HELLO, {s}!\n", .{name});
    } else {
        try ctx.print("Hello, {s}.\n", .{name});
    }
}
