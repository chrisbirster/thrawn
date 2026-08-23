const std = @import("std");
const command_mod = @import("../command.zig");
const Command = command_mod.Command;
const Option = @import("../options.zig").Option;
const options = @import("../options.zig");
const path = @import("../path.zig");

pub fn writeCandidates(
    allocator: std.mem.Allocator,
    writer: *std.Io.Writer,
    root: *const Command,
    words: []const []const u8,
) !void {
    const prefix = if (words.len == 0) "" else words[words.len - 1];
    const committed = if (words.len == 0) words else words[0 .. words.len - 1];
    var current = root;
    var index: usize = 0;
    var positional_start: usize = committed.len;

    while (index < committed.len) {
        const token = committed[index];
        if (std.mem.eql(u8, token, "--")) {
            positional_start = index + 1;
            break;
        }
        if (token.len > 0 and token[0] == '-') {
            if (consumeOption(root, current, committed, &index)) {
                index += 1;
                continue;
            }
            positional_start = index;
            break;
        }
        if (current.findChild(token)) |child| {
            current = child;
            index += 1;
            continue;
        }
        positional_start = index;
        break;
    }

    if (prefix.len > 0 and prefix[0] == '-') {
        try writeOptionCandidates(writer, root, current, prefix);
        return;
    }

    if (index == committed.len and current.children.len > 0) {
        var wrote_child = false;
        for (current.children) |child| {
            if (child.hidden or !std.mem.startsWith(u8, child.name, prefix)) continue;
            try writer.print("{s}\n", .{child.name});
            wrote_child = true;
        }
        if (wrote_child) return;
    }

    if (current.complete) |complete| {
        const positional_args = if (positional_start <= committed.len)
            committed[positional_start..]
        else
            &.{};
        var context: command_mod.CompletionContext = .{
            .allocator = allocator,
            .args = positional_args,
            .prefix = prefix,
            .writer = writer,
        };
        try complete(&context);
    }
}

fn consumeOption(
    root: *const Command,
    command: *const Command,
    words: []const []const u8,
    index: *usize,
) bool {
    const token = words[index.*];
    if (token.len > 2 and std.mem.startsWith(u8, token, "--")) {
        const body = token[2..];
        const equals_index = std.mem.indexOfScalar(u8, body, '=');
        const name = if (equals_index) |at| body[0..at] else body;
        const definition = findEffectiveLong(root, command, name) orelse return false;
        if (definition.kind == .value and equals_index == null and index.* + 1 < words.len) {
            index.* += 1;
        }
        return true;
    }
    if (token.len > 1 and token[0] == '-' and token[1] != '-') {
        var short_index: usize = 1;
        while (short_index < token.len) : (short_index += 1) {
            const definition = findEffectiveShort(root, command, token[short_index]) orelse return false;
            if (definition.kind == .value) {
                if (short_index + 1 == token.len and index.* + 1 < words.len) {
                    index.* += 1;
                }
                break;
            }
        }
        return true;
    }
    return false;
}

fn writeOptionCandidates(
    writer: *std.Io.Writer,
    root: *const Command,
    command: *const Command,
    prefix: []const u8,
) !void {
    for (command.options) |*definition| {
        try writeDefinition(writer, definition, prefix);
    }

    var commands: [path.max_depth]*const Command = undefined;
    const len = path.collect(root, command, &commands) orelse return;
    if (len <= 1) return;

    for (commands[0 .. len - 1]) |ancestor| {
        for (ancestor.options) |*definition| {
            if (definition.global) try writeDefinition(writer, definition, prefix);
        }
    }
}

fn writeDefinition(
    writer: *std.Io.Writer,
    definition: *const Option,
    prefix: []const u8,
) !void {
    var long_buffer: [260]u8 = undefined;
    const long = std.fmt.bufPrint(&long_buffer, "--{s}", .{definition.long}) catch return;
    if (std.mem.startsWith(u8, long, prefix)) {
        try writer.print("{s}\n", .{long});
    }

    if (definition.short) |short| {
        var short_buffer: [2]u8 = .{ '-', short };
        const short_value = short_buffer[0..];
        if (std.mem.startsWith(u8, short_value, prefix)) {
            try writer.print("{s}\n", .{short_value});
        }
    }
}

fn findEffectiveLong(
    root: *const Command,
    command: *const Command,
    name: []const u8,
) ?*const Option {
    if (options.findLong(command.options, name)) |definition| return definition;

    var commands: [path.max_depth]*const Command = undefined;
    const len = path.collect(root, command, &commands) orelse return null;
    if (len <= 1) return null;

    var index = len - 1;
    while (index > 0) {
        index -= 1;
        if (options.findLong(commands[index].options, name)) |definition| {
            if (definition.global) return definition;
        }
    }
    return null;
}

fn findEffectiveShort(
    root: *const Command,
    command: *const Command,
    short: u8,
) ?*const Option {
    if (options.findShort(command.options, short)) |definition| return definition;

    var commands: [path.max_depth]*const Command = undefined;
    const len = path.collect(root, command, &commands) orelse return null;
    if (len <= 1) return null;

    var index = len - 1;
    while (index > 0) {
        index -= 1;
        if (options.findShort(commands[index].options, short)) |definition| {
            if (definition.global) return definition;
        }
    }
    return null;
}
