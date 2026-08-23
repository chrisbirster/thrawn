//! Thrawn is a composable command-tree framework for Zig.

pub const arguments = @import("arguments.zig");
pub const options = @import("options.zig");
pub const errors = @import("errors.zig");
pub const help = @import("help.zig");
pub const path = @import("path.zig");
pub const suggestions = @import("suggestions.zig");
pub const validation = @import("validation.zig");
pub const completion = @import("completion/root.zig");

pub const Command = @import("command.zig").Command;
pub const Handler = @import("command.zig").Handler;
pub const CompletionContext = @import("command.zig").CompletionContext;
pub const Completer = @import("command.zig").Completer;
pub const Context = @import("context.zig").Context;
pub const Resolution = @import("resolve.zig").Resolution;
pub const resolve = @import("resolve.zig").resolve;
pub const run = @import("run.zig").run;
pub const runArgs = @import("run.zig").runArgs;

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
}
