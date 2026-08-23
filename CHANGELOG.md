# Changelog

All notable changes to Thrawn are documented here.

The project follows Semantic Versioning.

## Unreleased

## 0.1.0 - 2026-08-23

### Added

- Composable nested command trees, aliases, defaults, hidden and deprecated commands.
- Positional argument metadata and validation.
- Full long/short option grammar including `--name=value`, attached short values, clusters, and `--`.
- Typed string, integer, float, and choice values.
- Required, default, and repeatable options.
- Option dependency, conflict, and exclusive-group constraints.
- Inherited global options and completion.
- Grouped generated help and full nested command paths.
- Inherited before/after execution hooks.
- Passthrough command mode for wrapped executables.
- Generated Markdown and man-page documentation.
- Bash, Zsh, and Fish completion generation.
- Dynamic application-defined completion callbacks.
- First-class CLI testing harness.
- Command-tree validation and typo suggestions.
- Explicit stdout/stderr execution context and conventional exit codes.
- Native CI verification on Linux, macOS ARM64, macOS x86_64, and Windows x86_64.
- External consumer-package verification in Debug and ReleaseSafe.
- Tag-gated release workflow with package-version validation.

### License

- Released under the MIT License.
