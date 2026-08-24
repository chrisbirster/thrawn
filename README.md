# Thrawn

**Command with precision.**

Thrawn is a composable command-tree framework for Zig 0.16. It provides the mechanics shared by serious command-line applications while leaving application state and domain logic to the application.

## Features

- nested command trees, aliases, defaults, hidden and deprecated commands
- named positional arguments and validation
- `--long=value`, `-p8080`, clustered short switches, and `--` end-of-options
- typed string/integer/float/choice option values
- required, default, and repeatable options
- option dependencies, conflicts, and mutually exclusive groups
- inherited global options
- grouped generated help with full nested command paths
- configurable `help`, `-h`, and `--help` token handling
- typed application state available to handlers and hooks through `Context.state(T)`
- explicit borrowed context lifetimes with owned argument/option duplication helpers
- before/after hooks inherited through the command tree
- passthrough commands for wrapping other executables
- generated Markdown and man-page documentation
- Bash, Zsh, and Fish completion generation
- context-sensitive child, local-option, and inherited-global-option completion
- application-defined dynamic completion callbacks
- first-class `th.testing` CLI harness
- explicit stdout/stderr writers and conventional exit codes
- command-tree validation and typo suggestions
- native CI on Linux, macOS ARM64, macOS x86_64, and Windows x86_64
- separate consumer-package builds in Debug and ReleaseSafe

## Add Thrawn to a Zig project

For a tagged release, replace `<version>` with the release you want to pin:

```sh
zig fetch --save git+https://github.com/chrisbirster/thrawn#v<version>
```

Then expose the dependency module from your `build.zig` and import it normally:

```zig
const th = @import("thrawn");
```

See [`docs/installation.md`](docs/installation.md) for the complete dependency setup.

## Application state

Pass application-owned state without globals:

```zig
const App = struct {
    verbose: bool = false,
};

fn status(ctx: *th.Context) !void {
    const app = ctx.state(App) orelse return error.MissingAppState;
    if (app.verbose) try ctx.print("verbose status\n", .{});
}

var app: App = .{ .verbose = true };
const code = try th.runWithOptions(init, &root_command, .{
    .state = &app,
});
```

The state pointer is application-owned and must remain valid for the duration of the run.

## Context value lifetimes

`ctx.args`, `ctx.options`, `ctx.argument`, `ctx.optionValue`, and `ctx.optionValueAt` are borrowed views for the duration of the current handler or hook invocation. Do not retain those slices after the invocation returns.

When application state must keep a value, duplicate it with an application-owned allocator:

```zig
fn add(ctx: *th.Context) !void {
    const app = ctx.state(App) orelse return error.MissingAppState;

    app.name = try ctx.dupeArgument(app.arena.allocator(), 0);
    app.fields = try ctx.dupeArguments(app.arena.allocator(), 1);
    app.config_path = try ctx.dupeOptionValue(app.arena.allocator(), "config");
}
```

For repeatable options, `dupeOptionValueAt` duplicates a specific occurrence. See [`docs/lifetimes.md`](docs/lifetimes.md) for ownership and cleanup details.

## Application-owned `help` commands

By default, Thrawn recognizes `help`, `-h`, and `--help`. Applications that want a real `help` command can disable only the literal command token while retaining the option forms:

```zig
const help_command: th.Command = .{
    .name = "help",
    .handler = showHelpTopic,
};

const code = try th.runWithOptions(init, &root_command, .{
    .resolve = .{
        .help_tokens = .{ .command = null },
    },
});
```

Now `app help topic` resolves to the declared command while `app --help` and `app command --help` still use Thrawn's generated help.

## Option model

```zig
const deploy: th.Command = .{
    .name = "deploy",
    .options = &.{
        .{ .long = "dry-run", .short = 'n' },
        .{
            .long = "retries",
            .short = 'r',
            .kind = .value,
            .value_type = .integer,
            .default_value = "3",
        },
        .{
            .long = "tag",
            .short = 't',
            .kind = .value,
            .repeatable = true,
        },
    },
    .handler = runDeploy,
};
```

Thrawn accepts normal CLI forms such as `--retries=3`, `-r3`, `-n`, clustered boolean switches, and `--` to stop option parsing.

## Hooks and passthrough

Parent `.before` hooks run root-to-leaf and `.after` hooks run leaf-to-root. Commands marked `.passthrough = true` stop interpreting option-looking tokens after their first positional argument, which makes wrapper commands straightforward.

## Documentation

The same command tree can generate Markdown or man-page content:

```zig
try th.docs.writeMarkdown(writer, &root_command);
try th.docs.writeMan(writer, &root_command);
```

Run the repository documentation example with:

```sh
zig build docs
```

## Testing

```zig
var result = try th.testing.run(std.testing.allocator, &root, &.{ "deploy", "ship", "--dry-run" });
defer result.deinit();

try result.expectExit(0);
try result.expectStdoutContains("ship");
try result.expectStderr("");
```

## Development

```sh
zig build
zig build test
zig build examples
zig build run -- --help
zig build run -- --verbose fleet status
zig build run -- fleet deploy destroyer -r3 -talpha --tag=beta
zig build run -- exec node --inspect index.js
zig build run -- completion zsh
zig build docs
```

Development follows `feature/* -> dev -> main -> vX.Y.Z`.

Thrawn is licensed under the MIT License. See [`LICENSE`](LICENSE).
