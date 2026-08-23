# Roadmap

This roadmap defines the path from the initial `zig init` scaffold to Thrawn 1.0.

The milestones describe behavior, not mandatory file counts. The implementation grew into modules only as their responsibilities became distinct.

## Implementation status

The Phase 0 through Phase 3 architecture is now implemented on `dev` through feature branches. Before a 1.0 release, the remaining work is release hardening: API review, package metadata/version synchronization, installation documentation, and selecting a project license.

## Phase 0 — Command engine

Implemented:

- `Command`
- nested child commands
- aliases
- leaf handlers
- positional values passed to handlers
- basic resolution
- generated help
- unit tests for tree traversal

## Phase 1 — Reliable execution core

Implemented:

- proper stdout writer
- proper stderr writer
- explicit framework errors and exit codes
- full nested command paths in resolution/help/errors
- named positional declarations and validation
- useful unknown-command diagnostics
- exact tests for help and error output

## Phase 2 — Complete core CLI framework

Implemented:

- long options
- short options
- boolean switches
- valued options
- option validation
- default child commands
- hidden commands
- deprecated command metadata
- command-tree validation
- duplicate/collision detection
- typo suggestions
- generated usage/help formatting

At the end of Phase 2, Thrawn is considered a complete core framework and is suitable for substantial real-world use.

## Phase 3 — Shell completion and 1.0

Implemented:

- shared completion engine
- child-command completion
- option completion
- positional completion callbacks
- hidden-command filtering
- Bash integration
- Zsh integration
- Fish integration

The same command tree drives runtime resolution and completion, while application-defined completers can provide domain-specific values.

## Target source layout

```text
src/
├── root.zig
├── command.zig
├── context.zig
├── resolve.zig
├── run.zig
├── arguments.zig
├── options.zig
├── validation.zig
├── help.zig
├── errors.zig
├── suggestions.zig
├── path.zig
└── completion/
    ├── root.zig
    ├── engine.zig
    ├── bash.zig
    ├── zsh.zig
    └── fish.zig
```

## Examples

```text
examples/
├── basic/
├── nested/
├── options/
└── completion/
```

## Test suite

```text
tests/
├── root.zig
├── resolve_test.zig
├── options_test.zig
├── help_test.zig
├── validation_test.zig
└── completion_test.zig
```

## Release hardening

Before `v1.0.0`:

- review the public API names and remove accidental surface area
- synchronize `build.zig.zon` versioning with release tags
- document dependency installation and shell completion installation
- select and add the project license
- maintain `CHANGELOG.md`
- run the native Linux/macOS/Windows matrix from the release tag

## Release rule

No feature milestone is released directly from a feature branch.

```text
feature/*
    ↓
   dev
    ↓
  main
    ↓
 vX.Y.Z
```

A version tag is cut only from `main` after the release PR from `dev` is merged.
