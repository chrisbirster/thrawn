# Thrawn

**Command with precision.**

Thrawn is a composable command-tree framework for Zig 0.16. It provides the mechanics shared by serious command-line applications while leaving application state and domain logic to the application.

## Current foundation

- nested command trees
- command aliases
- positional argument-count rules
- long and short options
- generated help
- hidden and deprecated commands
- command-tree validation
- typo suggestions
- explicit stdout/stderr writers
- conventional exit codes
- public API integration tests
- native CI on Linux, macOS ARM, macOS Intel, and Windows

## Development

```sh
zig build
zig build test
zig build examples
zig build run -- --help
zig build run -- fleet status
zig build run -- fleet deploy destroyer --dry-run
```

Development follows `feature/* -> dev -> main -> vX.Y.Z`.

The architecture and roadmap are documented under `docs/` once the documentation foundation PR is merged.
