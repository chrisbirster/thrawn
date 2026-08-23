const std = @import("std");
const command_mod = @import("../command.zig");
const Command = command_mod.Command;
const options = @import("../options.zig");

/// Write newline-delimited completion candidates for the command line words
/// after argv[0]. The final word is treated as the prefix currently being
/// completed.
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
            if (consumeOption(current, committed, &index)) {
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
        try writeOptionCandidates(writer, current, prefix);
        return;
    }

    if (index == committed.len and current.children.len > 0) {
        var wrote_child = false;
        for (current.children) |child| {
            if (child.hidden) continue;
            if (!std.mem.startsWith(u8, child.name, prefix)) continue;
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

fn consumeOption(command: *const Command, words: []const []const u8, index: *usize) bool {
    const token = words[index.*];
    if (token.len > 2 and std.mem.startsWith(u8, token, "--")) {
        const body = token[2..];
        const equals_index = std.mem.indexOfScalar(u8, body, '=');
        const name = if (equals_index) |at| body[0..at] else body;
        const definition = options.findLong(command.options, name) orelse return false;
        if (definition.kind == .value and equals_index == null and index.* + 1 < words.len) {
            index.* += 1;
        }
        return true;
    }
    if (token.len == 2 and token[0] == '-') {
        const definition = options.findShort(command.options, token[1]) orelse return false;
        if (definition.kind == .value and index.* + 1 < words.len) index.* += 1;
        return true;
    }
    return false;
}

fn writeOptionCandidates(writer: *std.Io.Writer, command: *const Command, prefix: []const u8) !void {
    for (command.options) |definition| {
        var long_buffer: [260]u8 = undefined;
        const long = std.fmt.bufPrint(&long_buffer, "--{s}", .{definition.long}) catch continue;
        if (std.mem.startsWith(u8, long, prefix)) try writer.print("{s}\n", .{long});

        if (definition.short) |short| {
            var short_buffer: [2]u8 = .{ '-', short };
            const short_value = short_buffer[0..];
            if (std.mem.startsWith(u8, short_value, prefix)) try writer.print("{s}\n", .{short_value});
        }
    }
}

test "completion suggests nested children" {
    const status: Command = .{ .name = "status" };
    const start: Command = .{ .name = "start" };
    const fleet: Command = .{ .name = "fleet", .children = &.{ &status, &start } };
    const root: Command = .{ .name = "demo", .children = &.{&fleet} };
    const words = [_][]const u8{ "fleet", "sta" };

    var buffer: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try writeCandidates(std.testing.allocator, &writer, &root, &words);
    try std.testing.expectEqualStrings("status\nstart\n", writer.buffered());
}

test "completion suggests long and short options" {
    const deploy: Command = .{
        .name = "deploy",
        .options = &.{.{ .long = "dry-run", .short = 'n' }},
    };
    const root: Command = .{ .name = "demo", .children = &.{&deploy} };
    const words = [_][]const u8{ "deploy", "--d" };

    var buffer: [256]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try writeCandidates(std.testing.allocator, &writer, &root, &words);
    try std.testing.expectEqualStrings("--dry-run\n", writer.buffered());
}
