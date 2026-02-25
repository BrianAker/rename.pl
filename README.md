# rename

`rename` is a Perl-based filename renamer that applies Perl expressions (`s///`, `tr///`, `y///`) to files and directories, with safety guards to prevent common destructive mistakes.

## Features

- Perl rename expressions (`s///`, `tr///`, `y///`)
- Dry-run mode (`-n`) to preview changes
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
rename [options] 'expr' [files...]
```

If no `files` are provided, `rename` reads newline-separated paths from STDIN.

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
  - End option parsing (useful before globs or filenames starting with `-`).

## Examples

Dry-run rename:

```bash
rename -n 's/foo/bar/' -- *
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

## Test

Run test suite:

```bash
make test
```

Tests use `Test::More` and run via `prove`.

## License

BSD 2-Clause. See `LICENSE`.
