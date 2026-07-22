# rename

`rename` is a Perl-based filename renamer that applies Perl expressions (`s///`, `tr///`, `y///`) to files and directories, with safety guards to prevent common destructive mistakes.

## Features

- Perl rename expressions (`s///`, `tr///`, `y///`)
- Multiple expression arguments, applied left to right
- Dry-run mode (`-n`) to preview changes
- Commit-time version bumping via a tracked pre-commit hook
- Recursive processing (`--recursive`) for directory trees
- Safety checks for:
  - extension changes
  - hidden names (leading `.`)
  - leading dash names (leading `-`)
  - destination collisions
  - suspicious capture/replacement mismatches
  - dangerous `s/./.../g` patterns
- STDIN input support when no path arguments are provided

## Usage

```bash
rename [options] 'expr' ['expr' ...] [files...]
```

If no `files` are provided, `rename` reads newline-separated paths from STDIN.
When `--` is present, everything before it is parsed as CLI options or expression tokens, and everything after it is treated as file arguments.

### Options

- `-n`
  - Dry run. Print planned renames without modifying the filesystem.
- `--recursive`
  - Recursively process each provided directory argument.
  - Renames deeper paths before parent directories.
  - Applies expression to each path component basename, so parent path context is preserved.
- `--type f|d`
  - Exclude paths of the given type from renaming.
  - `f` ignores regular files.
  - `d` ignores directories.
- `--allow-hidden`
  - Allow output names that begin with `.`.
- `--allow-dash`
  - Allow output names that begin with `-`.
- `--allow-ext`
  - Allow extension changes.
- `--preserve-ext`
  - Keep original extension when a rename would change it.
  - Mutually exclusive with `--allow-ext`.
- `--`
  - End option and expression parsing.
  - Everything after `--` is treated as a file argument.
- `__underscore`
  - Built-in expression alias for `s/_/ /g`.

## Examples

Dry-run rename:

```bash
rename -n 's/foo/bar/' -- *
```

Apply multiple expressions in order:

```bash
rename -n 's/foo/baz/' 's/ /_/' -- "foo bar.txt"
```

Use the built-in underscore alias:

```bash
rename -n __underscore -- foo_bar.txt
```

Remove ` (Unabridged)` from files:

```bash
rename -n 's/ \(Unabridged\)//' -- *
```

Recursive rename (directories and nested files):

```bash
rename --recursive 's/ \(Unabridged\)//' -- "The Dog of Foo (Unabridged)"
```

Recursive rename but only files (skip directories):

```bash
rename --recursive --type d 's/ \(Unabridged\)//' -- "The Dog of Foo (Unabridged)"
```

Recursive rename but only directories (skip files):

```bash
rename --recursive --type f 's/ \(Unabridged\)//' -- "The Dog of Foo (Unabridged)"
```

Allow extension changes:

```bash
rename --allow-ext 's/\.mp4$/.mkv/' -- *.mp4
```

Preserve original extension:

```bash
rename --preserve-ext 's/episode/show/' -- episode.mp4
```

Read paths from STDIN:

```bash
find . -type f -name '*.txt' | rename -n 's/ /_/g'
```

## Install

Install to `/usr/local/bin` (default):

```bash
make install
```

Install using a custom prefix:

```bash
make install PREFIX=/opt/tools
```

Install using an explicit bin directory:

```bash
make install BINDIR=/custom/bin
```

Enable the repo's tracked git hook:

```bash
make install-hooks
```

This configures `core.hooksPath` to use `.githooks/`.

## Test

Run test suite:

```bash
make test
```

Tests use `Test::More` and run via `prove`.

## Versioning

The repo keeps the current version in [VERSION](/Users/brian/Documents/rename.pl/VERSION) using:

```text
YYYY.MM.DD-major.minor
```

Example:

```text
2026.07.16-1.7
```

Rules:

- The `major` number is managed by hand.
- The `minor` number is incremented automatically by the pre-commit hook.
- The date portion is rewritten to the current local date on each bump.

The hook runs [script/update-version](/Users/brian/Documents/rename.pl/script/update-version), which:

- Reads the current version from `VERSION`
- Increments the minor number
- Rewrites `VERSION`
- Updates every file listed in [.version-files](/Users/brian/Documents/rename.pl/.version-files)
- Stages the updated files so the commit includes the new version

To sync app manifests later, add their repo-relative paths to `.version-files`. Any listed file other than `VERSION` will have existing version strings in this format replaced with the new value.

## License

BSD 2-Clause. See `LICENSE`.
