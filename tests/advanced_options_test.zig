const std = @import("std");
const th = @import("thrawn");

test "defaults repeatable values constraints and typed values" {
    const definitions = [_]th.options.Option{
        .{ .long = "verbose", .short = 'v' },
        .{ .long = "port", .short = 'p', .kind = .value, .value_type = .integer, .default_value = "8080" },
        .{ .long = "tag", .short = 't', .kind = .value, .repeatable = true },
        .{ .long = "json", .conflicts_with = &.{"quiet"} },
        .{ .long = "quiet" },
    };
    const args = [_][]const u8{ "-v", "-talpha", "--tag=beta" };
    var parsed = try th.options.parse(std.testing.allocator, &definitions, &args);
    defer parsed.deinit();
    try std.testing.expect(parsed.has("verbose"));
    try std.testing.expectEqualStrings("8080", parsed.find("port").?);
    try std.testing.expectEqual(@as(usize, 2), parsed.count("tag"));
}

test "conflicting options fail" {
    const definitions = [_]th.options.Option{
        .{ .long = "json", .conflicts_with = &.{"quiet"} },
        .{ .long = "quiet" },
    };
    const args = [_][]const u8{ "--json", "--quiet" };
    try std.testing.expectError(error.ConflictingOptions, th.options.parse(std.testing.allocator, &definitions, &args));
}
