# detangle for GitHub Actions

Checks import cycles and architecture rules in JavaScript and TypeScript projects with [detangle](https://github.com/debug-diary-1/detangle), and puts each violation on the pull request as an annotation on the line of the import that causes it. A Markdown report goes to the job summary.

detangle checks VS Code's source (10,000 modules, 113,000 imports) in about 0.2 s, so the step adds next to nothing to a CI run. The action downloads a release binary and verifies its checksum; it doesn't need Node.js.

```yaml
on: pull_request

jobs:
  dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: debug-diary-1/detangle-action@v1
```

With no `detangle.toml`, detangle checks its default rules: import cycles, imports that don't resolve, npm packages imported without being declared, and orphaned files. Your own rules (which folders may import which, per-package boundaries, Nx tags) go in `detangle.toml`; see the [reference](https://github.com/debug-diary-1/detangle/blob/main/docs/reference.md). To convert an existing setup (JavaScript rules configs, ESLint import rules, Nx module boundaries, madge), run `npx detangle migrate` once.

The step fails when detangle finds errors (or warnings too, with `--strict`).

## Inputs

| Input | Default | |
| --- | --- | --- |
| `path` | `.` | The project to check: the directory with its `detangle.toml` or `package.json`. |
| `version` | `latest` | The detangle version to install, such as `0.2.2`. |
| `args` | | More arguments for `detangle check`, split on spaces. |
| `summary` | `true` | Write a Markdown report to the job summary. |

The output `version` is the version that was installed.

## Examples

An existing codebase, failing only on new violations (record the baseline once with `npx detangle check --write-baseline` and commit it):

```yaml
      - uses: debug-diary-1/detangle-action@v1
        with:
          args: --baseline .detangle-baseline.json
```

One package of a monorepo, warnings included, at a pinned version:

```yaml
      - uses: debug-diary-1/detangle-action@v1
        with:
          path: packages/web
          version: 0.2.2
          args: --strict
```

Annotations point at files relative to the repository, also when `path` is a subdirectory.

## Platforms

Linux (x64, arm64), macOS (arm64, x64) and Windows (x64, arm64) runners. On Linux the static musl build is used, so it also works in Alpine containers.

## License

MIT or Apache-2.0, at your option.
