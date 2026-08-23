const std = @import("std");

pub const Kind = enum {
    boolean,
    value,
};

pub const ValueType = enum {
    string,
    integer,
    float,
    choice,
};

pub const Option = struct {
    long: []const u8,
    short: ?u8 = null,
    kind: Kind = .boolean,
    value_type: ValueType = .string,
    value_name: ?[]const u8 = null,
    choices: []const []const u8 = &.{},
    summary: []const u8 = "",
    required: bool = false,
    default_value: ?[]const u8 = null,
    repeatable: bool = false,
    global: bool = false,
    conflicts_with: []const []const u8 = &.{},
    requires: []const []const u8 = &.{},
    exclusive_group: ?[]const u8 = null,
};

pub const Value = struct {
    option: *const Option,
    value: ?[]const u8 = null,
    is_default: bool = false,
};

pub const ParseError = error{
    UnknownOption,
    MissingValue,
    MissingRequiredOption,
    DuplicateOption,
    InvalidValue,
    ConflictingOptions,
    MissingRequiredDependency,
    OutOfMemory,
};

pub const Parsed = struct {
    allocator: std.mem.Allocator,
    positional_storage: [][]const u8,
    value_storage: []Value,
    positionals: []const []const u8,
    values: []const Value,

    pub fn deinit(self: *Parsed) void {
        self.allocator.free(self.positional_storage);
        self.allocator.free(self.value_storage);
        self.* = undefined;
    }

    pub fn has(self: *const Parsed, long: []const u8) bool {
        return self.count(long) > 0;
    }

    pub fn count(self: *const Parsed, long: []const u8) usize {
        var total: usize = 0;
        for (self.values) |item| {
            if (std.mem.eql(u8, item.option.long, long)) total += 1;
        }
        return total;
    }

    pub fn find(self: *const Parsed, long: []const u8) ?[]const u8 {
        var index: usize = self.values.len;
        while (index > 0) {
            index -= 1;
            const item = self.values[index];
            if (std.mem.eql(u8, item.option.long, long)) return item.value orelse "";
        }
        return null;
    }
};

pub fn parse(
    allocator: std.mem.Allocator,
    definitions: []const Option,
    args: []const []const u8,
) ParseError!Parsed {
    return parseWithMode(allocator, definitions, args, false);
}

