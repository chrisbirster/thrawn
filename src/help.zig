const std = @import("std");
const arguments = @import("arguments.zig");
const Command = @import("command.zig").Command;
const path = @import("path.zig");

pub fn write(
    writer: *std.Io.Writer,
    root: *const Command,
    command: *const Command,
) std.Io.Writer.Error!void {
    try path.write(writer, root, command);
    if (command.summary.len > 0) try writer.print(" — {s}", .{command.summary});
    try writer.print("\n", .{});

    if (command.description.len > 0) {
        try writer.print("\n{s}\n", .{command.description});
    }

    try writer.print("\nUsage:\n  ", .{});
    if (command.usage) |usage| {
        try writer.print("{s}", .{usage});
    } else {
        try path.write(writer, root, command);
        if (command.children.len > 0) try writer.print(" <command>", .{});
        try arguments.writeUsage(writer, command.args.positionals);
        if (command.options.len > 0) try writer.print(" [options]", .{});
    }
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

    if (command.args.positionals.len > 0) {
        try writer.print("\nArguments:\n", .{});
        for (command.args.positionals) |positional| {
            try writer.print("  ", .{});
            try arguments.writeLabel(writer, positional);
            if (positional.summary.len > 0) try writer.print("\n      {s}", .{positional.summary});
            try writer.print("\n", .{});
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

test "help is generated from full command path and metadata" {
    const child: Command = .{
        .name = "status",
        .summary = "Show status",
        .args = .{ .positionals = &.{.{ .name = "target", .summary = "Target to inspect" }} },
    };
    const root: Command = .{ .name = "demo", .summary = "Demo app", .children = &.{&child} };
    var buffer: [2048]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try write(&writer, &root, &child);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "demo status — Show status") != null);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "demo status <target>") != null);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "Target to inspect") != null);
}
