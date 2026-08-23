const std = @import("std");
const th = @import("thrawn");

const status_command: th.Command = .{
    .name = "status",
    .summary = "Show fleet status",
    .handler = status,
};

const deploy_command: th.Command = .{
    .name = "deploy",
    .summary = "Deploy a ship",
    .args = .{ .positionals = &.{.{ .name = "ship", .summary = "Ship to deploy" }} },
    .options = &.{
        .{ .long = "dry-run", .short = 'n', .summary = "Show the deployment without executing it" },
    },
    .complete = completeShips,
    .handler = deploy,
};

const fleet_command: th.Command = .{
    .name = "fleet",
    .summary = "Manage the fleet",
    .children = &.{ &status_command, &deploy_command },
};

const version_command: th.Command = .{
    .name = "version",
    .aliases = &.{"v"},
    .summary = "Print version information",
    .handler = version,
};

const completion_command: th.Command = .{
    .name = "completion",
    .summary = "Generate a shell completion script",
    .args = .{ .positionals = &.{.{ .name = "shell", .summary = "bash, zsh, or fish" }} },
    .handler = generateCompletion,
};

const root_command: th.Command = .{
    .name = "thrawn-demo",
    .summary = "Command with precision",
    .version = "0.1.0-dev",
    .children = &.{ &fleet_command, &version_command, &completion_command },
};

pub fn main(init: std.process.Init) !void {
    const code = try th.run(init, &root_command);
    if (code != th.errors.success) std.process.exit(code);
}

fn status(ctx: *th.Context) !void {
    try ctx.print("The fleet is operating within parameters.\n", .{});
}

fn deploy(ctx: *th.Context) !void {
    const ship = ctx.argument(0).?;
    if (ctx.hasOption("dry-run")) {
        try ctx.print("Would deploy {s}.\n", .{ship});
        return;
    }
    try ctx.print("Deploying {s}.\n", .{ship});
}

fn completeShips(ctx: *th.CompletionContext) !void {
    try ctx.candidate("destroyer");
    try ctx.candidate("cruiser");
    try ctx.candidate("carrier");
}

fn version(ctx: *th.Context) !void {
    try ctx.print("thrawn-demo 0.1.0-dev\n", .{});
}

fn generateCompletion(ctx: *th.Context) !void {
    const shell_name = ctx.argument(0).?;
    const shell = th.completion.Shell.parse(shell_name) orelse {
        try ctx.printError("error: unsupported shell '{s}'\n", .{shell_name});
        return error.UnsupportedShell;
    };
    try th.completion.writeScript(ctx.stdout, shell, root_command.name);
}
