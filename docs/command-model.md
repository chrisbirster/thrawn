# Command Model

## Mental model

A Thrawn application is a tree.

```text
root
├── branch
│   ├── leaf
│   └── leaf
└── leaf
```

Each command is a declaration. Thrawn walks declarations to determine which handler owns the remaining command-line input.

For example:

```text
dz nutz add node@26 --dry-run
```

Conceptually becomes:

```text
command path: dz → nutz → add
positionals:  node@26
options:      --dry-run
```

## Command declaration

The final public shape may evolve while Thrawn is pre-1.0, but the intended model is approximately:

```zig
pub const Command = struct {
    name: []const u8,
    aliases: []const []const u8 = &.{},

    summary: []const u8 = "",
    description: []const u8 = "",

    children: []const *const Command = &.{},
    default_child: ?*const Command = null,

    positionals: []const Positional = &.{},
    options: []const Option = &.{},

    hidden: bool = false,
    deprecated: ?[]const u8 = null,

    handler: ?Handler = null,
};
```

A command declaration is static metadata. It should not contain mutable per-execution state.

## Branch commands

A branch organizes child commands.

```zig
const nutz = th.Command{
    .name = "nutz",
    .summary = "Manage Nutz",
    .children = &.{
        &add,
        &remove,
        &list,
    },
};
```

This produces:

```text
nutz
├── add
├── remove
└── list
```

A branch without a handler normally shows help when selected directly.

## Leaf commands

A leaf performs work through a handler.

```zig
const add = th.Command{
    .name = "add",
    .summary = "Install a package",
    .handler = addPackage,
};
```

A leaf may still accept positional arguments and options.

## Commands may be both branch and executable

Thrawn should not artificially prevent a command from containing both children and a handler.

```text
foo
├── inspect
└── update
```

`foo` may have its own behavior when run without a child while still exposing `foo inspect` and `foo update`.

The resolution rules for this case must be deterministic and tested.

## Aliases

Aliases provide alternate spellings for the same command.

```zig
const version = th.Command{
    .name = "version",
    .aliases = &.{"v"},
};
```

Both resolve to the same declaration:

```text
demo version
demo v
```

Aliases participate in tree validation. A sibling name and alias must never resolve ambiguously.

## Default child

A branch may explicitly choose a child to run when no child token is provided.

Example:

```text
dz nutz
```

could intentionally behave as:

```text
dz nutz list
```

using:

```zig
.default_child = &list,
```

Default behavior must always be explicit. Thrawn should not guess a default child based on ordering.

## Positional arguments

Positionals represent ordered values owned by a command.

Example:

```text
dz nutz add node@26
```

`node@26` is a positional argument owned by `add`.

The target declaration style is approximately:

```zig
.positionals = &.{
    .{
        .name = "package",
        .required = true,
    },
},
```

Thrawn should eventually support:

- required values
- optional values
- repeated/trailing values
- useful usage rendering
- validation before the handler runs

Handlers should not have to reimplement basic argument-count checks.

## Options

Options are named values or switches.

Example:

```text
dz nutz add node@26 --dry-run
```

Target declaration:

```zig
.options = &.{
    .{
        .long = "dry-run",
        .short = 'n',
        .kind = .boolean,
        .summary = "Show changes without applying them",
    },
},
```

Thrawn should support at least:

- boolean switches
- string values
- short names
- long names
- required option values
- repeated options where explicitly allowed

Option parsing should be deterministic and should not silently accept malformed values.

## Context

Handlers receive a per-invocation context rather than mutating the static command declaration.

Approximate model:

```zig
pub const Context = struct {
    allocator: std.mem.Allocator,

    root: *const Command,
    command: *const Command,
    path: []const *const Command,

    args: ParsedArguments,
    options: ParsedOptions,

    stdout: *std.Io.Writer,
    stderr: *std.Io.Writer,
};
```

The exact Zig I/O types should follow the Zig version Thrawn targets, but the architectural distinction is fixed:

```text
Command = static declaration
Context = one execution
```

## Handler

A handler is application code invoked only after Thrawn has resolved and validated the input.

Conceptually:

```zig
pub const Handler = *const fn (*Context) anyerror!void;
```

Example:

```zig
fn addPackage(ctx: *th.Context) !void {
    const package = ctx.args.get("package");
    const dry_run = ctx.options.boolean("dry-run");

    // Application logic starts here.
}
```

Thrawn should not know what a package is or how it is installed.

## Resolution rules

For input:

```text
app alpha beta value
```

Thrawn should:

1. start at the root command
2. resolve `alpha` against direct children
3. resolve `beta` against `alpha`'s children
4. stop walking when the next token is not a child command or when parsing rules require it to belong to the selected command
5. parse the remaining input according to the selected command's positional/option declarations
6. validate
7. execute

Resolution must preserve enough information to report the exact path where failure occurred.

Example:

```text
error: unknown command "statsu" for "dz daemon"

did you mean "status"?
```

## Help behavior

These forms should all be supported by 1.0:

```text
app help
app help alpha
app help alpha beta
app alpha --help
app alpha beta --help
```

Help is generated from the command declarations rather than maintained separately.

## Completion behavior

The same tree should power shell completion.

For:

```text
dz nutz <TAB>
```

Thrawn can derive static candidates such as:

```text
add
remove
list
```

Applications may provide dynamic completion callbacks for values Thrawn cannot know statically, such as available package names.

## One repository, many source files

Splitting a branch into files is an organizational choice:

```text
commands/
└── nutz/
    ├── root.zig
    ├── add.zig
    ├── remove.zig
    └── list.zig
```

It does not imply four packages or four Git repositories.

The files compile together as one application. Thrawn's job is simply to connect their command declarations into one tree.
