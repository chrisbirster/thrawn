const std = @import("std");
const arguments = @import("arguments.zig");
const Command = @import("command.zig").Command;
const path = @import("path.zig");

pub fn writeMarkdown(writer: *std.Io.Writer, root: *const Command) std.Io.Writer.Error!void {
    try writer.print("# {s}\n\n", .{root.name});
    if (root.summary.len > 0) try writer.print("{s}\n\n", .{root.summary});
    if (root.description.len > 0) try writer.print("{s}\n\n", .{root.description});
    try writeMarkdownCommand(writer, root, root, 2);
}

fn writeMarkdownCommand(writer: *std.Io.Writer, root: *const Command, command: *const Command, level: usize) std.Io.Writer.Error!void {
    if (command != root) {
        var count: usize = 0;
        while (count < level) : (count += 1) try writer.print("#", .{});
        try writer.print(" `", .{});
        try path.write(writer, root, command);
        try writer.print("`\n\n", .{});
        if (command.summary.len > 0) try writer.print("{s}\n\n", .{command.summary});
        if (command.description.len > 0) try writer.print("{s}\n\n", .{command.description});
    }

    try writer.print("**Usage:** `", .{});
    if (command.usage) |usage| {
        try writer.print("{s}", .{usage});
    } else {
        try path.write(writer, root, command);
        if (command.children.len > 0) try writer.print(" <command>", .{});
        try arguments.writeUsage(writer, command.args.positionals);
        if (command.options.len > 0) try writer.print(" [options]", .{});
    }
    try writer.print("`\n\n", .{});

    if (command.children.len > 0) {
        try writer.print("**Commands**\n\n", .{});
        for (command.children) |child| {
            if (child.hidden) continue;
            try writer.print("- `{s}`", .{child.name});
            if (child.summary.len > 0) try writer.print(" — {s}", .{child.summary});
            try writer.print("\n", .{});
        }
        try writer.print("\n", .{});
    }

    if (command.args.positionals.len > 0) {
        try writer.print("**Arguments**\n\n", .{});
        for (command.args.positionals) |positional| {
            try writer.print("- `", .{});
            try arguments.writeLabel(writer, positional);
            try writer.print("`", .{});
            if (positional.summary.len > 0) try writer.print(" — {s}", .{positional.summary});
            try writer.print("\n", .{});
        }
        try writer.print("\n", .{});
    }

    if (command.options.len > 0) {
        try writer.print("**Options**\n\n", .{});
        for (command.options) |definition| {
            try writer.print("- `--{s}`", .{definition.long});
            if (definition.short) |short| try writer.print(" (`-{c}`)", .{short});
            if (definition.summary.len > 0) try writer.print(" — {s}", .{definition.summary});
            if (definition.default_value) |default_value| try writer.print(" Default: `{s}`.", .{default_value});
            try writer.print("\n", .{});
        }
        try writer.print("\n", .{});
    }

    for (command.children) |child| {
        if (child.hidden) continue;
        try writeMarkdownCommand(writer, root, child, level + 1);
    }
}

pub fn writeMan(writer: *std.Io.Writer, root: *const Command) std.Io.Writer.Error!void {
    try writer.print(".TH {s} 1\n.SH NAME\n{s} \\- {s}\n", .{ root.name, root.name, root.summary });
    try writer.print(".SH SYNOPSIS\n.B {s}\n", .{root.name});
    if (root.description.len > 0) try writer.print(".SH DESCRIPTION\n{s}\n", .{root.description});
    try writeManCommands(writer, root, root);
}

fn writeManCommands(writer: *std.Io.Writer, root: *const Command, command: *const Command) std.Io.Writer.Error!void {
    if (command != root) {
        try writer.print(".SS ", .{});
        try path.write(writer, root, command);
        try writer.print("\n{s}\n", .{command.summary});
        try writer.print(".B Usage:\n", .{});
        try path.write(writer, root, command);
        try arguments.writeUsage(writer, command.args.positionals);
        if (command.options.len > 0) try writer.print(" [options]", .{});
        try writer.print("\n", .{});
    }
    for (command.children) |child| {
        if (child.hidden) continue;
        try writeManCommands(writer, root, child);
    }
}

test "markdown docs are generated from the command tree" {
    const child: Command = .{ .name = "status", .summary = "Show status" };
    const root: Command = .{ .name = "demo", .summary = "Demo CLI", .children = &.{&child} };
    var buffer: [4096]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try writeMarkdown(&writer, &root);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "# demo") != null);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "`demo status`") != null);
}
