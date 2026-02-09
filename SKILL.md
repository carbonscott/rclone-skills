---
name: rclone-gdrive
description: Help with rclone operations for Google Drive — file listing, copying, syncing, moving, mounting, shared/team drives, and filtering. Use when the user mentions rclone, Google Drive file transfers, syncing to/from Drive, mounting Drive as a filesystem, managing shared drives, or needs to construct rclone commands for Google Drive operations.
---

# rclone Google Drive

## Core Commands

Paths use the format `REMOTE:path/to/folder`. Replace `REMOTE` with the configured remote name.

### Listing

```bash
rclone lsd REMOTE:                    # list directories at root
rclone ls REMOTE:                     # list all files recursively (with sizes)
rclone lsf REMOTE:path/              # machine-parseable listing
rclone lsf REMOTE: --format "pst"    # custom format: path, size, time
rclone lsjson REMOTE:path/           # JSON output with metadata
rclone size REMOTE:path/             # total size and file count
rclone about REMOTE:                 # quota usage info
```

### Searching (server-side, fast)

Use `backend query` to search Google Drive server-side — much faster than `lsf --recursive | grep` which lists all files client-side before filtering.

```bash
rclone backend query REMOTE: "name contains 'keyword'"                    # search by name
rclone backend query REMOTE: "modifiedTime > '2025-01-01'"               # by date
rclone backend query REMOTE: "name contains 'report' and mimeType contains 'presentation'"  # combined

# Search a shared drive
rclone backend query "REMOTE,team_drive=DRIVE_ID:" "name contains 'keyword'"
```

Returns JSON with file ID, name, size, dates, and webViewLink. See [Google Drive search syntax](https://developers.google.com/drive/api/guides/ref-search-terms) for all query operators.

For multiple searches on the same drive, either run multiple `backend query` calls or cache a full listing locally (`rclone lsf --recursive --fast-list > /tmp/listing.txt`) and grep that file.

### Copying and syncing

```bash
rclone copy source:path/ dest:path/         # copy files (does NOT delete at dest)
rclone copy source:path/ dest:path/ --dry-run  # preview what would be copied
rclone sync source:path/ dest:path/         # make dest identical to source (DELETES extras at dest)
rclone sync source:path/ dest:path/ --dry-run  # always preview sync first
rclone bisync source:path/ dest:path/       # two-way sync
```

### Moving and deleting

```bash
rclone move source:path/ dest:path/                # move files (deletes from source)
rclone move source:path/ dest:path/ --delete-empty-src-dirs  # also remove empty dirs
rclone delete REMOTE:path/                         # delete files (to trash by default)
rclone delete REMOTE:path/ --drive-use-trash=false  # permanent delete
rclone purge REMOTE:path/                          # delete directory and all contents
rclone cleanup REMOTE:                             # empty trash permanently
```

### Mounting

```bash
rclone mount REMOTE: ~/mountpoint --vfs-cache-mode full    # mount as filesystem
rclone mount REMOTE: ~/mountpoint --daemon                 # mount in background
# Unmount: fusermount -u ~/mountpoint (Linux) or umount ~/mountpoint (macOS)
```

Note: Google Docs appear as 0-byte files in mounts. They transfer correctly with copy/sync but may not download properly via mount.

### Maintenance

```bash
rclone dedupe REMOTE:path/     # fix duplicate files (Drive-specific issue)
rclone check source: dest:     # compare source and dest without transferring
```

## Shared Drives (Team Drives)

```bash
# List all available shared drives
rclone backend drives REMOTE:

# Access a specific shared drive on-the-fly (no config needed)
rclone ls REMOTE,team_drive=DRIVE_ID:

# Auto-generate config aliases for all shared drives
rclone backend -o config drives REMOTE:

# Create a dedicated remote for one shared drive
rclone config create myteam drive scope drive team_drive DRIVE_ID
```

For detailed shared drive setup, multi-drive aliases, backend commands (untrash, copyid, rescue, query), and service accounts, see [references/shared-drives.md](references/shared-drives.md).

## Key Flags

| Flag | Effect |
|------|--------|
| `--dry-run` | Preview without changes |
| `--fast-list` | Batch directory listings (up to 20x faster for large dirs) |
| `--no-traverse` | Skip listing dest; efficient with `--files-from` on short lists |
| `-v` / `-vv` | Verbose / very verbose logging |
| `--progress` / `-P` | Show real-time transfer progress |
| `--max-age 24h` | Only files modified in last 24 hours |
| `--min-size 1M` | Skip files smaller than 1 MiB |
| `--drive-use-trash=false` | Permanently delete instead of trashing |
| `--drive-shared-with-me` | Operate on "Shared with me" folder |
| `--checkers N` | Number of parallel checks (default 8) |
| `--transfers N` | Number of parallel transfers (default 4) |

For all `--drive-*` flags (scopes, export formats, chunk sizes, etc.), see [references/drive-options.md](references/drive-options.md).

For filtering syntax (`--include`, `--exclude`, `--filter-from`, etc.), see [references/filtering.md](references/filtering.md).

## Gotchas

- **Upload limit**: 750 GiB/day (undocumented Google limit). Use `--drive-stop-on-upload-limit` to make this error fatal instead of retrying.
- **Download limit**: 10 TiB/day.
- **Google Docs**: Appear as size -1 in listings, 0 in mounts. They sync correctly but may not download via mount. Export format controlled by `--drive-export-formats` (default: `docx,xlsx,pptx,svg`).
- **Duplicates**: Google Drive can create duplicate files. Use `rclone dedupe` to fix. If files keep re-copying, run dedupe first.
- **Shortcuts**: By default treated as the target file. Use `--drive-skip-shortcuts` to ignore them. Shortcuts pointing to parent folders can cause infinite recursion.
- **Trash**: Deletes go to trash by default. Use `--drive-use-trash=false` for permanent deletion. `rclone cleanup` empties trash (may take minutes to days on Google's side).
- **Searching**: Prefer `rclone backend query` for file search — it uses Google's server-side API and is dramatically faster than `rclone lsf --recursive | grep` which lists all files client-side before filtering. For multiple searches on the same drive, either use multiple `backend query` calls or cache a full listing locally.
- **Rate limiting**: Drive limits to ~2 files/sec for small files. Large files transfer at full speed. Use `--fast-list` for faster directory listings.
- **"Computers" tab**: Folders under this tab are read-only (500 error).
- **HTTP/2 disabled**: HTTP/2 is disabled by default for Drive due to an unresolved issue.
