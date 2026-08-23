# Design Decisions

This document records decisions already made so the project does not repeatedly reopen settled questions without new evidence.

## 1. Thrawn is a command-tree framework

Thrawn is not merely a flag parser.

Its central abstraction is a tree of commands:

```text
app
├── alpha
│   ├── one
│   └── two
└── beta
```

The framework resolves a path through that tree and invokes the selected handler.

## 2. Command composition is primarily source-code composition

A command branch may be split across ordinary Zig files for organization.

Example:

```text
commands/
└── nutz/
    ├── root.zig
    ├── add.zig
    ├── remove.zig
    └── list.zig
```

These files are normally part of one application repository and one compiled binary.

Thrawn does not assume that every command or leaf is a separate Git repository, package, or runtime plugin.

## 3. Applications own command meaning

Thrawn understands that `add` is a command and how its arguments/options are structured.

It does not understand what `dz nutz add` means to Deez.

The division is:

```text
Thrawn:
  command declaration
  command resolution
  arguments/options
  validation
  help
  completion
  execution mechanics

Application:
  package installation
  database access
  network calls
  daemon IPC
  domain rules
```

## 4. Static declarations are preferred

The primary model is a command tree constructed from Zig declarations known at compile time.

This keeps the tree explicit, easy to inspect, straightforward to validate, and friendly to Zig's strengths.

Runtime plugin discovery is not a 1.0 goal.

## 5. Command and Context are separate concepts

`Command` describes static metadata.

`Context` describes one invocation.

Mutable execution state should not be stored inside globally declared command values.

## 6. Thrawn supports normal options

Bonzai's tree-first philosophy is useful, but Thrawn will not prohibit conventional flags/options.

Both of these are valid design tools:

```text
app profile use work
app deploy --dry-run
```

The framework should encourage understandable command trees while supporting normal Unix CLI expectations.

## 7. Persistence is outside Thrawn

Thrawn will not copy Bonzai's persistent-variable system into its core.

Configuration files, databases, saved user state, environment profiles, and daemon state belong to consuming applications or dedicated libraries.

This keeps Thrawn focused and prevents CLI parsing from becoming an application framework.

## 8. Help is generated from declarations

Command metadata should be the source of truth for generated help and usage.

Applications should not have to maintain a second independent help definition that can drift from actual parsing behavior.

## 9. Completion uses the same tree

Runtime resolution and shell completion must derive from the same command declarations.

Shell adapters may differ, but they should not independently redefine the command structure.

## 10. stdout and stderr are first-class

Normal results go to stdout. Diagnostics and usage errors go to stderr.

Writers must be injectable so behavior can be tested exactly.

Direct debug printing is acceptable only during the earliest prototype and is not the target public design.

## 11. Invalid trees should fail early

A command tree containing ambiguous names, aliases, or options is a developer error.

Thrawn should validate declarations and surface these problems before normal command execution rather than choose an arbitrary match.

## 12. Internal file count is not a goal

The target 1.0 layout contains multiple modules because the finished framework has multiple responsibilities.

However, the project begins small. We do not create empty abstractions solely to make the repository resemble a mature framework.

Files are split when the implementation earns the separation.

## 13. Phase 2 is the complete core; Phase 3 completes the product experience

After Phase 2, Thrawn should be capable of building serious production CLIs with commands, arguments, options, validation, help, errors, and suggestions.

Phase 3 adds shell completion and stabilizes the public experience for 1.0.

## 14. Release development flows through `dev`

The project branch model is fixed as:

```text
feature/* → dev → main → version tag
```

`main` is not the day-to-day integration branch.

Release tags are cut from `main` only after the corresponding `dev` release promotion has merged.

## 15. Deez is an important consumer, not part of Thrawn

Deez can be used to pressure-test Thrawn's API because it needs a serious nested CLI.

However, Thrawn should remain useful to unrelated Zig CLI applications. A Deez-specific need becomes a Thrawn feature only when it exposes a genuinely reusable CLI abstraction.
