# rclone Filtering Reference

## Table of Contents

- [Pattern Syntax](#pattern-syntax)
- [Filter Flags](#filter-flags)
- [Size and Age Filters](#size-and-age-filters)
- [Files-From](#files-from)
- [Common Pitfalls](#common-pitfalls)

## Pattern Syntax

Rclone uses glob-style matching:

```
*         matches any non-separator characters
**        matches anything including / separators
?         matches any single non-separator character
[abc]     character class
[a-z]     character range
{a,b,c}   pattern alternatives (no spaces)
{{regex}}  inline regular expression
\c        escape a special character
```

### Path anchoring

- `/pattern` — matches only at the root of the remote
- `pattern` — matches at the end of any path (from a `/` boundary)

```
file.jpg    matches "file.jpg" and "dir/file.jpg", NOT "afile.jpg"
/file.jpg   matches only "file.jpg" at root, NOT "dir/file.jpg"
```

### Pattern examples

| Pattern | Matches | Does not match |
|---------|---------|----------------|
| `*.jpg` | `file.jpg`, `dir/file.jpg` | `file.png` |
| `/*.jpg` | `/file.jpg` | `/dir/file.jpg` |
| `*.{jpg,png}` | `file.jpg`, `file.png` | `file.gif` |
| `dir/**` | `dir/anyfile`, `dir/sub/file` | `other/file` |
| `*.t?t` | `file.txt`, `file.tzt` | `file.png` |

### Regular expressions

Wrap in `{{ }}`. Uses Go/re2 syntax.

```
*.{{jpe?g}}       matches file.jpg, file.jpeg
/{{.*\.jpe?g}}    matches .jpg/.jpeg at root only
*.{{(?i)jpg}}     case-insensitive match
```

Patterns are case-sensitive by default. Use `--ignore-case` for case-insensitive matching.

## Filter Flags

**Important**: Avoid mixing `--include`, `--exclude`, and `--filter` in one command. Use `--filter-from` for complex rules.

### --exclude / --exclude-from

Exclude files matching a pattern.

```bash
rclone ls remote: --exclude "*.bak"
rclone ls remote: --exclude "/dir/**"
rclone ls remote: --exclude-from exclude-list.txt
```

### --include / --include-from

Include only files matching a pattern. Implies `--exclude **` for everything else.

```bash
rclone ls remote: --include "*.{png,jpg}"
rclone copy /vol1 remote: --include "{dirA,dirB}/**"
rclone ls remote: --include-from include-list.txt
```

### --filter / --filter-from

Most flexible. Rules prefixed with `+` (include) or `-` (exclude). Processed in order.

```bash
rclone ls remote: --filter "- *.bak"
rclone ls remote: --filter-from filter-rules.txt
```

Example `filter-rules.txt`:
```
# Comments start with #
- secret*.jpg
+ *.jpg
+ *.png
- /dir/Trash/**
+ /dir/**
- *
```

Rules are first-match-wins. The final `- *` excludes everything not previously matched.

`!` on its own line clears all prior rules.

### Directory filters

End patterns with `/` to filter directories:
```
- /dir1/
```

This optimizes by skipping directory traversal entirely.

## Size and Age Filters

```bash
--min-size 50k       # skip files smaller than 50 KiB
--max-size 1G        # skip files larger than 1 GiB
--min-age 2d         # skip files newer than 2 days
--max-age 24h        # skip files older than 24 hours
--max-age 2024-01-01 # skip files older than this date
```

Size units: `B`, `K` (KiB), `M`, `G`, `T`, `P`
Age formats: `1d2h3m`, `24h`, `2024-01-15`

## Files-From

Override all other filters. Process only the listed files.

```bash
rclone copy --files-from file-list.txt source: dest:
```

Combine with `--no-traverse` for efficiency on short lists (1 API call per file instead of full listing).

`--files-from-raw` is the same but doesn't strip whitespace or skip `#`/`;` lines.

## Common Pitfalls

1. Use paths relative to the remote root
2. Use `/` to anchor to the root of a remote
3. Use `**` to match directory contents recursively
4. Always use `/` (not `\`) in patterns, even on Windows
5. `rclone purge` does NOT obey filters
6. Test filters safely: `rclone ls remote: --dry-run -vv --dump filters`
