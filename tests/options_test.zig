const std = @import("std");
const th = @import("thrawn");

test "public option parser handles long, short, and positional values" {
    const definitions = [_]th.options.Option{
        .{ .long = "dry-run", .short = 'n' },
        .{ .long = "profile", .short = 'p', .kind = .value },
    };
    const args = [_][]const u8{ "node", "--dry-run", "-p", "work" };

    var parsed = try th.options.parse(std.testing.allocator, &definitions, &args);
    defer parsed.deinit();

    try std.testing.expectEqualStrings("node", parsed.positionals[0]);
    try std.testing.expect(parsed.has("dry-run"));
    try std.testing.expectEqualStrings("work", parsed.find("profile").?);
}
