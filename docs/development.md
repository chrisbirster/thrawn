# Development Workflow

## Branch model

Thrawn uses a simple promotion model:

```text
feature/*
    ↓ pull request
   dev
    ↓ release pull request
  main
    ↓
 vX.Y.Z
```

### `main`

`main` represents released or release-ready code.

Rules:

- do not develop directly on `main`
- normal feature work does not target `main`
- `main` receives release promotions from `dev`
- release tags are cut from `main`

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
3. update the package version where appropriate
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

After the release PR is merged into `main`:

```sh
git checkout main
git pull origin main

git tag -a v0.1.0 -m "Thrawn v0.1.0"
git push origin v0.1.0
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

## Syncing after release

If the release changes `main` in a way not already present in `dev`—for example a release-only changelog/version commit—merge `main` back into `dev` before starting the next feature cycle.

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
