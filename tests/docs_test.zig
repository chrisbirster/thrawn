const std = @import("std");
const th = @import("thrawn");

test "markdown and man documentation are generated" {
    const child: th.Command = .{ .name = "status", .summary = "Show status" };
    const root: th.Command = .{ .name = "demo", .summary = "Demo CLI", .children = &.{&child} };
    var markdown_buffer: [4096]u8 = undefined;
    var markdown_writer: std.Io.Writer = .fixed(&markdown_buffer);
    try th.docs.writeMarkdown(&markdown_writer, &root);
    try std.testing.expect(std.mem.indexOf(u8, markdown_writer.buffered(), "demo status") != null);

    var man_buffer: [4096]u8 = undefined;
    var man_writer: std.Io.Writer = .fixed(&man_buffer);
    try th.docs.writeMan(&man_writer, &root);
    try std.testing.expect(std.mem.indexOf(u8, man_writer.buffered(), ".TH demo 1") != null);
}
