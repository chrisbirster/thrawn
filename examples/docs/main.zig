const std = @import("std");
const th = @import("thrawn");

const child: th.Command = .{ .name = "hello", .summary = "Say hello" };
const root: th.Command = .{ .name = "docs-example", .summary = "Documentation example", .children = &.{&child} };

pub fn main(init: std.process.Init) !void {
    var buffer: [4096]u8 = undefined;
    var writer: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    try th.docs.writeMarkdown(&writer.interface, &root);
    try writer.interface.flush();
}
