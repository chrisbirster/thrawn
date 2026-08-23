const std = @import("std");
const Command = @import("command.zig").Command;
const Context = @import("context.zig").Context;
const completion = @import("completion/root.zig");
const help = @import("help.zig");
const options = @import("options.zig");
const path = @import("path.zig");
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
    const code = try runArgs(init.arena.allocator(), root, args, &stdout_file_writer.interface, &stderr_file_writer.interface);
    try stdout_file_writer.interface.flush();
    try stderr_file_writer.interface.flush();
    return code;
}

pub fn runArgs(allocator: std.mem.Allocator, root: *const Command, args: []const []const u8, stdout: *std.Io.Writer, stderr: *std.Io.Writer) !u8 {
    try validation.validate(root);
    if (args.len > 0 and std.mem.eql(u8, args[0], "--thrawn-complete")) {
        try completion.writeCandidates(allocator, stdout, root, args[1..]);
        return exit.success;
    }

    switch (resolve_mod.resolve(root, args)) {
        .help => |selected| {
            try help.write(stdout, selected.root, selected.command);
            return exit.success;
        },
        .unknown => |unknown| {
            try stderr.print("error: unknown command '{s}' for '", .{unknown.value});
            try path.write(stderr, unknown.root, unknown.parent);
            try stderr.print("'\n", .{});
            if (suggestions.bestChild(unknown.parent, unknown.value)) |suggestion| try stderr.print("Did you mean '{s}'?\n", .{suggestion.name});
            try stderr.print("\n", .{});
            try help.write(stderr, unknown.root, unknown.parent);
            return exit.usage;
        },
        .execute => |selected| return execute(allocator, selected.root, selected.command, selected.prefix_args, selected.args, stdout, stderr),
    }
}

fn execute(allocator: std.mem.Allocator, root: *const Command, command: *const Command, prefix_args: []const []const u8, tail_args: []const []const u8, stdout: *std.Io.Writer, stderr: *std.Io.Writer) !u8 {
    var command_stack: [path.max_depth]*const Command = undefined;
    const command_count = path.collect(root, command, &command_stack) orelse return exit.failure;
    const command_path = command_stack[0..command_count];

    var definition_count: usize = command.options.len;
    for (command_path[0 .. command_count - 1]) |ancestor| for (ancestor.options) |definition| if (definition.global) { definition_count += 1; };
    const definitions = try allocator.alloc(options.Option, definition_count);
    defer allocator.free(definitions);
    var definition_index: usize = 0;
    for (command_path[0 .. command_count - 1]) |ancestor| {
        for (ancestor.options) |definition| {
            if (!definition.global) continue;
            definitions[definition_index] = definition;
            definition_index += 1;
        }
    }
    for (command.options) |definition| {
        definitions[definition_index] = definition;
        definition_index += 1;
    }

    const combined = try allocator.alloc([]const u8, prefix_args.len + tail_args.len);
    defer allocator.free(combined);
    var combined_index: usize = 0;
    for (prefix_args) |item| { combined[combined_index] = item; combined_index += 1; }
    for (tail_args) |item| { combined[combined_index] = item; combined_index += 1; }

    var parsed = options.parseWithMode(allocator, definitions, combined, command.passthrough) catch |err| {
        try stderr.print("error: invalid options for '", .{});
        try path.write(stderr, root, command);
        try stderr.print("': {s}\n\n", .{@errorName(err)});
        try help.write(stderr, root, command);
        return exit.usage;
    };
    defer parsed.deinit();

    if (!command.args.valid(parsed.positionals.len)) {
        try stderr.print("error: invalid argument count for '", .{});
        try path.write(stderr, root, command);
        try stderr.print("'\n\n", .{});
        try help.write(stderr, root, command);
        return exit.usage;
    }
    if (command.deprecated) |message| {
        try stderr.print("warning: '", .{});
        try path.write(stderr, root, command);
        try stderr.print("' is deprecated: {s}\n", .{message});
    }

    var context: Context = .{
        .allocator = allocator,
        .root = root,
        .command = command,
        .command_path = command_path,
        .args = parsed.positionals,
        .options = parsed.values,
        .stdout = stdout,
        .stderr = stderr,
    };

    for (command_path) |node| {
        if (node.before) |before| before(&context) catch |err| {
            try stderr.print("error: before hook failed: {s}\n", .{@errorName(err)});
            return exit.failure;
        };
    }

    var handler_error: ?anyerror = null;
    const handler = command.handler orelse unreachable;
    handler(&context) catch |err| { handler_error = err; };

    var reverse_index = command_path.len;
    while (reverse_index > 0) {
        reverse_index -= 1;
        if (command_path[reverse_index].after) |after| after(&context) catch |err| {
            try stderr.print("error: after hook failed: {s}\n", .{@errorName(err)});
            return exit.failure;
        };
    }

    if (handler_error) |err| {
        try stderr.print("error: {s}\n", .{@errorName(err)});
        return exit.failure;
    }
    return exit.success;
}
