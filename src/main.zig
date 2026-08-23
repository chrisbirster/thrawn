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
    .usage = "deploy <ship> [--dry-run]",
    .args = .{ .exact = 1 },
    .options = &.{
        .{ .long = "dry-run", .short = 'n', .summary = "Show the deployment without executing it" },
    },
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

const root_command: th.Command = .{
    .name = "thrawn-demo",
    .summary = "Command with precision",
    .version = "0.1.0-dev",
    .children = &.{ &fleet_command, &version_command },
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

fn version(ctx: *th.Context) !void {
    try ctx.print("thrawn-demo 0.1.0-dev\n", .{});
}
