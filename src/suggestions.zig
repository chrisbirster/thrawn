const Command = @import("command.zig").Command;

pub fn bestChild(parent: *const Command, value: []const u8) ?*const Command {
    if (value.len > 128) return null;

    var best: ?*const Command = null;
    var best_score: usize = 3;

    for (parent.children) |child| {
        if (child.hidden or child.name.len > 128) continue;
        const score = distance(value, child.name);
        if (score < best_score) {
            best = child;
            best_score = score;
        }
    }

    return best;
}

fn distance(a: []const u8, b: []const u8) usize {
    var previous: [129]usize = undefined;
    var current: [129]usize = undefined;

    for (0..b.len + 1) |index| previous[index] = index;

    for (a, 0..) |a_char, a_index| {
        current[0] = a_index + 1;
        for (b, 0..) |b_char, b_index| {
            const deletion = previous[b_index + 1] + 1;
            const insertion = current[b_index] + 1;
            const substitution = previous[b_index] + @intFromBool(a_char != b_char);
            current[b_index + 1] = @min(deletion, @min(insertion, substitution));
        }
        previous = current;
    }

    return previous[b.len];
}

test "suggest close child names" {
    const status: Command = .{ .name = "status" };
    const start: Command = .{ .name = "start" };
    const root: Command = .{ .name = "demo", .children = &.{ &status, &start } };
    const suggestion = bestChild(&root, "statsu");
    try @import("std").testing.expect(suggestion != null);
}
