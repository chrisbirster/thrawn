# Roadmap

This roadmap defines the path from the current `zig init` scaffold to Thrawn 1.0.

The milestones describe behavior, not mandatory file counts. Start simple, split modules when responsibilities become distinct, and keep the public API small throughout.

## Phase 0 — Command engine

Goal: prove the core tree model.

Implement:

- `Command`
- nested child commands
- aliases
- leaf handlers
- positional values passed to handlers
- basic resolution
- basic generated help
- unit tests for tree traversal

Initial implementation may live almost entirely in `src/root.zig` with `src/main.zig` serving as a demonstration executable.

Expected commands:

```text
thrawn-demo
thrawn-demo fleet
thrawn-demo fleet status
thrawn-demo fleet deploy destroyer
thrawn-demo version
thrawn-demo v
```

Exit criteria:

- nested traversal works
- aliases resolve to the same command
- remaining tokens reach the selected leaf
- branches show help when no executable leaf is selected
- resolution is directly unit testable

Suggested feature branch:

```text
feature/command-tree-engine
```

## Phase 1 — Reliable execution core

Goal: make Thrawn safe and testable enough to use in another project.

Implement:

- proper stdout writer
- proper stderr writer
- explicit framework errors
- consistent exit-code behavior
- full command paths in resolution results
- positional argument declarations and validation
- useful unknown-command diagnostics
- exact tests for help and error output

Likely modules introduced here:

```text
command.zig
context.zig
resolve.zig
run.zig
arguments.zig
help.zig
errors.zig
```

Suggested feature branches:

```text
feature/output-writers
feature/error-model
feature/argument-validation
feature/help-output
```

Exit criteria:

- command output can be redirected cleanly
- errors go to stderr
- framework usage failures return a documented nonzero status
- handlers receive already-validated basic positional input
- nested usage/help displays the complete path
- all normal behavior is testable without subprocesses

## Phase 2 — Complete core CLI framework

Goal: make Thrawn functionally complete for production CLI applications.

Implement:

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
- polished help/usage formatting

Likely modules introduced here:

```text
options.zig
validation.zig
suggestions.zig
```

Suggested feature branches:

```text
feature/options
feature/default-commands
feature/tree-validation
feature/suggestions
feature/help-formatting
```

Exit criteria:

- applications can express normal command-line interfaces without writing their own parsing layer
- invalid command declarations fail early
- option/name collisions cannot produce ambiguous behavior
- help output fully describes commands, positionals, and options
- error messages identify the failing command path

At the end of Phase 2, Thrawn is considered a complete core framework and is suitable for substantial real-world use.

## Phase 3 — Shell completion and 1.0

Goal: make the framework feel complete in interactive shells.

Implement:

- shared completion engine
- child-command completion
- option completion
- positional completion callbacks
- hidden-command filtering
- Bash integration
- Zsh integration
- Fish integration

Target modules:

```text
completion/
├── root.zig
├── engine.zig
├── bash.zig
├── zsh.zig
└── fish.zig
```

Suggested feature branches:

```text
feature/completion-engine
feature/zsh-completion
feature/bash-completion
feature/fish-completion
```

Exit criteria:

- the same command tree drives runtime resolution and completion
- static candidates require no application duplication
- applications can provide dynamic candidates for domain-specific values
- Bash, Zsh, and Fish have documented installation paths

## Examples

Examples should be added as the corresponding capability becomes stable:

```text
examples/
├── basic/
├── nested/
├── options/
└── completion/
```

Each example should be intentionally small and demonstrate one concept clearly.

## Test suite

As the implementation grows, move behavioral coverage into dedicated files:

```text
tests/
├── resolve_test.zig
├── options_test.zig
├── help_test.zig
├── validation_test.zig
└── completion_test.zig
```

Tests may remain colocated with implementation early in development if that makes iteration easier.

## Release milestones

Suggested version progression:

### `v0.1.0`

Command engine is proven:

- tree traversal
- aliases
- handlers
- basic help
- basic tests

### `v0.2.0`–`v0.4.x`

Reliable execution work:

- output model
- error model
- positional argument validation
- improved help

### `v0.5.0`–`v0.8.x`

Phase 2 core framework:

- options
- tree validation
- defaults
- hidden/deprecated commands
- typo suggestions

### `v0.9.0`

1.0 release candidate period:

- completion engine
- shell adapters
- documentation/examples
- public API stabilization

### `v1.0.0`

Stable public API with:

- command trees
- arguments
- options
- help
- errors/exit behavior
- validation
- completion for Bash/Zsh/Fish
- comprehensive tests and examples

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
