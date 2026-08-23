const std = @import("std");
const Command = @import("command.zig").Command;

/// Write the path from root to target. If target does not belong to root,
/// fall back to the target's own name rather than producing misleading output.
pub fn write(
    writer: *std.Io.Writer,
    root: *const Command,
    target: *const Command,
) std.Io.Writer.Error!void {
    if (!contains(root, target)) {
        try writer.print("{s}", .{target.name});
        return;
    }

    try writer.print("{s}", .{root.name});
    if (root == target) return;

    var current = root;
    while (current != target) {
        var next: ?*const Command = null;
        for (current.children) |child| {
            if (contains(child, target)) {
                next = child;
                break;
            }
        }

        const child = next orelse return;
        try writer.print(" {s}", .{child.name});
        current = child;
    }
}

pub fn contains(root: *const Command, target: *const Command) bool {
    if (root == target) return true;
    for (root.children) |child| {
        if (contains(child, target)) return true;
    }
    return false;
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
