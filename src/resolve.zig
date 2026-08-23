const std = @import("std");
const Command = @import("command.zig").Command;

pub const Selection = struct {
    command: *const Command,
    args: []const []const u8,
};

pub const Unknown = struct {
    parent: *const Command,
    value: []const u8,
};

pub const Resolution = union(enum) {
    help: *const Command,
    execute: Selection,
    unknown: Unknown,
};

pub fn resolve(root: *const Command, args: []const []const u8) Resolution {
    if (args.len == 0) return .{ .help = root };

    var current = root;
    var index: usize = 0;

    while (index < args.len) {
        const value = args[index];
        if (isHelp(value)) return .{ .help = current };

        const child = current.findChild(value) orelse break;
        current = child;
        index += 1;
    }

    if (current.handler == null) {
        if (index == args.len) {
            if (current.default_child) |default_child| {
                if (default_child.handler != null) {
                    return .{ .execute = .{ .command = default_child, .args = &.{} } };
                }
                return .{ .help = default_child };
            }
            return .{ .help = current };
        }
        return .{ .unknown = .{ .parent = current, .value = args[index] } };
    }

    return .{ .execute = .{ .command = current, .args = args[index..] } };
}

pub fn isHelp(value: []const u8) bool {
    return std.mem.eql(u8, value, "help") or
        std.mem.eql(u8, value, "-h") or
        std.mem.eql(u8, value, "--help");
}

test "nested leaf resolves with remaining arguments" {
    const leaf: Command = .{ .name = "deploy", .handler = ignore };
    const branch: Command = .{ .name = "fleet", .children = &.{&leaf} };
    const root: Command = .{ .name = "demo", .children = &.{&branch} };
    const args = [_][]const u8{ "fleet", "deploy", "destroyer" };

    const resolution = resolve(&root, &args);
    switch (resolution) {
        .execute => |selected| {
            try std.testing.expectEqualStrings("deploy", selected.command.name);
            try std.testing.expectEqualStrings("destroyer", selected.args[0]);
        },
        else => return error.UnexpectedResolution,
    }
}

fn ignore(_: *@import("context.zig").Context) !void {}
