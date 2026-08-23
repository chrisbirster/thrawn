//! Thrawn is a composable command-tree framework for Zig.

const build_options = @import("build_options");

pub const version: []const u8 = build_options.version;

pub const arguments = @import("arguments.zig");
pub const options = @import("options.zig");
pub const errors = @import("errors.zig");
pub const help = @import("help.zig");
pub const path = @import("path.zig");
pub const suggestions = @import("suggestions.zig");
pub const validation = @import("validation.zig");
pub const completion = @import("completion/root.zig");
pub const docs = @import("docs.zig");
pub const testing = @import("testing.zig");

pub const Command = @import("command.zig").Command;
pub const Handler = @import("command.zig").Handler;
pub const Hook = @import("command.zig").Hook;
pub const CompletionContext = @import("command.zig").CompletionContext;
pub const Completer = @import("command.zig").Completer;
pub const Context = @import("context.zig").Context;
pub const Resolution = @import("resolve.zig").Resolution;
pub const resolve = @import("resolve.zig").resolve;
pub const run = @import("run.zig").run;
pub const runArgs = @import("run.zig").runArgs;

test "package version is available through the public module" {
    try @import("std").testing.expect(version.len > 0);
}

test {
    _ = @import("arguments.zig");
    _ = @import("options.zig");
    _ = @import("command.zig");
    _ = @import("resolve.zig");
    _ = @import("validation.zig");
    _ = @import("suggestions.zig");
    _ = @import("path.zig");
    _ = @import("help.zig");
    _ = @import("completion/root.zig");
    _ = @import("docs.zig");
    _ = @import("testing.zig");
}
