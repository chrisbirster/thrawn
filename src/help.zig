const std = @import("std");
const arguments = @import("arguments.zig");
const Command = @import("command.zig").Command;
const Option = @import("options.zig").Option;
const path = @import("path.zig");

pub fn write(writer: *std.Io.Writer, root: *const Command, command: *const Command) std.Io.Writer.Error!void {
    try path.write(writer, root, command);
    if (command.summary.len > 0) try writer.print(" — {s}", .{command.summary});
    try writer.print("\n", .{});
    if (command.description.len > 0) try writer.print("\n{s}\n", .{command.description});

    try writer.print("\nUsage:\n  ", .{});
    if (command.usage) |usage| {
        try writer.print("{s}", .{usage});
    } else {
        try path.write(writer, root, command);
        if (command.children.len > 0) try writer.print(" <command>", .{});
        try arguments.writeUsage(writer, command.args.positionals);
        if (command.options.len > 0 or inheritedGlobalCount(root, command) > 0) try writer.print(" [options]", .{});
    }
    try writer.print("\n", .{});

    try writeChildren(writer, command);

    if (command.args.positionals.len > 0) {
        try writer.print("\nArguments:\n", .{});
        for (command.args.positionals) |positional| {
            try writer.print("  ", .{});
            try arguments.writeLabel(writer, positional);
            if (positional.summary.len > 0) try writer.print("\n      {s}", .{positional.summary});
            try writer.print("\n", .{});
        }
    }

    if (command.options.len > 0) try writeOptions(writer, "Options", command.options, false);
    try writeInheritedGlobals(writer, root, command);

    if (command.version) |version| try writer.print("\nVersion: {s}\n", .{version});
}

fn writeChildren(writer: *std.Io.Writer, command: *const Command) std.Io.Writer.Error!void {
    var ungrouped = false;
    for (command.children) |child| if (!child.hidden and child.group == null) { ungrouped = true; break; };
    if (ungrouped) {
        try writer.print("\nCommands:\n", .{});
        for (command.children) |child| {
            if (child.hidden or child.group != null) continue;
            try writer.print("  {s:<16} {s}\n", .{ child.name, child.summary });
        }
    }

    for (command.children, 0..) |child, index| {
        if (child.hidden) continue;
        const group = child.group orelse continue;
        var seen = false;
        for (command.children[0..index]) |previous| {
            if (previous.group) |previous_group| {
                if (std.mem.eql(u8, group, previous_group)) { seen = true; break; }
            }
        }
        if (seen) continue;
        try writer.print("\n{s}:\n", .{group});
        for (command.children) |grouped| {
            if (grouped.hidden) continue;
            if (grouped.group) |grouped_name| {
                if (std.mem.eql(u8, group, grouped_name)) try writer.print("  {s:<16} {s}\n", .{ grouped.name, grouped.summary });
            }
        }
    }
}

fn writeOptions(writer: *std.Io.Writer, title: []const u8, definitions: []const Option, globals_only: bool) std.Io.Writer.Error!void {
    var count: usize = 0;
    for (definitions) |definition| if (!globals_only or definition.global) { count += 1; };
    if (count == 0) return;
    try writer.print("\n{s}:\n", .{title});
    for (definitions) |definition| {
        if (globals_only and !definition.global) continue;
        if (definition.short) |short| try writer.print("  -{c}, --{s}", .{ short, definition.long }) else try writer.print("      --{s}", .{definition.long});
        if (definition.kind == .value) {
            const value_name = definition.value_name orelse "value";
            try writer.print(" <{s}>", .{value_name});
        }
        if (definition.summary.len > 0) try writer.print("\n      {s}", .{definition.summary});
        if (definition.default_value) |default_value| try writer.print(" [default: {s}]", .{default_value});
        if (definition.required) try writer.print(" [required]", .{});
        if (definition.repeatable) try writer.print(" [repeatable]", .{});
        try writer.print("\n", .{});
    }
}

fn inheritedGlobalCount(root: *const Command, command: *const Command) usize {
    var commands: [path.max_depth]*const Command = undefined;
    const len = path.collect(root, command, &commands) orelse return 0;
    var count: usize = 0;
    for (commands[0 .. if (len > 0) len - 1 else 0]) |ancestor| for (ancestor.options) |definition| if (definition.global) { count += 1; };
    return count;
}

fn writeInheritedGlobals(writer: *std.Io.Writer, root: *const Command, command: *const Command) std.Io.Writer.Error!void {
    var commands: [path.max_depth]*const Command = undefined;
    const len = path.collect(root, command, &commands) orelse return;
    if (len <= 1 or inheritedGlobalCount(root, command) == 0) return;
    try writer.print("\nGlobal Options:\n", .{});
    for (commands[0 .. len - 1]) |ancestor| {
        for (ancestor.options) |definition| {
            if (!definition.global) continue;
            if (definition.short) |short| try writer.print("  -{c}, --{s}", .{ short, definition.long }) else try writer.print("      --{s}", .{definition.long});
            if (definition.kind == .value) try writer.print(" <{s}>", .{definition.value_name orelse "value"});
            if (definition.summary.len > 0) try writer.print("\n      {s}", .{definition.summary});
            try writer.print("\n", .{});
        }
    }
}
