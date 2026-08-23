const std = @import("std");
const th = @import("thrawn");

const hello_command: th.Command = .{
    .name = "hello",
    .summary = "Say hello",
    .handler = hello,
};

const root_command: th.Command = .{
    .name = "basic-example",
    .children = &.{&hello_command},
};

pub fn main(init: std.process.Init) !void {
    const code = try th.run(init, &root_command);
    if (code != 0) std.process.exit(code);
}

fn hello(ctx: *th.Context) !void {
    try ctx.print("Hello from Thrawn.\n", .{});
}
