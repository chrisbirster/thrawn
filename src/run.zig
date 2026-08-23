const std = @import("std");
const Command = @import("command.zig").Command;
const Context = @import("context.zig").Context;
const completion = @import("completion/root.zig");
const help = @import("help.zig");
const options = @import("options.zig");
const resolve_mod = @import("resolve.zig");
const suggestions = @import("suggestions.zig");
const validation = @import("validation.zig");
const exit = @import("errors.zig");

pub fn run(init: std.process.Init, root: *const Command) !u8 {
    const argv = try init.minimal.args.toSlice(init.arena.allocator());
    const args = if (argv.len > 1) argv[1..] else &.{};

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_file_writer: std.Io.File.Writer = .init(.stderr(), init.io, &stderr_buffer);

    const code = try runArgs(
        init.arena.allocator(),
        root,
        args,
        &stdout_file_writer.interface,
        &stderr_file_writer.interface,
    );

    try stdout_file_writer.interface.flush();
    try stderr_file_writer.interface.flush();
    return code;
}

pub fn runArgs(
    allocator: std.mem.Allocator,
    root: *const Command,
    args: []const []const u8,
    stdout: *std.Io.Writer,
    stderr: *std.Io.Writer,
) !u8 {
    try validation.validate(root);

    if (args.len > 0 and std.mem.eql(u8, args[0], "--thrawn-complete")) {
        try completion.writeCandidates(allocator, stdout, root, args[1..]);
        return exit.success;
    }

    switch (resolve_mod.resolve(root, args)) {
        .help => |command| {
            try help.write(stdout, command);
            return exit.success;
        },
        .unknown => |unknown| {
            try stderr.print("error: unknown command '{s}' for '{s}'\n", .{ unknown.value, unknown.parent.name });
            if (suggestions.bestChild(unknown.parent, unknown.value)) |suggestion| {
                try stderr.print("Did you mean '{s}'?\n", .{suggestion.name});
            }
            try stderr.print("\n", .{});
            try help.write(stderr, unknown.parent);
            return exit.usage;
        },
        .execute => |selected| {
            var parsed = options.parse(allocator, selected.command.options, selected.args) catch |err| {
                try stderr.print("error: invalid options for '{s}': {s}\n\n", .{ selected.command.name, @errorName(err) });
                try help.write(stderr, selected.command);
                return exit.usage;
            };
            defer parsed.deinit();

            if (!selected.command.args.valid(parsed.positionals.len)) {
                try stderr.print("error: invalid argument count for '{s}'\n\n", .{selected.command.name});
                try help.write(stderr, selected.command);
                return exit.usage;
            }

            if (selected.command.deprecated) |message| {
                try stderr.print("warning: '{s}' is deprecated: {s}\n", .{ selected.command.name, message });
            }

            var context: Context = .{
                .allocator = allocator,
                .args = parsed.positionals,
                .options = parsed.values,
                .stdout = stdout,
                .stderr = stderr,
            };

            const handler = selected.command.handler orelse unreachable;
            handler(&context) catch |err| {
                try stderr.print("error: {s}\n", .{@errorName(err)});
                return exit.failure;
            };
            return exit.success;
        },
    }
}
