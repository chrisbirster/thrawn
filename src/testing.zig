const std = @import("std");
const Command = @import("command.zig").Command;
const run_mod = @import("run.zig");

pub const Result = struct {
    allocator: std.mem.Allocator,
    exit_code: u8,
    stdout: []u8,
    stderr: []u8,

    pub fn deinit(self: *Result) void {
        self.allocator.free(self.stdout);
        self.allocator.free(self.stderr);
        self.* = undefined;
    }

    pub fn expectExit(self: *const Result, expected: u8) !void {
        try std.testing.expectEqual(expected, self.exit_code);
    }

    pub fn expectStdout(self: *const Result, expected: []const u8) !void {
        try std.testing.expectEqualStrings(expected, self.stdout);
    }

    pub fn expectStderr(self: *const Result, expected: []const u8) !void {
        try std.testing.expectEqualStrings(expected, self.stderr);
    }

    pub fn expectStdoutContains(self: *const Result, expected: []const u8) !void {
        try std.testing.expect(std.mem.indexOf(u8, self.stdout, expected) != null);
    }

    pub fn expectStderrContains(self: *const Result, expected: []const u8) !void {
        try std.testing.expect(std.mem.indexOf(u8, self.stderr, expected) != null);
    }
};

pub fn run(allocator: std.mem.Allocator, root: *const Command, args: []const []const u8) !Result {
    var stdout_buffer: [32768]u8 = undefined;
    var stderr_buffer: [32768]u8 = undefined;
    var stdout_writer: std.Io.Writer = .fixed(&stdout_buffer);
    var stderr_writer: std.Io.Writer = .fixed(&stderr_buffer);

    const exit_code = try run_mod.runArgs(allocator, root, args, &stdout_writer, &stderr_writer);
    const stdout_copy = try allocator.dupe(u8, stdout_writer.buffered());
    errdefer allocator.free(stdout_copy);
    const stderr_copy = try allocator.dupe(u8, stderr_writer.buffered());

    return .{
        .allocator = allocator,
        .exit_code = exit_code,
        .stdout = stdout_copy,
        .stderr = stderr_copy,
    };
}