pub fn parseWithMode(
    allocator: std.mem.Allocator,
    definitions: []const Option,
    args: []const []const u8,
    passthrough_after_first_positional: bool,
) ParseError!Parsed {
    const positional_storage = allocator.alloc([]const u8, args.len) catch return error.OutOfMemory;
    errdefer allocator.free(positional_storage);

    var value_capacity: usize = definitions.len;
    for (args) |token| value_capacity += token.len;
    const value_storage = allocator.alloc(Value, value_capacity) catch return error.OutOfMemory;
    errdefer allocator.free(value_storage);

    var positional_count: usize = 0;
    var value_count: usize = 0;
    var index: usize = 0;
    var options_enabled = true;

    while (index < args.len) : (index += 1) {
        const token = args[index];

        if (options_enabled and std.mem.eql(u8, token, "--")) {
            options_enabled = false;
            continue;
        }

        if (options_enabled and token.len > 2 and std.mem.startsWith(u8, token, "--")) {
            const body = token[2..];
            const equals_index = std.mem.indexOfScalar(u8, body, '=');
            const name = if (equals_index) |at| body[0..at] else body;
            const definition = findLong(definitions, name) orelse return error.UnknownOption;

            if (!definition.repeatable and countDefinition(value_storage[0..value_count], definition) > 0) {
                return error.DuplicateOption;
            }

            var option_value: ?[]const u8 = null;
            switch (definition.kind) {
                .boolean => {
                    if (equals_index != null) return error.InvalidValue;
                },
                .value => {
                    if (equals_index) |at| {
                        option_value = body[at + 1 ..];
                    } else {
                        if (index + 1 >= args.len) return error.MissingValue;
                        index += 1;
                        option_value = args[index];
                    }
                    if (!validValue(definition, option_value.?)) return error.InvalidValue;
                },
            }

            value_storage[value_count] = .{ .option = definition, .value = option_value };
            value_count += 1;
            continue;
        }

        if (options_enabled and token.len > 1 and token[0] == '-' and token[1] != '-') {
            var short_index: usize = 1;
            while (short_index < token.len) : (short_index += 1) {
                const definition = findShort(definitions, token[short_index]) orelse return error.UnknownOption;
                if (!definition.repeatable and countDefinition(value_storage[0..value_count], definition) > 0) {
                    return error.DuplicateOption;
                }

                var option_value: ?[]const u8 = null;
                if (definition.kind == .value) {
                    if (short_index + 1 < token.len) {
                        var attached = token[short_index + 1 ..];
                        if (attached.len > 0 and attached[0] == '=') attached = attached[1..];
                        option_value = attached;
                    } else {
                        if (index + 1 >= args.len) return error.MissingValue;
                        index += 1;
                        option_value = args[index];
                    }
                    if (!validValue(definition, option_value.?)) return error.InvalidValue;
                    short_index = token.len;
                }

                value_storage[value_count] = .{ .option = definition, .value = option_value };
                value_count += 1;
            }
            continue;
        }

        positional_storage[positional_count] = token;
        positional_count += 1;
        if (passthrough_after_first_positional) options_enabled = false;
    }

    for (definitions) |*definition| {
        if (countDefinition(value_storage[0..value_count], definition) != 0) continue;
        if (definition.default_value) |default_value| {
            if (definition.kind == .boolean) {
                if (std.mem.eql(u8, default_value, "true")) {
                    value_storage[value_count] = .{ .option = definition, .is_default = true };
                    value_count += 1;
                }
            } else {
                if (!validValue(definition, default_value)) return error.InvalidValue;
                value_storage[value_count] = .{ .option = definition, .value = default_value, .is_default = true };
                value_count += 1;
            }
        }
    }

    const parsed_values = value_storage[0..value_count];

    for (definitions) |*definition| {
        const present = countDefinition(parsed_values, definition) != 0;
        if (definition.required and !present) return error.MissingRequiredOption;
        if (!present) continue;

        for (definition.conflicts_with) |name| {
            if (hasLong(parsed_values, name)) return error.ConflictingOptions;
        }
        for (definition.requires) |name| {
            if (!hasLong(parsed_values, name)) return error.MissingRequiredDependency;
        }
        if (definition.exclusive_group) |group| {
            for (definitions) |*other| {
                if (other == definition) continue;
                if (other.exclusive_group) |other_group| {
                    if (std.mem.eql(u8, group, other_group) and countDefinition(parsed_values, other) != 0) {
                        return error.ConflictingOptions;
                    }
                }
            }
        }
    }

    return .{
        .allocator = allocator,
        .positional_storage = positional_storage,
        .value_storage = value_storage,
        .positionals = positional_storage[0..positional_count],
        .values = parsed_values,
    };
}

pub fn validValue(definition: *const Option, value: []const u8) bool {
    if (definition.kind == .boolean) return std.mem.eql(u8, value, "true") or std.mem.eql(u8, value, "false");
    return switch (definition.value_type) {
        .string => true,
        .integer => blk: {
            _ = std.fmt.parseInt(i64, value, 0) catch break :blk false;
            break :blk true;
        },
        .float => blk: {
            _ = std.fmt.parseFloat(f64, value) catch break :blk false;
            break :blk true;
        },
        .choice => blk: {
            for (definition.choices) |choice| {
                if (std.mem.eql(u8, value, choice)) break :blk true;
            }
            break :blk false;
        },
    };
}

pub fn findLong(definitions: []const Option, name: []const u8) ?*const Option {
    for (definitions) |*definition| {
        if (std.mem.eql(u8, definition.long, name)) return definition;
    }
    return null;
}

pub fn findShort(definitions: []const Option, short: u8) ?*const Option {
    for (definitions) |*definition| {
        if (definition.short == short) return definition;
    }
    return null;
}

fn countDefinition(values: []const Value, definition: *const Option) usize {
    var total: usize = 0;
    for (values) |item| {
        if (item.option == definition) total += 1;
    }
    return total;
}

fn hasLong(values: []const Value, long: []const u8) bool {
    for (values) |item| {
        if (std.mem.eql(u8, item.option.long, long)) return true;
    }
    return false;
}

test "long equals, attached short values, clusters, and end marker" {
    const definitions = [_]Option{
        .{ .long = "alpha", .short = 'a' },
        .{ .long = "beta", .short = 'b' },
        .{ .long = "port", .short = 'p', .kind = .value, .value_type = .integer, .repeatable = true },
    };
    const args = [_][]const u8{ "-ab", "-p8080", "--port=9090", "--", "--alpha" };
    var parsed = try parseWithMode(std.testing.allocator, &definitions, &args, false);
    defer parsed.deinit();
    try std.testing.expect(parsed.has("alpha"));
    try std.testing.expect(parsed.has("beta"));
    try std.testing.expectEqualStrings("9090", parsed.find("port").?);
    try std.testing.expectEqualStrings("--alpha", parsed.positionals[0]);
}
