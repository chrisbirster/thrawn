const std = @import("std");
const th = @import("thrawn");

test "nested help includes full path and positional metadata" {
    const deploy: th.Command = .{
        .name = "deploy",
        .summary = "Deploy a ship",
        .args = .{ .positionals = &.{.{ .name = "ship", .summary = "Ship to deploy" }} },
    };
    const fleet: th.Command = .{ .name = "fleet", .children = &.{&deploy} };
    const root: th.Command = .{ .name = "demo", .children = &.{&fleet} };

    var buffer: [2048]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try th.help.write(&writer, &root, &deploy);

    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "demo fleet deploy — Deploy a ship") != null);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "demo fleet deploy <ship>") != null);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "Ship to deploy") != null);
}
