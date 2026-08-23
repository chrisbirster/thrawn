# Development Workflow

## Branch model

Thrawn uses a simple promotion model:

```text
feature/*
    ↓ pull request
   dev
    ↓ release pull request
  main
    ↓ manual release workflow
 vX.Y.Z
```

### `main`

`main` represents released or release-ready code.

Rules:

- do not develop directly on `main`
- normal feature work does not target `main`
- `main` receives release promotions from `dev`
- releases are created only from `main`

### `dev`

`dev` is the integration branch for the next release.

Rules:

- feature branches start from current `dev`
- completed features merge back into `dev`
- `dev` may contain multiple completed features intended for the next release
- when the planned release is stable, `dev` is merged into `main` through a release PR

### `feature/*`

All implementation and documentation changes should normally happen on focused feature branches created from `dev`.

Examples:

```text
feature/command-tree-engine
feature/output-writers
feature/options
feature/completion-engine
feature/docs-foundation
```

A feature branch should solve one coherent problem and remain small enough to review.

## Starting a feature

```sh
git checkout dev
git pull origin dev
git checkout -b feature/command-tree-engine
```

Make changes and run the relevant checks:

```sh
zig fmt .
zig build
zig build test
```

Then:

```sh
git add .
git commit -m "feat: add command tree engine"
git push -u origin feature/command-tree-engine
```

Open a PR:

```text
feature/command-tree-engine → dev
```

## Commit conventions

Use short conventional prefixes where they help communicate intent:

```text
feat: add nested command resolution
fix: reject duplicate aliases
test: cover nested help paths
docs: define command model
refactor: separate resolution from execution
chore: update CI configuration
```

Commits should explain a meaningful change rather than every save operation.

## Feature PR requirements

Before merging into `dev`:

- implementation builds
- tests pass
- new behavior has tests
- public API changes are documented
- architecture docs are updated if responsibilities changed
- unrelated changes are removed from the branch

## Preparing a release

When `dev` contains the desired release scope:

1. confirm the full test suite passes
2. update `CHANGELOG.md`
3. update `build.zig.zon` to the exact release version
4. verify examples/documentation against the release API
5. open a release PR:

```text
dev → main
```

The release PR should summarize:

- user-visible additions
- public API changes
- bug fixes
- breaking changes, if any
- known limitations

## Cutting a release

After the release PR is merged into `main`, use the GitHub Actions **release** workflow instead of creating a tag locally.

### GitHub website

1. open the repository
2. open **Actions**
3. choose **release**
4. choose **Run workflow**
5. enter the version, for example `0.1.0`
6. run the workflow

### GitHub Mobile

GitHub Mobile supports manually dispatching workflows that use `workflow_dispatch`.

1. open the Thrawn repository in GitHub Mobile
2. open **Actions**
3. choose **release**
4. choose **Run workflow**
5. enter the version
6. run the workflow

The workflow always releases the current `main` commit. It:

1. validates the requested version
2. verifies it exactly matches `build.zig.zon`
3. refuses to overwrite an existing tag
4. records the exact `main` commit SHA
5. runs ReleaseSafe builds and tests on Linux, macOS ARM64, macOS x86_64, and Windows x86_64
6. verifies the external consumer package on each platform
7. creates the `vX.Y.Z` tag only after every native job succeeds
8. creates the GitHub Release and generated release notes

The version input may be entered with or without the `v` prefix:

```text
0.1.0
v0.1.0
0.2.0-rc.1
```

Tags use semantic versioning:

```text
vMAJOR.MINOR.PATCH
```

Examples:

```text
v0.1.0
v0.5.0
v0.9.0
v1.0.0
v1.0.1
```

Prerelease versions such as `0.2.0-rc.1` are automatically published as GitHub prereleases.

## Why releases are manual

Promotion to `main` and publication are intentionally separate actions. Merging `dev` into `main` makes a commit release-ready, but it does not publish anything by itself.

This gives the maintainer a final explicit release button that can be used from GitHub without requiring a local Git checkout or Git tag command.

## Syncing after release

If the release changes `main` in a way not already present in `dev`, merge `main` back into `dev` before starting the next feature cycle.

```sh
git checkout dev
git pull origin dev
git merge main
git push origin dev
```

The branches should not intentionally drift.

## Documentation rule

Architecture documentation records current intent, but code and tests remain authoritative for released behavior.

When a feature changes a settled architectural decision, update the relevant document in the same feature PR.

## Scope discipline

Thrawn should resist absorbing application concerns simply because a consuming project needs them.

Before adding a framework feature, ask:

1. Is this generally useful to unrelated CLI applications?
2. Does it concern command declaration, parsing, resolution, validation, help, execution, or completion?
3. Can the application implement it cleanly without framework support?

If a feature is specific to Deez or another application, it belongs in that application unless there is a clear reusable CLI abstraction.
