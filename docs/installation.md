# Installation and dependency setup

Thrawn is a Zig library. Applications depend on it through the Zig package manager and import the module as `thrawn`.

## Released version

After a release tag exists, add a specific version to an application:

```sh
zig fetch --save git+https://github.com/chrisbirster/thrawn#v0.1.0
```

Pinning a release tag keeps builds reproducible and avoids depending on the moving `dev` branch.

## Development version

To test the current repository before the first release:

```sh
zig fetch --save git+https://github.com/chrisbirster/thrawn
```

For local development, a path dependency can be used in `build.zig.zon` instead.

## Consumer build.zig

After `zig fetch --save`, expose Thrawn to an executable module:

```zig
const thrawn_dep = b.dependency("thrawn", .{
    .target = target,
    .optimize = optimize,
});

const exe = b.addExecutable(.{
    .name = "my-cli",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "thrawn", .module = thrawn_dep.module("thrawn") },
        },
    }),
});
```

Application code can then use:

```zig
const th = @import("thrawn");
```

The package exposes its version as `th.version`.

## Shell completion

Applications choose how to expose completion installation. A normal command can generate a script using:

```zig
const shell = th.completion.Shell.parse(shell_name) orelse return error.UnsupportedShell;
try th.completion.writeScript(ctx.stdout, shell, root_command.name);
```

This enables application commands such as:

```text
my-cli completion bash
my-cli completion zsh
my-cli completion fish
```

The generated scripts use Thrawn's internal completion protocol and the application's declared command tree.
