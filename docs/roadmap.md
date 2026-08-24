# Roadmap

Thrawn is past the initial framework-construction phase. The roadmap is now driven by real consumer usage, especially Deez, rather than by adding features speculatively.

## Current status

Implemented and validated across Linux, macOS ARM64, macOS x86_64, and Windows x86_64:

- composable nested command trees and aliases
- positional metadata and validation
- long/short options, clusters, attached values, and `--`
- typed option values, defaults, repeatable options, and constraints
- inherited global options
- generated help and shell completion
- hooks and passthrough commands
- generated Markdown/man documentation
- first-class CLI testing harness
- typed application state through `Context.state(T)`
- configurable help-token handling
- Debug and ReleaseSafe consumer-package verification

Deez is the first substantial external consumer and is used to identify framework ergonomics and correctness gaps.

## v0.3.0 — Context lifetime safety

In development:

- document `Context` argument and option views as borrowed for the current handler/hook invocation
- provide owned duplication helpers for arguments and option values
- cover retained-value behavior after parser teardown
- backfill Deez to use the owned API at application boundaries

The goal is to make ownership explicit without forcing allocations on handlers that consume values synchronously.

## After v0.3.0

Priorities should continue to come from consumer pressure. Likely work includes:

1. typed positional argument declarations and accessors
2. required-state ergonomics such as `requireState(T)` if repeated consumer code justifies it
3. more structured framework errors for applications that need custom terminal UX
4. parser fuzzing for option clusters, `--`, aliases, globals, nested commands, and variadic arguments
5. a second substantial external consumer so the API is not optimized only around Deez
6. public API audit and accidental-surface removal
7. migration/deprecation policy before API freeze

## Path to 1.0

Thrawn should reach `1.0.0` only after:

- multiple real applications use it without internal workarounds
- argument/option ownership rules are stable
- public command/context/options APIs have been reviewed for long-term naming and semantics
- parser fuzzing and the native Debug/ReleaseSafe matrix are consistently green
- installation, completion, generated-doc, and testing workflows are documented
- breaking changes have a documented migration path

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
