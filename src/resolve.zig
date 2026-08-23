const std = @import("std");
const Command = @import("command.zig").Command;
const options = @import("options.zig");

pub const Help = struct { root: *const Command, command: *const Command };
pub const Selection = struct {
    root: *const Command,
    command: *const Command,
    prefix_args: []const []const u8 = &.{},
    args: []const []const u8,
};
pub const Unknown = struct { root: *const Command, parent: *const Command, value: []const u8 };

pub const Resolution = union(enum) { help: Help, execute: Selection, unknown: Unknown };

pub fn resolve(root: *const Command, args: []const []const u8) Resolution {
    if (args.len == 0) return .{ .help = .{ .root = root, .command = root } };

    var index: usize = 0;
    while (skipLeadingGlobal(root, args, index)) |next| index = next;
    const prefix_len = index;

    var current = root;
    while (index < args.len) {
        const value = args[index];
        if (isHelp(value)) return .{ .help = .{ .root = root, .command = current } };
        const child = current.findChild(value) orelse break;
        current = child;
        index += 1;
    }

    if (current.handler == null) {
        if (index == args.len) {
            if (current.default_child) |default_child| {
                if (default_child.handler != null) {
                    return .{ .execute = .{ .root = root, .command = default_child, .prefix_args = args[0..prefix_len], .args = &.{} } };
                }
                return .{ .help = .{ .root = root, .command = default_child } };
            }
            return .{ .help = .{ .root = root, .command = current } };
        }
        return .{ .unknown = .{ .root = root, .parent = current, .value = args[index] } };
    }

    return .{ .execute = .{ .root = root, .command = current, .prefix_args = args[0..prefix_len], .args = args[index..] } };
}

fn skipLeadingGlobal(root: *const Command, args: []const []const u8, index: usize) ?usize {
    if (index >= args.len) return null;
    const token = args[index];
    if (token.len > 2 and std.mem.startsWith(u8, token, "--")) {
        const body = token[2..];
        const equals_index = std.mem.indexOfScalar(u8, body, '=');
        const name = if (equals_index) |at| body[0..at] else body;
        const definition = options.findLong(root.options, name) orelse return null;
        if (!definition.global) return null;
        if (definition.kind == .value and equals_index == null and index + 1 < args.len) return index + 2;
        return index + 1;
    }
    if (token.len > 1 and token[0] == '-' and token[1] != '-') {
        var short_index: usize = 1;
        while (short_index < token.len) : (short_index += 1) {
            const definition = options.findShort(root.options, token[short_index]) orelse return null;
            if (!definition.global) return null;
            if (definition.kind == .value) {
                if (short_index + 1 < token.len) return index + 1;
                if (index + 1 < args.len) return index + 2;
                return index + 1;
            }
        }
        return index + 1;
    }
    return null;
}

pub fn isHelp(value: []const u8) bool {
    return std.mem.eql(u8, value, "help") or std.mem.eql(u8, value, "-h") or std.mem.eql(u8, value, "--help");
}

fn ignore(_: *@import("context.zig").Context) !void {}

test "root global options can precede the command path" {
    const leaf: Command = .{ .name = "deploy", .handler = ignore };
    const root: Command = .{
        .name = "demo",
        .options = &.{.{ .long = "verbose", .short = 'v', .global = true }},
        .children = &.{&leaf},
    };
    const args = [_][]const u8{ "--verbose", "deploy", "target" };
    const result = resolve(&root, &args);
    switch (result) {
        .execute => |selected| {
            try std.testing.expectEqual(@as(usize, 1), selected.prefix_args.len);
            try std.testing.expectEqualStrings("target", selected.args[0]);
        },
        else => return error.UnexpectedResolution,
    }
}
