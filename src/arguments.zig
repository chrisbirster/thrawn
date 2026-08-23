const std = @import("std");

pub const Rules = struct {
    min: usize = 0,
    max: ?usize = null,
    exact: ?usize = null,

    pub fn valid(self: Rules, count: usize) bool {
        if (self.exact) |expected| return count == expected;
        if (count < self.min) return false;
        if (self.max) |maximum| {
            if (count > maximum) return false;
        }
        return true;
    }
};

test "argument rules validate exact counts" {
    const rules: Rules = .{ .exact = 2 };
    try std.testing.expect(rules.valid(2));
    try std.testing.expect(!rules.valid(1));
    try std.testing.expect(!rules.valid(3));
}

test "argument rules validate ranges" {
    const rules: Rules = .{ .min = 1, .max = 3 };
    try std.testing.expect(rules.valid(1));
    try std.testing.expect(rules.valid(2));
    try std.testing.expect(rules.valid(3));
    try std.testing.expect(!rules.valid(0));
    try std.testing.expect(!rules.valid(4));
}
