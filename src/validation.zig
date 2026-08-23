const std = @import("std");
const Command = @import("command.zig").Command;
const ValidationError = @import("errors.zig").ValidationError;

pub fn validate(root: *const Command) ValidationError!void {
    try validateCommand(root);
}

fn validateCommand(command: *const Command) ValidationError!void {
    if (command.name.len == 0) return error.EmptyCommandName;

    if (command.default_child) |default_child| {
        var found = false;
        for (command.children) |child| {
            if (child == default_child) {
                found = true;
                break;
            }
        }
        if (!found) return error.InvalidDefaultChild;
    }

    for (command.children, 0..) |child, index| {
        for (command.children[0..index]) |previous| {
            if (std.mem.eql(u8, child.name, previous.name)) return error.DuplicateCommandName;
            if (previous.matches(child.name) or child.matches(previous.name)) return error.DuplicateAlias;
            for (child.aliases) |alias| {
                if (previous.matches(alias)) return error.DuplicateAlias;
            }
        }
        try validateCommand(child);
    }

    for (command.options, 0..) |current, index| {
        if (current.long.len == 0) return error.EmptyOptionName;
        for (command.options[0..index]) |previous| {
            if (std.mem.eql(u8, current.long, previous.long)) return error.DuplicateOptionName;
            if (current.short != null and current.short == previous.short) return error.DuplicateShortOption;
        }
    }
}

test "duplicate child names are rejected" {
    const first: Command = .{ .name = "status" };
    const second: Command = .{ .name = "status" };
    const root: Command = .{ .name = "demo", .children = &.{ &first, &second } };
    try std.testing.expectError(error.DuplicateCommandName, validate(&root));
}
