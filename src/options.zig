const std = @import("std");

pub const Kind = enum {
    boolean,
    value,
};

pub const Option = struct {
    long: []const u8,
    short: ?u8 = null,
    kind: Kind = .boolean,
    summary: []const u8 = "",
    required: bool = false,
};

pub const Value = struct {
    option: *const Option,
    value: ?[]const u8 = null,
};

pub const ParseError = error{
    UnknownOption,
    MissingValue,
    MissingRequiredOption,
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
        return self.find(long) != null;
    }

    pub fn find(self: *const Parsed, long: []const u8) ?[]const u8 {
        var index: usize = self.values.len;
        while (index > 0) {
            index -= 1;
            const item = self.values[index];
            if (std.mem.eql(u8, item.option.long, long)) {
                return item.value orelse "";
            }
        }
        return null;
    }
};

pub fn parse(
    allocator: std.mem.Allocator,
    definitions: []const Option,
    args: []const []const u8,
) ParseError!Parsed {
    const positional_storage = allocator.alloc([]const u8, args.len) catch return error.OutOfMemory;
    errdefer allocator.free(positional_storage);

    const value_storage = allocator.alloc(Value, args.len) catch return error.OutOfMemory;
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

            var option_value: ?[]const u8 = null;
            switch (definition.kind) {
                .boolean => {
                    if (equals_index != null) return error.UnknownOption;
                },
                .value => {
                    if (equals_index) |at| {
                        option_value = body[at + 1 ..];
                    } else {
                        if (index + 1 >= args.len) return error.MissingValue;
                        index += 1;
                        option_value = args[index];
                    }
                },
            }

            value_storage[value_count] = .{ .option = definition, .value = option_value };
            value_count += 1;
            continue;
        }

        if (options_enabled and token.len == 2 and token[0] == '-') {
            const definition = findShort(definitions, token[1]) orelse return error.UnknownOption;
            var option_value: ?[]const u8 = null;
            if (definition.kind == .value) {
                if (index + 1 >= args.len) return error.MissingValue;
                index += 1;
                option_value = args[index];
            }
            value_storage[value_count] = .{ .option = definition, .value = option_value };
            value_count += 1;
            continue;
        }

        positional_storage[positional_count] = token;
        positional_count += 1;
    }

    for (definitions) |*definition| {
        if (!definition.required) continue;
        var found = false;
        for (value_storage[0..value_count]) |item| {
            if (item.option == definition) {
                found = true;
                break;
            }
        }
        if (!found) return error.MissingRequiredOption;
    }

    return .{
        .allocator = allocator,
        .positional_storage = positional_storage,
        .value_storage = value_storage,
        .positionals = positional_storage[0..positional_count],
        .values = value_storage[0..value_count],
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

test "parse boolean and value options" {
    const definitions = [_]Option{
        .{ .long = "dry-run", .short = 'n' },
        .{ .long = "profile", .short = 'p', .kind = .value },
    };
    const args = [_][]const u8{ "node", "--dry-run", "-p", "work" };

    var parsed = try parse(std.testing.allocator, &definitions, &args);
    defer parsed.deinit();

    try std.testing.expectEqual(@as(usize, 1), parsed.positionals.len);
    try std.testing.expectEqualStrings("node", parsed.positionals[0]);
    try std.testing.expect(parsed.has("dry-run"));
    try std.testing.expectEqualStrings("work", parsed.find("profile").?);
}
