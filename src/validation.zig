const std = @import("std");
const Command = @import("command.zig").Command;
const Option = @import("options.zig").Option;
const options = @import("options.zig");
const ValidationError = @import("errors.zig").ValidationError;

const max_depth = 128;
const max_globals = 128;

pub fn validate(root: *const Command) ValidationError!void {
    var ancestry: [max_depth]*const Command = undefined;
    var globals: [max_globals]*const Option = undefined;
    try validateCommand(root, &ancestry, 0, &globals, 0);
}

fn validateCommand(command: *const Command, ancestry: *[max_depth]*const Command, depth: usize, globals: *[max_globals]*const Option, inherited_count: usize) ValidationError!void {
    if (depth >= ancestry.len) return error.CommandTreeTooDeep;
    for (ancestry[0..depth]) |ancestor| if (ancestor == command) return error.CommandCycle;
    ancestry[depth] = command;
    if (command.name.len == 0) return error.EmptyCommandName;

    for (command.aliases, 0..) |alias, index| {
        if (alias.len == 0) return error.EmptyAlias;
        if (std.mem.eql(u8, alias, command.name)) return error.DuplicateAlias;
        for (command.aliases[0..index]) |previous| if (std.mem.eql(u8, alias, previous)) return error.DuplicateAlias;
    }

    if (command.default_child) |default_child| {
        var found = false;
        for (command.children) |child| if (child == default_child) { found = true; break; };
        if (!found) return error.InvalidDefaultChild;
    }

    for (command.children, 0..) |child, index| {
        for (command.children[0..index]) |previous| {
            if (std.mem.eql(u8, child.name, previous.name)) return error.DuplicateCommandName;
            if (commandsCollide(child, previous)) return error.DuplicateAlias;
        }
    }

    for (command.options, 0..) |*current, index| {
        if (current.long.len == 0) return error.EmptyOptionName;
        if (current.default_value) |default_value| if (!options.validValue(current, default_value)) return error.InvalidOptionDefault;
        for (command.options[0..index]) |previous| {
            if (std.mem.eql(u8, current.long, previous.long)) return error.DuplicateOptionName;
            if (current.short != null and current.short == previous.short) return error.DuplicateShortOption;
        }
        for (globals[0..inherited_count]) |global| {
            if (std.mem.eql(u8, current.long, global.long)) return error.DuplicateOptionName;
            if (current.short != null and current.short == global.short) return error.DuplicateShortOption;
        }
        for (current.requires) |name| if (!optionExists(command.options, globals[0..inherited_count], name)) return error.UnknownOptionReference;
        for (current.conflicts_with) |name| if (!optionExists(command.options, globals[0..inherited_count], name)) return error.UnknownOptionReference;
    }

    var saw_optional = false;
    for (command.args.positionals, 0..) |current, index| {
        if (current.name.len == 0) return error.EmptyPositionalName;
        for (command.args.positionals[0..index]) |previous| if (std.mem.eql(u8, current.name, previous.name)) return error.DuplicatePositionalName;
        if (!current.required) saw_optional = true;
        if (current.required and saw_optional) return error.RequiredPositionalAfterOptional;
        if (current.variadic and index + 1 != command.args.positionals.len) return error.VariadicPositionalNotLast;
    }

    var child_global_count = inherited_count;
    for (command.options) |*definition| {
        if (!definition.global) continue;
        if (child_global_count >= globals.len) return error.TooManyGlobalOptions;
        globals[child_global_count] = definition;
        child_global_count += 1;
    }
    for (command.children) |child| try validateCommand(child, ancestry, depth + 1, globals, child_global_count);
}

fn optionExists(local: []const Option, inherited: []const *const Option, name: []const u8) bool {
    for (local) |definition| if (std.mem.eql(u8, definition.long, name)) return true;
    for (inherited) |definition| if (std.mem.eql(u8, definition.long, name)) return true;
    return false;
}

fn commandsCollide(a: *const Command, b: *const Command) bool {
    if (a.matches(b.name) or b.matches(a.name)) return true;
    for (a.aliases) |alias| if (b.matches(alias)) return true;
    for (b.aliases) |alias| if (a.matches(alias)) return true;
    return false;
}
