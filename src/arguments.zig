const std = @import("std");

pub const Positional = struct {
    name: []const u8,
    summary: []const u8 = "",
    required: bool = true,
    variadic: bool = false,
};

pub const Rules = struct {
    positionals: []const Positional = &.{},
    min: ?usize = null,
    max: ?usize = null,
    exact: ?usize = null,

    pub fn valid(self: Rules, count: usize) bool {
        if (self.exact) |expected| return count == expected;

        const minimum = self.min orelse self.inferredMinimum();
        if (count < minimum) return false;

        const maximum = self.max orelse self.inferredMaximum();
        if (maximum) |value| {
            if (count > value) return false;
        }
        return true;
    }

    fn inferredMinimum(self: Rules) usize {
        var count: usize = 0;
        for (self.positionals) |positional| {
            if (positional.required) count += 1;
        }
        return count;
    }

    fn inferredMaximum(self: Rules) ?usize {
        if (self.positionals.len == 0) return null;
        if (self.positionals[self.positionals.len - 1].variadic) return null;
        return self.positionals.len;
    }
};

pub fn writeUsage(writer: *std.Io.Writer, positionals: []const Positional) std.Io.Writer.Error!void {
    for (positionals) |positional| {
        try writer.print(" ", .{});
        try writeLabel(writer, positional);
    }
}

pub fn writeLabel(writer: *std.Io.Writer, positional: Positional) std.Io.Writer.Error!void {
    if (positional.required) {
        if (positional.variadic) {
            try writer.print("<{s}...>", .{positional.name});
        } else {
            try writer.print("<{s}>", .{positional.name});
        }
    } else if (positional.variadic) {
        try writer.print("[{s}...]", .{positional.name});
    } else {
        try writer.print("[{s}]", .{positional.name});
    }
}

test "argument rules validate exact counts" {
    const rules: Rules = .{ .exact = 2 };
    try std.testing.expect(rules.valid(2));
    try std.testing.expect(!rules.valid(1));
    try std.testing.expect(!rules.valid(3));
}

test "argument rules validate explicit ranges" {
    const rules: Rules = .{ .min = 1, .max = 3 };
    try std.testing.expect(rules.valid(1));
    try std.testing.expect(rules.valid(2));
    try std.testing.expect(rules.valid(3));
    try std.testing.expect(!rules.valid(0));
    try std.testing.expect(!rules.valid(4));
}

test "positionals infer argument range" {
    const rules: Rules = .{
        .positionals = &.{
            .{ .name = "required" },
            .{ .name = "optional", .required = false },
        },
    };
    try std.testing.expect(rules.valid(1));
    try std.testing.expect(rules.valid(2));
    try std.testing.expect(!rules.valid(0));
    try std.testing.expect(!rules.valid(3));
}
