const std = @import("std");
const Command = @import("command.zig").Command;

pub fn write(writer: *std.Io.Writer, command: *const Command) std.Io.Writer.Error!void {
    try writer.print("{s}", .{command.name});
    if (command.summary.len > 0) try writer.print(" — {s}", .{command.summary});
    try writer.print("\n", .{});

    if (command.description.len > 0) {
        try writer.print("\n{s}\n", .{command.description});
    }

    try writer.print("\nUsage:\n  {s}", .{command.usage orelse command.name});
    if (command.children.len > 0) try writer.print(" <command>", .{});
    try writer.print("\n", .{});

    var visible_children: usize = 0;
    for (command.children) |child| {
        if (!child.hidden) visible_children += 1;
    }

    if (visible_children > 0) {
        try writer.print("\nCommands:\n", .{});
        for (command.children) |child| {
            if (child.hidden) continue;
            try writer.print("  {s:<16} {s}\n", .{ child.name, child.summary });
        }
    }

    if (command.options.len > 0) {
        try writer.print("\nOptions:\n", .{});
        for (command.options) |option| {
            if (option.short) |short| {
                try writer.print("  -{c}, --{s}", .{ short, option.long });
            } else {
                try writer.print("      --{s}", .{option.long});
            }
            if (option.kind == .value) try writer.print(" <value>", .{});
            if (option.summary.len > 0) try writer.print("\n      {s}", .{option.summary});
            try writer.print("\n", .{});
        }
    }

    if (command.version) |version| {
        try writer.print("\nVersion: {s}\n", .{version});
    }
}

test "help is generated from command metadata" {
    const child: Command = .{ .name = "status", .summary = "Show status" };
    const root: Command = .{ .name = "demo", .summary = "Demo app", .children = &.{&child} };
    var buffer: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try write(&writer, &root);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "Commands:") != null);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "status") != null);
}
