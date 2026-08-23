const std = @import("std");
const Command = @import("../command.zig").Command;
const engine = @import("engine.zig");
const bash = @import("bash.zig");
const zsh = @import("zsh.zig");
const fish = @import("fish.zig");

pub const Shell = enum {
    bash,
    zsh,
    fish,

    pub fn parse(value: []const u8) ?Shell {
        if (std.mem.eql(u8, value, "bash")) return .bash;
        if (std.mem.eql(u8, value, "zsh")) return .zsh;
        if (std.mem.eql(u8, value, "fish")) return .fish;
        return null;
    }
};

pub fn writeCandidates(
    allocator: std.mem.Allocator,
    writer: *std.Io.Writer,
    root: *const Command,
    words: []const []const u8,
) !void {
    try engine.writeCandidates(allocator, writer, root, words);
}

pub fn writeScript(writer: *std.Io.Writer, shell: Shell, executable: []const u8) !void {
    switch (shell) {
        .bash => try bash.write(writer, executable),
        .zsh => try zsh.write(writer, executable),
        .fish => try fish.write(writer, executable),
    }
}

test "shell names parse" {
    try std.testing.expectEqual(Shell.zsh, Shell.parse("zsh").?);
    try std.testing.expect(Shell.parse("powershell") == null);
}

test {
    _ = @import("engine.zig");
}
