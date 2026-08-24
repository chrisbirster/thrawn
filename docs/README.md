# Thrawn Documentation

Thrawn is a composable command-tree framework for Zig.

Its responsibility is intentionally narrow: describe command trees, resolve command paths, validate command-line input, generate help and completion, and execute the selected handler. Application-specific state, configuration, persistence, networking, and daemon behavior belong to applications that use Thrawn.

## Documents

- [Architecture](architecture.md) — module responsibilities, data flow, and package boundaries.
- [Command Model](command-model.md) — how commands, branches, leaves, handlers, aliases, arguments, and options fit together.
- [Context Value Lifetimes](lifetimes.md) — borrowed handler values, owned copies, and retention rules.
- [Installation](installation.md) — dependency and build-module setup.
- [Roadmap](roadmap.md) — current milestones from released functionality through 1.0.
- [Testing](testing.md) — test strategy, behavioral guarantees, and release coverage.
- [Development](development.md) — branch workflow, feature development, pull requests, and repository conventions.
- [Design Decisions](design-decisions.md) — decisions already made and features intentionally kept outside Thrawn.

## Repository layout

```text
thrawn/
├── src/
│   ├── root.zig
│   ├── command.zig
│   ├── context.zig
│   ├── resolve.zig
│   ├── run.zig
│   ├── arguments.zig
│   ├── options.zig
│   ├── validation.zig
│   ├── help.zig
│   ├── errors.zig
│   ├── suggestions.zig
│   ├── path.zig
│   ├── docs.zig
│   ├── testing.zig
│   └── completion/
│       ├── root.zig
│       ├── engine.zig
│       ├── bash.zig
│       ├── zsh.zig
│       └── fish.zig
├── examples/
├── tests/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── build.zig
└── build.zig.zon
```

## Core principle

Thrawn generalizes the mechanics of a CLI, not the meaning of an application's commands.

```text
Thrawn:
  How do I find, validate, document, complete, and run a command?

Application:
  What does that command actually do?
```
