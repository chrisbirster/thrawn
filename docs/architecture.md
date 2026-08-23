# Architecture

## Purpose

Thrawn is a reusable Zig framework for building command-line applications from a statically declared command tree.

The framework owns command structure and command-line mechanics. It does not own application business logic or persistent application state.

The primary execution flow is:

```text
process arguments
      ↓
parse command-line tokens
      ↓
resolve command tree
      ↓
validate arguments/options
      ↓
create execution context
      ↓
run selected handler
      ↓
return output + exit status
```

## Design goals

Thrawn should be:

1. **Tree-first** — nested commands are the primary organizing model.
2. **Static and explicit** — command trees are ordinary Zig declarations known at compile time.
3. **Small at the boundary** — applications should need only `@import("thrawn")` and a few public types/functions.
4. **Testable** — parsing, resolution, help, validation, and completion must be testable without launching subprocesses.
5. **Composable in code** — a large application can split command branches across source files without requiring separate packages or repositories.
6. **Predictable** — ambiguous trees and invalid declarations should fail validation rather than produce surprising runtime behavior.
7. **Shell-friendly** — stdout, stderr, exit codes, help, and completions should behave like a well-designed Unix CLI.

## Non-goals

Thrawn is not responsible for:

- configuration files
- persistent variables
- databases
- logging frameworks
- HTTP clients
- daemon communication
- runtime plugin discovery
- package management
- terminal UI frameworks
- application-specific environment management

Those belong to the application using Thrawn.

## Target module layout

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
└── completion/
    ├── root.zig
    ├── engine.zig
    ├── bash.zig
    ├── zsh.zig
    └── fish.zig
```

This is the target 1.0 structure. Development begins with fewer files and splits responsibilities out as they become substantial.

## Module responsibilities

### `root.zig`

Public package surface.

Consumers should normally write:

```zig
const th = @import("thrawn");
```

`root.zig` re-exports stable public types and entry points. Internal file organization should not leak into consuming applications.

### `command.zig`

Defines the static command declaration.

A command can be:

- a branch containing children
- a leaf with a handler
- both a branch and an executable command

Expected concerns include:

- name
- aliases
- summary/description
- child commands
- handler
- positional argument declarations
- option declarations
- default child
- hidden/deprecated metadata
- completion callback metadata

### `context.zig`

Defines data available during one execution.

A context should contain execution-time state such as:

- selected command
- full command path
- positional values
- parsed options
- allocator
- stdout writer
- stderr writer

The command declaration is static. The context is per invocation.

### `resolve.zig`

Walks the command tree using input tokens and determines which command owns the remaining input.

Resolution should not perform application business logic.

Example:

```text
input:  dz nutz add node@26

path:   dz → nutz → add
args:   ["node@26"]
```

### `run.zig`

Coordinates one complete invocation:

1. obtain process arguments
2. resolve the command
3. parse and validate input owned by that command
4. construct the context
5. invoke the handler
6. map framework failures to useful errors/exit codes

`run.zig` should orchestrate other modules instead of becoming the place where all parsing logic lives.

### `arguments.zig`

Owns positional argument declarations and validation.

Examples:

```text
<package>
<source> <destination>
[file...]
```

It should support required/optional positional values and count validation without forcing handlers to repeatedly perform manual checks.

### `options.zig`

Owns named option parsing and declarations.

Examples:

```text
--dry-run
-n
--profile testing
--count 3
```

The option system should distinguish declaration from parsed values and detect collisions or malformed input.

### `validation.zig`

Validates the developer-declared command tree before normal execution.

Examples of invalid declarations:

- empty command names
- duplicate sibling command names
- aliases colliding with names or aliases
- duplicate option names
- duplicate short options
- malformed positional declarations
- invalid default-child references

Tree validation exists to catch developer errors early.

### `help.zig`

Generates help and usage from command metadata.

It should understand the full command path so nested help can display:

```text
Usage:
  dz nutz add <package> [options]
```

instead of only:

```text
add <package>
```

### `errors.zig`

Defines framework-level error/result types and their mapping to messages and exit statuses.

Application errors remain application-defined.

### `suggestions.zig`

Provides optional typo assistance for invalid commands/options.

Example:

```text
error: unknown command "udpate" for "dz nutz"

did you mean "update"?
```

This should remain separate from core resolution so suggestion quality can evolve without complicating tree traversal.

### `completion/engine.zig`

Computes completion candidates from the same command tree used for runtime resolution.

It should support:

- child command names
- aliases when appropriate
- options
- positional custom completion callbacks
- hidden command filtering

### `completion/bash.zig`, `zsh.zig`, `fish.zig`

Shell-specific integration layers. They should adapt the common completion engine rather than each implement command semantics independently.

## Static tree model

A typical tree should look approximately like this:

```zig
const status = th.Command{
    .name = "status",
    .handler = showStatus,
};

const daemon = th.Command{
    .name = "daemon",
    .children = &.{
        &status,
    },
};

const root = th.Command{
    .name = "dz",
    .children = &.{
        &daemon,
    },
};
```

This creates:

```text
dz
└── daemon
    └── status
```

The declarations may live in separate Zig files for organization, but they remain part of one application repository and one compiled command tree.

## Public API boundary

The ideal consumer experience is small:

```zig
const std = @import("std");
const th = @import("thrawn");

const version = th.Command{
    .name = "version",
    .handler = showVersion,
};

const root = th.Command{
    .name = "demo",
    .children = &.{&version},
};

pub fn main(init: std.process.Init) !void {
    try th.run(init, &root);
}
```

As the internal architecture expands, this basic shape should remain stable.

## Output model

Normal handler results must go to stdout. Diagnostics, usage errors, and failures must go to stderr.

This matters for shell composition:

```sh
dz nutz list > installed.txt
```

Only the command result should be redirected into `installed.txt`.

All output should flow through injectable writers so exact behavior can be unit tested.

## Exit status model

The exact API may evolve, but Thrawn must distinguish at least:

```text
0  success
1  command/application failure
2  invalid command-line usage
```

Framework behavior should be deterministic and documented.

## Dependency direction

The architecture should flow inward toward simple declarations and data structures:

```text
completion shell adapters ─┐
help/suggestions           │
run                        ├──> resolution + parsing + validation
                           │              ↓
                           └──────────> Command / Context
```

Core command declarations should not depend on shell-specific completion implementations or application-specific services.

## Growth rule

Do not create a source file merely because it appears in the target tree. A module should be split out when it has a real responsibility, meaningful implementation, and tests of its own.
