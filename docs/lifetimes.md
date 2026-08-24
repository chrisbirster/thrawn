# Context Value Lifetimes

Thrawn keeps handler execution fast by exposing parsed command-line data as borrowed views.

## Borrowed values

The following values are borrowed for the duration of the current handler or hook invocation:

- `ctx.args`
- `ctx.options`
- `ctx.argument(index)`
- `ctx.optionValue(name)`
- `ctx.optionValueAt(name, index)`

Applications must not retain those slices or option values after the handler or hook returns.

This rule is deliberately stricter than any incidental implementation detail. Some argument bytes may originate in the process argv and some option/default values may have longer storage, but applications should rely only on the documented invocation lifetime.

## Retaining one argument

Use an application-owned allocator when a value must outlive the handler:

```zig
const name = try ctx.dupeArgument(app.arena.allocator(), 0) orelse
    return error.MissingArgument;

app.pending_name = name;
```

`dupeArgument` copies the bytes and returns memory owned by the supplied allocator.

## Retaining several arguments

Variadic command models commonly need to keep an outer slice as well as each string. Use `dupeArguments`:

```zig
app.fields = try ctx.dupeArguments(app.arena.allocator(), 2);
```

The returned value owns:

1. the outer `[][]u8` slice, and
2. every string allocation contained by that slice.

With a general-purpose allocator, free both layers:

```zig
const fields = try ctx.dupeArguments(allocator, 2);
defer {
    for (fields) |field| allocator.free(field);
    allocator.free(fields);
}
```

Arena allocators are convenient when the retained values share an application or request lifetime.

## Retaining option values

Use `dupeOptionValue` for the latest option occurrence:

```zig
app.config_path = try ctx.dupeOptionValue(app.arena.allocator(), "config");
```

For repeatable options, use `dupeOptionValueAt`:

```zig
const first_tag = try ctx.dupeOptionValueAt(app.arena.allocator(), "tag", 0);
```

Both APIs return `null` when the requested value is absent.

## Why Thrawn does not copy everything

Automatically copying every argument and option would make simple CLIs pay for allocations they do not need. Most handlers consume their input synchronously and can use the borrowed views directly.

Thrawn therefore uses an explicit rule:

```text
consume now  -> borrowed Context views
retain later -> duplicate into application-owned memory
```

This keeps the common path allocation-light while making ownership at application boundaries intentional and testable.
