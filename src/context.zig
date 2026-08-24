const std = @import("std");
const Command = @import("command.zig").Command;
const option = @import("options.zig");

pub const Context = struct {
    allocator: std.mem.Allocator,
    root: *const Command,
    command: *const Command,
    command_path: []const *const Command,

    /// Borrowed positional arguments for the current handler/hook invocation.
    /// Do not retain this slice beyond the invocation. Use `dupeArgument` or
    /// `dupeArguments` with an application-owned allocator when values must
    /// outlive the current context.
    args: []const []const u8,

    /// Borrowed parsed option values for the current handler/hook invocation.
    /// Do not retain this slice or values returned by `optionValue` /
    /// `optionValueAt` beyond the invocation. Use `dupeOptionValue` or
    /// `dupeOptionValueAt` when a value must be retained.
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

    /// Duplicate one positional argument into application-owned memory.
    /// The caller owns the returned allocation.
    pub fn dupeArgument(self: *const Context, allocator: std.mem.Allocator, index: usize) !?[]u8 {
        const value = self.argument(index) orelse return null;
        return try allocator.dupe(u8, value);
    }

    /// Duplicate positional arguments from `start` through the end into
    /// application-owned memory. The caller owns both the returned outer slice
    /// and every string allocation inside it.
    pub fn dupeArguments(self: *const Context, allocator: std.mem.Allocator, start: usize) ![][]u8 {
        const source = if (start < self.args.len) self.args[start..] else &.{};
        const duplicated = try allocator.alloc([]u8, source.len);
        errdefer allocator.free(duplicated);

        var initialized: usize = 0;
        errdefer {
            for (duplicated[0..initialized]) |value| allocator.free(value);
        }

        for (source, 0..) |value, index| {
            duplicated[index] = try allocator.dupe(u8, value);
            initialized += 1;
        }

        return duplicated;
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

    /// Duplicate the latest value for an option into application-owned memory.
    /// The caller owns the returned allocation.
    pub fn dupeOptionValue(self: *const Context, allocator: std.mem.Allocator, long: []const u8) !?[]u8 {
        const value = self.optionValue(long) orelse return null;
        return try allocator.dupe(u8, value);
    }

    /// Duplicate one occurrence of a repeatable option into application-owned
    /// memory. The caller owns the returned allocation.
    pub fn dupeOptionValueAt(self: *const Context, allocator: std.mem.Allocator, long: []const u8, wanted: usize) !?[]u8 {
        const value = self.optionValueAt(long, wanted) orelse return null;
        return try allocator.dupe(u8, value);
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
