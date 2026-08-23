const std = @import("std");
const Command = @import("command.zig").Command;
const ValidationError = @import("errors.zig").ValidationError;

const max_depth = 128;

pub fn validate(root: *const Command) ValidationError!void {
    var ancestry: [max_depth]*const Command = undefined;
    try validateCommand(root, &ancestry, 0);
}

fn validateCommand(
    command: *const Command,
    ancestry: *[max_depth]*const Command,
    depth: usize,
) ValidationError!void {
    if (depth >= ancestry.len) return error.CommandTreeTooDeep;
    for (ancestry[0..depth]) |ancestor| {
        if (ancestor == command) return error.CommandCycle;
    }
    ancestry[depth] = command;

    if (command.name.len == 0) return error.EmptyCommandName;

    for (command.aliases, 0..) |alias, index| {
        if (alias.len == 0) return error.EmptyAlias;
        if (std.mem.eql(u8, alias, command.name)) return error.DuplicateAlias;
        for (command.aliases[0..index]) |previous| {
            if (std.mem.eql(u8, alias, previous)) return error.DuplicateAlias;
        }
    }

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
            if (commandsCollide(child, previous)) return error.DuplicateAlias;
        }
        try validateCommand(child, ancestry, depth + 1);
    }

    for (command.options, 0..) |current, index| {
        if (current.long.len == 0) return error.EmptyOptionName;
        for (command.options[0..index]) |previous| {
            if (std.mem.eql(u8, current.long, previous.long)) return error.DuplicateOptionName;
            if (current.short != null and current.short == previous.short) return error.DuplicateShortOption;
        }
    }

    var saw_optional = false;
    for (command.args.positionals, 0..) |current, index| {
        if (current.name.len == 0) return error.EmptyPositionalName;
        for (command.args.positionals[0..index]) |previous| {
            if (std.mem.eql(u8, current.name, previous.name)) return error.DuplicatePositionalName;
        }
        if (!current.required) saw_optional = true;
        if (current.required and saw_optional) return error.RequiredPositionalAfterOptional;
        if (current.variadic and index + 1 != command.args.positionals.len) {
            return error.VariadicPositionalNotLast;
        }
    }
}

fn commandsCollide(a: *const Command, b: *const Command) bool {
    if (a.matches(b.name) or b.matches(a.name)) return true;
    for (a.aliases) |alias| {
        if (b.matches(alias)) return true;
    }
    for (b.aliases) |alias| {
        if (a.matches(alias)) return true;
    }
    return false;
}

test "duplicate child names are rejected" {
    const first: Command = .{ .name = "status" };
    const second: Command = .{ .name = "status" };
    const root: Command = .{ .name = "demo", .children = &.{ &first, &second } };
    try std.testing.expectError(error.DuplicateCommandName, validate(&root));
}

test "alias collisions are rejected" {
    const first: Command = .{ .name = "remove", .aliases = &.{"rm"} };
    const second: Command = .{ .name = "rm" };
    const root: Command = .{ .name = "demo", .children = &.{ &first, &second } };
    try std.testing.expectError(error.DuplicateAlias, validate(&root));
}

test "required positional cannot follow optional positional" {
    const command: Command = .{
        .name = "demo",
        .args = .{ .positionals = &.{
            .{ .name = "first", .required = false },
            .{ .name = "second" },
        } },
    };
    try std.testing.expectError(error.RequiredPositionalAfterOptional, validate(&command));
}
