# Testing Strategy

Thrawn should be designed so its behavior is testable as ordinary Zig functions, not primarily through subprocess tests.

## Principles

1. **Resolution is pure where practical.** Given a command tree and tokens, tests should be able to inspect the selected command, path, and remaining input directly.
2. **Output is injected.** Help, diagnostics, and command output should write to testable writers instead of calling global debug-print helpers.
3. **Developer errors and user errors are distinct.** Invalid command declarations should be covered separately from invalid CLI input.
4. **Every parsing ambiguity gets a test.** If two interpretations are possible, the intended rule must be explicit in tests.
5. **Public behavior matters more than internal implementation.** Refactors should not require rewriting the whole test suite if observable behavior is unchanged.

## Test layers

### Command resolution

Cover:

- direct child resolution
- deeply nested resolution
- aliases
- unknown root child
- unknown nested child
- branch selected without a leaf
- executable command with children
- default child behavior
- remaining positional tokens
- help tokens at supported positions

Target file:

```text
tests/resolve_test.zig
```

### Arguments

Cover:

- required positional arguments
- optional positional arguments
- too few values
- too many values
- repeated/trailing values
- usage representation

Argument validation should happen before the handler is invoked.

### Options

Cover:

- long boolean options
- short boolean options
- long options with values
- short options with values
- missing values
- duplicate options
- repeated options when allowed
- unknown options
- option/positional ordering rules
- `--` end-of-options behavior if supported

Target file:

```text
tests/options_test.zig
```

### Help

Help tests should compare generated text against exact expected output for representative trees.

Cover:

- root help
- branch help
- leaf help
- full nested path in usage
- positionals
- options
- aliases where intentionally displayed
- hidden commands excluded from normal help
- deprecation notices

Target file:

```text
tests/help_test.zig
```

### Tree validation

Cover developer mistakes including:

- empty command names
- duplicate sibling names
- duplicate aliases
- name/alias collisions
- invalid default child
- duplicate long options
- duplicate short options
- malformed positional declarations

Target file:

```text
tests/validation_test.zig
```

### Suggestions

Cover:

- obvious single-character typo
- transposed characters
- no suggestion when candidates are not close enough
- nested command suggestions limited to the relevant parent
- hidden commands not suggested

### Completion

The completion engine should be tested separately from shell-specific script rendering.

Cover:

- root command candidates
- nested command candidates
- options
- hidden filtering
- prefix filtering
- positional custom completion callback
- command path awareness

Target file:

```text
tests/completion_test.zig
```

Then add smaller adapter tests for Bash, Zsh, and Fish generation.

## Error and exit behavior

Tests should verify both the message destination and the logical exit result.

Examples:

```text
success                       → stdout, exit 0
unknown command               → stderr, usage error
invalid argument count        → stderr, usage error
unknown option                → stderr, usage error
handler/application failure   → stderr as application chooses, nonzero
```

The exact public API for returning an exit status can evolve before 1.0, but the behavior must remain explicit and covered.

## No subprocess requirement for core tests

Core tests should be able to call APIs like:

```zig
const result = try th.resolve(&root, args);
```

or execute against in-memory writers.

Subprocess/integration tests may exist for final executable behavior, but they should supplement rather than replace direct unit tests.

## Release gate

Before merging `dev` into `main`, the release branch state must pass at least:

```sh
zig fmt --check .
zig build
zig build test
```

If the exact Zig formatter command differs for the targeted Zig version, CI should use the supported equivalent.

By 1.0, CI should test all supported platforms/targets that Thrawn claims to support.
