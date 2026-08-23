const std = @import("std");
const Context = @import("context.zig").Context;
const arguments = @import("arguments.zig");
const option = @import("options.zig");

pub const Handler = *const fn (*Context) anyerror!void;

pub const CompletionContext = struct {
    allocator: std.mem.Allocator,
    args: []const []const u8,
    prefix: []const u8,
    writer: *std.Io.Writer,

    pub fn candidate(self: *CompletionContext, value: []const u8) std.Io.Writer.Error!void {
        if (std.mem.startsWith(u8, value, self.prefix)) {
            try self.writer.print("{s}\n", .{value});
        }
    }
};

pub const Completer = *const fn (*CompletionContext) anyerror!void;

pub const Command = struct {
    name: []const u8,
    aliases: []const []const u8 = &.{},
    summary: []const u8 = "",
    description: []const u8 = "",
    usage: ?[]const u8 = null,
    version: ?[]const u8 = null,
    children: []const *const Command = &.{},
    default_child: ?*const Command = null,
    handler: ?Handler = null,
    complete: ?Completer = null,
    args: arguments.Rules = .{},
    options: []const option.Option = &.{},
    hidden: bool = false,
    deprecated: ?[]const u8 = null,

    pub fn matches(self: *const Command, value: []const u8) bool {
        if (std.mem.eql(u8, self.name, value)) return true;
        for (self.aliases) |alias| {
            if (std.mem.eql(u8, alias, value)) return true;
        }
        return false;
    }

    pub fn findChild(self: *const Command, value: []const u8) ?*const Command {
        for (self.children) |child| {
            if (child.matches(value)) return child;
        }
        return null;
    }
};

test "commands match names and aliases" {
    const command: Command = .{
        .name = "version",
        .aliases = &.{ "v", "ver" },
    };
    try std.testing.expect(command.matches("version"));
    try std.testing.expect(command.matches("v"));
    try std.testing.expect(!command.matches("status"));
}
