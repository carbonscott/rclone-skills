# Google Drive Options Reference

## Table of Contents

- [Standard Options](#standard-options)
- [Advanced Options](#advanced-options)
- [Backend Commands](#backend-commands)

## Standard Options

### --drive-client-id / --drive-client-secret

Custom OAuth client ID/secret. Leave blank to use rclone's built-in (shared, lower performance).
Creating your own is recommended for heavy use — see "Making your own client_id" in rclone docs.

### --drive-scope

Comma-separated list of scopes. Examples:

| Scope | Access |
|-------|--------|
| `drive` | Full access all files (default) |
| `drive.readonly` | Read-only access to files and metadata |
| `drive.file` | Only files created by rclone (visible in web UI) |
| `drive.appfolder` | Private app folder (not visible in web UI) |
| `drive.metadata.readonly` | Read-only metadata, no file content access |

Multiple scopes: `drive.readonly,drive.file`

### --drive-service-account-file

Path to service account JSON credentials. For unattended/server use.
Leading `~` and env vars like `${RCLONE_CONFIG_DIR}` are expanded.

## Advanced Options

### --drive-team-drive

ID of the Shared Drive (Team Drive). Set during config or via `--drive-team-drive=ID`.

### --drive-root-folder-id

Restrict rclone to a specific folder. Use the folder ID from the Google Drive URL:
`https://drive.google.com/drive/folders/FOLDER_ID` → use `FOLDER_ID`.

Note: Folders under "Computers" tab are read-only (500 error).

### --drive-shared-with-me

Operate on "Shared with me" folder. Works with list and copy/sync/move commands.

### --drive-trashed-only

Only show trashed files in their original directory structure.

### --drive-starred-only

Only show starred files.

### --drive-auth-owner-only

Only consider files owned by the authenticated user.

### --drive-use-trash

Send files to trash instead of permanent delete (default: `true`).
Use `--drive-use-trash=false` for permanent deletion.

### --drive-skip-gdocs

Skip Google Docs/Sheets/Slides in all listings (they become invisible).

### --drive-skip-shortcuts

Ignore shortcut files completely. Useful to avoid infinite recursion from shortcuts pointing to parent folders.

### --drive-copy-shortcut-content

When server-side copying, copy the contents of shortcuts rather than the shortcut itself.

### --drive-export-formats

Preferred formats for downloading Google Docs. Default: `docx,xlsx,pptx,svg`.
Alternatives: `pdf`, `ods,odt,odp` (LibreOffice).

### --drive-import-formats

Formats to convert when uploading to Google Docs. Default: none (no conversion).

### --drive-impersonate

Impersonate a user when using a service account (Workspace admin feature).
Example: `--drive-impersonate user@example.com`

### --drive-upload-cutoff

Cutoff for switching to chunked upload. Default: `8Mi`.

### --drive-chunk-size

Upload chunk size (must be power of 2 >= 256k). Default: `8Mi`.
Larger = faster but more memory per transfer.

### --drive-acknowledge-abuse

Allow downloading files flagged as malware/spam by Google.

### --drive-stop-on-upload-limit

Make the 750 GiB/day upload limit error fatal (stops sync). Default: `false`.

### --drive-stop-on-download-limit

Make the 10 TiB/day download limit error fatal. Default: `false`.

### --drive-use-created-date

Use file creation date instead of modification date. Useful for Google Photos.

### --drive-list-chunk

Size of listing chunk (100-1000). Default: `1000`.

### --drive-pacer-min-sleep

Minimum time between API calls. Default: `100ms`.

### --drive-pacer-burst

Number of API calls allowed without sleeping. Default: `100`.

### --drive-resource-key

Resource key for accessing link-shared files. Extract from URL:
`https://drive.google.com/.../XXX?resourcekey=YYY` → `root_folder_id=XXX`, `resource_key=YYY`.

### --drive-disable-http2

Disable HTTP/2 for Drive (default: `true` — HTTP/2 disabled due to unresolved issue #3631).

## Backend Commands

Run with: `rclone backend COMMAND remote:`

| Command | Description | Example |
|---------|-------------|---------|
| `drives` | List available Shared Drives | `rclone backend drives remote:` |
| `drives -o config` | Output Shared Drives as config aliases | `rclone backend -o config drives remote:` |
| `get` | Get config parameters | `rclone backend get remote: -o chunk_size` |
| `set` | Update config parameters | `rclone backend set remote: -o chunk_size=67108864` |
| `shortcut` | Create Drive shortcuts | `rclone backend shortcut remote: source dest` |
| `untrash` | Restore trashed files recursively | `rclone backend untrash remote:directory` |
| `copyid` | Copy files by Google Drive file ID | `rclone backend copyid remote: FILE_ID path/` |
| `moveid` | Move files by Google Drive file ID | `rclone backend moveid remote: FILE_ID path/` |
| `query` | Search using Google Drive query language | `rclone backend query remote: "name contains 'report'"` |
| `rescue` | List/rescue/delete orphaned files | `rclone backend rescue remote: Orphans` |
| `exportformats` | Dump available export formats | `rclone backend exportformats remote:` |
| `importformats` | Dump available import formats | `rclone backend importformats remote:` |

### Query syntax

Uses [Google Drive Search query terms](https://developers.google.com/drive/api/guides/ref-search-terms).

```bash
# Files containing "report" in a specific folder
rclone backend query remote: "'FOLDER_ID' in parents and name contains 'report'"

# Files modified after a date
rclone backend query remote: "modifiedTime > '2024-01-01'"
```

Escape `'` as `\'` and `\` as `\\\` within query strings.
