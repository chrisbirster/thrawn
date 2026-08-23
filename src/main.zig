const std = @import("std");
const th = @import("thrawn");

const status_command: th.Command = .{
    .name = "status",
    .group = "Fleet Commands",
    .summary = "Show fleet status",
    .handler = status,
};

const deploy_command: th.Command = .{
    .name = "deploy",
    .group = "Fleet Commands",
    .summary = "Deploy a ship",
    .args = .{ .positionals = &.{.{ .name = "ship", .summary = "Ship to deploy" }} },
    .options = &.{
        .{ .long = "dry-run", .short = 'n', .summary = "Show the deployment without executing it", .conflicts_with = &.{"force"} },
        .{ .long = "force", .short = 'f', .summary = "Force deployment", .conflicts_with = &.{"dry-run"} },
        .{ .long = "retries", .short = 'r', .kind = .value, .value_type = .integer, .default_value = "1", .value_name = "count", .summary = "Retry count" },
        .{ .long = "tag", .short = 't', .kind = .value, .repeatable = true, .summary = "Attach a repeatable tag" },
    },
    .complete = completeShips,
    .handler = deploy,
};

const fleet_command: th.Command = .{
    .name = "fleet",
    .group = "Fleet Commands",
    .summary = "Manage the fleet",
    .children = &.{ &status_command, &deploy_command },
};

const exec_command: th.Command = .{
    .name = "exec",
    .group = "Utility Commands",
    .summary = "Pass trailing arguments through unchanged",
    .args = .{ .positionals = &.{
        .{ .name = "program", .summary = "Program to execute" },
        .{ .name = "args", .summary = "Arguments passed through", .required = false, .variadic = true },
    } },
    .passthrough = true,
    .handler = exec,
};

const version_command: th.Command = .{
    .name = "version",
    .group = "Developer Commands",
    .aliases = &.{"v"},
    .summary = "Print version information",
    .handler = printVersion,
};

const completion_command: th.Command = .{
    .name = "completion",
    .group = "Developer Commands",
    .summary = "Generate a shell completion script",
    .args = .{ .positionals = &.{.{ .name = "shell", .summary = "bash, zsh, or fish" }} },
    .handler = generateCompletion,
};

const docs_command: th.Command = .{
    .name = "docs",
    .group = "Developer Commands",
    .summary = "Generate command documentation",
    .args = .{ .positionals = &.{.{ .name = "format", .summary = "markdown or man" }} },
    .handler = generateDocs,
};

const root_command: th.Command = .{
    .name = "thrawn-demo",
    .summary = "Command with precision",
    .version = th.version,
    .options = &.{
        .{ .long = "verbose", .short = 'V', .global = true, .summary = "Enable verbose diagnostics" },
        .{ .long = "color", .kind = .value, .value_type = .choice, .choices = &.{ "auto", "always", "never" }, .default_value = "auto", .global = true, .summary = "Color mode" },
    },
    .before = before,
    .after = after,
    .children = &.{ &fleet_command, &exec_command, &version_command, &completion_command, &docs_command },
};

pub fn main(init: std.process.Init) !void {
    const code = try th.run(init, &root_command);
    if (code != th.errors.success) std.process.exit(code);
}

fn before(ctx: *th.Context) !void {
    if (ctx.hasOption("verbose")) try ctx.printError("verbose: running {s}\n", .{ctx.command.name});
}

fn after(_: *th.Context) !void {}

fn status(ctx: *th.Context) !void {
    try ctx.print("The fleet is operating within parameters.\n", .{});
}

fn deploy(ctx: *th.Context) !void {
    const ship = ctx.argument(0).?;
    const retries = (try ctx.optionInt(u32, "retries")) orelse 1;
    if (ctx.hasOption("dry-run")) {
        try ctx.print("Would deploy {s} with {d} attempt(s).\n", .{ ship, retries });
        return;
    }
    try ctx.print("Deploying {s} with {d} attempt(s).\n", .{ ship, retries });
}

fn exec(ctx: *th.Context) !void {
    for (ctx.args, 0..) |arg, index| {
        if (index != 0) try ctx.print(" ", .{});
        try ctx.print("{s}", .{arg});
    }
    try ctx.print("\n", .{});
}

fn completeShips(ctx: *th.CompletionContext) !void {
    try ctx.candidate("destroyer");
    try ctx.candidate("cruiser");
    try ctx.candidate("carrier");
}

fn printVersion(ctx: *th.Context) !void {
    try ctx.print("thrawn-demo {s}\n", .{th.version});
}

fn generateCompletion(ctx: *th.Context) !void {
    const shell_name = ctx.argument(0).?;
    const shell = th.completion.Shell.parse(shell_name) orelse return error.UnsupportedShell;
    try th.completion.writeScript(ctx.stdout, shell, root_command.name);
}

fn generateDocs(ctx: *th.Context) !void {
    const format = ctx.argument(0).?;
    if (std.mem.eql(u8, format, "markdown")) return th.docs.writeMarkdown(ctx.stdout, &root_command);
    if (std.mem.eql(u8, format, "man")) return th.docs.writeMan(ctx.stdout, &root_command);
    return error.UnsupportedDocumentationFormat;
}
