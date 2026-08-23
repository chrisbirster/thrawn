# Thrawn

**Command with precision.**

Thrawn is a composable command-tree framework for Zig 0.16. It provides the mechanics shared by serious command-line applications while leaving application state and domain logic to the application.

## Features

- nested command trees and aliases
- positional argument-count rules
- long and short boolean/value options
- generated help
- hidden and deprecated commands
- command-tree validation
- typo suggestions
- explicit stdout/stderr writers
- conventional exit codes
- Bash, Zsh, and Fish completion generation
- context-sensitive child and option completion
- application-defined dynamic completion callbacks
- public API integration tests
- native CI on Linux, macOS ARM, macOS Intel, and Windows

## Completion

Applications can expose a normal command that calls `th.completion.writeScript` for Bash, Zsh, or Fish. Generated scripts use Thrawn's reserved `--thrawn-complete` protocol to ask the running application for candidates derived from its command tree.

Commands may provide dynamic positional candidates:

```zig
fn completePackages(ctx: *th.CompletionContext) !void {
    try ctx.candidate("node");
    try ctx.candidate("zig");
    try ctx.candidate("ripgrep");
}

const add_command: th.Command = .{
    .name = "add",
    .complete = completePackages,
    .handler = add,
};
```

## Development

```sh
zig build
zig build test
zig build examples
zig build run -- --help
zig build run -- fleet status
zig build run -- fleet deploy destroyer --dry-run
zig build run -- completion zsh
zig build run -- --thrawn-complete fleet de
```

Development follows `feature/* -> dev -> main -> vX.Y.Z`.

See `docs/` for architecture, command model, testing strategy, and roadmap.
