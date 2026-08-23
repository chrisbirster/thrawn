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

For a tagged release:

```sh
zig fetch --save git+https://github.com/chrisbirster/thrawn#v0.1.0
```

Then expose the dependency module from your `build.zig` and import it normally:

```zig
const th = @import("thrawn");
```

See [`docs/installation.md`](docs/installation.md) for the complete dependency setup.

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
