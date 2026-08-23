# Thrawn Documentation

Thrawn is a composable command-tree framework for Zig.

Its responsibility is intentionally narrow: describe command trees, resolve command paths, validate command-line input, generate help and completion, and execute the selected handler. Application-specific state, configuration, persistence, networking, and daemon behavior belong to applications that use Thrawn.

## Documents

- [Architecture](architecture.md) — target 1.0 module layout, responsibilities, data flow, and package boundaries.
- [Command Model](command-model.md) — how commands, branches, leaves, handlers, aliases, arguments, and options fit together.
- [Roadmap](roadmap.md) — implementation phases and release milestones from the initial command engine through 1.0.
- [Testing](testing.md) — test strategy, behavioral guarantees, and what must be covered before release.
- [Development](development.md) — branch workflow, feature development, pull requests, and repository conventions.
- [Design Decisions](design-decisions.md) — decisions already made and features intentionally kept outside Thrawn.

## Target repository layout

The following is the target architecture, not a requirement to create empty files immediately. Modules should be split out when their responsibilities become real and independently testable.

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
│   └── completion/
│       ├── root.zig
│       ├── engine.zig
│       ├── bash.zig
│       ├── zsh.zig
│       └── fish.zig
├── examples/
│   ├── basic/
│   ├── nested/
│   ├── options/
│   └── completion/
├── tests/
│   ├── resolve_test.zig
│   ├── options_test.zig
│   ├── help_test.zig
│   ├── validation_test.zig
│   └── completion_test.zig
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
