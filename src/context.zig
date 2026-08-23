const std = @import("std");
const option = @import("options.zig");

pub const Context = struct {
    allocator: std.mem.Allocator,
    args: []const []const u8,
    options: []const option.Value = &.{},
    stdout: *std.Io.Writer,
    stderr: *std.Io.Writer,

    pub fn argument(self: *const Context, index: usize) ?[]const u8 {
        if (index >= self.args.len) return null;
        return self.args[index];
    }

    pub fn hasOption(self: *const Context, long: []const u8) bool {
        return self.optionValue(long) != null;
    }

    pub fn optionValue(self: *const Context, long: []const u8) ?[]const u8 {
        var index: usize = self.options.len;
        while (index > 0) {
            index -= 1;
            const item = self.options[index];
            if (std.mem.eql(u8, item.option.long, long)) {
                return item.value orelse "";
            }
        }
        return null;
    }

    pub fn print(
        self: *Context,
        comptime format: []const u8,
        values: anytype,
    ) std.Io.Writer.Error!void {
        try self.stdout.print(format, values);
    }

    pub fn printError(
        self: *Context,
        comptime format: []const u8,
        values: anytype,
    ) std.Io.Writer.Error!void {
        try self.stderr.print(format, values);
    }
};
