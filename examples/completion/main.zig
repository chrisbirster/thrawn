const std = @import("std");
const th = @import("thrawn");

const open_command: th.Command = .{
    .name = "open",
    .args = .{ .exact = 1 },
    .complete = completeTargets,
    .handler = open,
};

const completion_command: th.Command = .{
    .name = "completion",
    .args = .{ .exact = 1 },
    .handler = generateCompletion,
};

const root_command: th.Command = .{
    .name = "completion-example",
    .children = &.{ &open_command, &completion_command },
};

pub fn main(init: std.process.Init) !void {
    const code = try th.run(init, &root_command);
    if (code != 0) std.process.exit(code);
}

fn open(ctx: *th.Context) !void {
    try ctx.print("Opening {s}.\n", .{ctx.argument(0).?});
}

fn completeTargets(ctx: *th.CompletionContext) !void {
    try ctx.candidate("alpha");
    try ctx.candidate("beta");
    try ctx.candidate("gamma");
}

fn generateCompletion(ctx: *th.Context) !void {
    const shell = th.completion.Shell.parse(ctx.argument(0).?) orelse return error.UnsupportedShell;
    try th.completion.writeScript(ctx.stdout, shell, root_command.name);
}
