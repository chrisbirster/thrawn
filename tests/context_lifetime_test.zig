const std = @import("std");
const th = @import("thrawn");

const Retained = struct {
    allocator: std.mem.Allocator,
    first: ?[]u8 = null,
    tail: ?[][]u8 = null,
    mode: ?[]u8 = null,
    tag: ?[]u8 = null,

    fn deinit(self: *Retained) void {
        if (self.first) |value| self.allocator.free(value);
        if (self.tail) |values| {
            for (values) |value| self.allocator.free(value);
            self.allocator.free(values);
        }
        if (self.mode) |value| self.allocator.free(value);
        if (self.tag) |value| self.allocator.free(value);
        self.* = undefined;
    }
};

fn retainValues(ctx: *th.Context) !void {
    const retained = ctx.state(Retained) orelse return error.MissingState;
    retained.first = try ctx.dupeArgument(retained.allocator, 0);
    retained.tail = try ctx.dupeArguments(retained.allocator, 1);
    retained.mode = try ctx.dupeOptionValue(retained.allocator, "mode");
    retained.tag = try ctx.dupeOptionValueAt(retained.allocator, "tag", 0);
}

test "context ownership helpers survive parser teardown" {
    const leaf: th.Command = .{
        .name = "store",
        .handler = retainValues,
        .args = .{ .positionals = &.{
            .{ .name = "first" },
            .{ .name = "rest", .variadic = true },
        } },
        .options = &.{
            .{ .long = "mode", .kind = .value },
            .{ .long = "tag", .kind = .value, .repeatable = true },
        },
    };
    const root: th.Command = .{ .name = "demo", .children = &.{&leaf} };

    var retained: Retained = .{ .allocator = std.testing.allocator };
    defer retained.deinit();

    var stdout_buffer: [64]u8 = undefined;
    var stderr_buffer: [64]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buffer);
    var stderr = std.Io.Writer.fixed(&stderr_buffer);

    const code = try th.runArgsWithOptions(
        std.testing.allocator,
        &root,
        &.{ "store", "alpha", "beta", "gamma", "--mode", "safe", "--tag", "one", "--tag", "two" },
        &stdout,
        &stderr,
        .{ .state = &retained },
    );

    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expectEqualStrings("alpha", retained.first.?);
    try std.testing.expectEqual(@as(usize, 2), retained.tail.?.len);
    try std.testing.expectEqualStrings("beta", retained.tail.?[0]);
    try std.testing.expectEqualStrings("gamma", retained.tail.?[1]);
    try std.testing.expectEqualStrings("safe", retained.mode.?);
    try std.testing.expectEqualStrings("one", retained.tag.?);
}

test "context ownership helpers handle missing values and empty tails" {
    var stdout_buffer: [1]u8 = undefined;
    var stderr_buffer: [1]u8 = undefined;
    var stdout = std.Io.Writer.fixed(&stdout_buffer);
    var stderr = std.Io.Writer.fixed(&stderr_buffer);
    const root: th.Command = .{ .name = "demo" };
    var path = [_]*const th.Command{&root};
    const args = [_][]const u8{"only"};

    var ctx: th.Context = .{
        .allocator = std.testing.allocator,
        .root = &root,
        .command = &root,
        .command_path = &path,
        .args = &args,
        .stdout = &stdout,
        .stderr = &stderr,
    };

    try std.testing.expect((try ctx.dupeArgument(std.testing.allocator, 99)) == null);
    try std.testing.expect((try ctx.dupeOptionValue(std.testing.allocator, "missing")) == null);

    const empty = try ctx.dupeArguments(std.testing.allocator, 99);
    defer std.testing.allocator.free(empty);
    try std.testing.expectEqual(@as(usize, 0), empty.len);
}
