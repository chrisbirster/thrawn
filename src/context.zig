const std = @import("std");
const Command = @import("command.zig").Command;
const option = @import("options.zig");

pub const Context = struct {
    allocator: std.mem.Allocator,
    root: *const Command,
    command: *const Command,
    command_path: []const *const Command,
    args: []const []const u8,
    options: []const option.Value = &.{},
    stdout: *std.Io.Writer,
    stderr: *std.Io.Writer,
    app_state: ?*anyopaque = null,

    pub fn state(self: *const Context, comptime T: type) ?*T {
        const raw = self.app_state orelse return null;
        return @ptrCast(@alignCast(raw));
    }

    pub fn argument(self: *const Context, index: usize) ?[]const u8 {
        if (index >= self.args.len) return null;
        return self.args[index];
    }

    pub fn hasOption(self: *const Context, long: []const u8) bool {
        return self.optionCount(long) > 0;
    }

    pub fn optionCount(self: *const Context, long: []const u8) usize {
        var total: usize = 0;
        for (self.options) |item| {
            if (std.mem.eql(u8, item.option.long, long)) total += 1;
        }
        return total;
    }

    pub fn optionValue(self: *const Context, long: []const u8) ?[]const u8 {
        var index: usize = self.options.len;
        while (index > 0) {
            index -= 1;
            const item = self.options[index];
            if (std.mem.eql(u8, item.option.long, long)) return item.value orelse "";
        }
        return null;
    }

    pub fn optionValueAt(self: *const Context, long: []const u8, wanted: usize) ?[]const u8 {
        var found: usize = 0;
        for (self.options) |item| {
            if (!std.mem.eql(u8, item.option.long, long)) continue;
            if (found == wanted) return item.value orelse "";
            found += 1;
        }
        return null;
    }

    pub fn optionInt(self: *const Context, comptime T: type, long: []const u8) !?T {
        const value = self.optionValue(long) orelse return null;
        return try std.fmt.parseInt(T, value, 0);
    }

    pub fn optionFloat(self: *const Context, comptime T: type, long: []const u8) !?T {
        const value = self.optionValue(long) orelse return null;
        return try std.fmt.parseFloat(T, value);
    }

    pub fn optionEnum(self: *const Context, comptime E: type, long: []const u8) ?E {
        const value = self.optionValue(long) orelse return null;
        return std.meta.stringToEnum(E, value);
    }

    pub fn print(self: *Context, comptime format: []const u8, values: anytype) std.Io.Writer.Error!void {
        try self.stdout.print(format, values);
    }

    pub fn printError(self: *Context, comptime format: []const u8, values: anytype) std.Io.Writer.Error!void {
        try self.stderr.print(format, values);
    }
};
