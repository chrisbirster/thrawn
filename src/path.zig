const std = @import("std");
const Command = @import("command.zig").Command;

pub const max_depth = 128;

pub fn write(writer: *std.Io.Writer, root: *const Command, target: *const Command) std.Io.Writer.Error!void {
    var commands: [max_depth]*const Command = undefined;
    const len = collect(root, target, &commands) orelse {
        try writer.print("{s}", .{target.name});
        return;
    };
    for (commands[0..len], 0..) |command, index| {
        if (index != 0) try writer.print(" ", .{});
        try writer.print("{s}", .{command.name});
    }
}

pub fn collect(root: *const Command, target: *const Command, out: *[max_depth]*const Command) ?usize {
    return collectInto(root, target, out, 0);
}

fn collectInto(root: *const Command, target: *const Command, out: *[max_depth]*const Command, depth: usize) ?usize {
    if (depth >= out.len) return null;
    out[depth] = root;
    if (root == target) return depth + 1;
    for (root.children) |child| {
        if (collectInto(child, target, out, depth + 1)) |len| return len;
    }
    return null;
}

pub fn contains(root: *const Command, target: *const Command) bool {
    var commands: [max_depth]*const Command = undefined;
    return collect(root, target, &commands) != null;
}

test "write full nested command path" {
    const deploy: Command = .{ .name = "deploy" };
    const fleet: Command = .{ .name = "fleet", .children = &.{&deploy} };
    const root: Command = .{ .name = "demo", .children = &.{&fleet} };
    var buffer: [128]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try write(&writer, &root, &deploy);
    try std.testing.expectEqualStrings("demo fleet deploy", writer.buffered());
}
