# Shared Drives (Team Drives) Reference

## Table of Contents

- [Listing Shared Drives](#listing-shared-drives)
- [Configuring Access](#configuring-access)
- [Accessing Specific Shared Drives](#accessing-specific-shared-drives)
- [Multi-Drive Setup](#multi-drive-setup)
- [Backend Commands](#backend-commands)
- [Service Accounts](#service-accounts)

## Listing Shared Drives

List all Shared Drives available to your account:

```bash
rclone backend drives remote:
```

Returns JSON with drive IDs and names:
```json
[
    {"id": "0ABCDEF-01234567890", "kind": "drive#drive", "name": "My Team Drive"},
    {"id": "0ABCDEFabcdefghijkl", "kind": "drive#drive", "name": "Another Drive"}
]
```

## Configuring Access

### During initial setup

Answer `y` to "Configure this as a Shared Drive?" during `rclone config`. Select or enter the drive ID.

### Non-interactive config for a shared drive

```bash
rclone config create myteam drive scope drive team_drive DRIVE_ID
```

### Access a specific shared drive on-the-fly

Use connection string syntax (no config change needed):

```bash
rclone ls remote,team_drive=DRIVE_ID:
rclone ls remote,team_drive=DRIVE_ID:path/to/folder
```

## Accessing Specific Shared Drives

Once configured with a `team_drive` ID, the remote root points to that Shared Drive:

```bash
rclone lsd myteam:           # list top-level folders
rclone ls myteam:Projects/   # list files in Projects folder
rclone copy myteam:Reports/ ./local-reports/
```

## Multi-Drive Setup

### Auto-generate aliases for all Shared Drives

```bash
rclone backend -o config drives remote:
```

This outputs config entries you can append to `~/.config/rclone/rclone.conf`:

```ini
[My Team Drive]
type = alias
remote = remote,team_drive=0ABCDEF-01234567890,root_folder_id=:

[Another Drive]
type = alias
remote = remote,team_drive=0ABCDEFabcdefghijkl,root_folder_id=:

[AllDrives]
type = combine
upstreams = "My Team Drive=My Team Drive:" "Another Drive=Another Drive:"
```

This creates:
- Individual aliases for each Shared Drive
- A combined `AllDrives` remote showing all drives in one directory tree

Illegal characters in drive names are replaced with `_`, duplicates get number suffixes.

### Manual alias setup

```ini
[specific-team]
type = alias
remote = gdrive-work,team_drive=DRIVE_ID,root_folder_id=:
```

## Backend Commands

### untrash — Restore deleted files

```bash
rclone backend untrash remote:directory           # restore all in directory
rclone backend --interactive untrash remote:dir    # preview first
rclone backend --dry-run untrash remote:dir        # dry run
```

### copyid — Copy by file ID

```bash
rclone backend copyid remote: FILE_ID local/path/
rclone backend copyid remote: ID1 path1/ ID2 path2/   # multiple files
```

Path ending with `/` copies the file with its original name into that directory.

### moveid — Move by file ID

```bash
rclone backend moveid remote: FILE_ID destination/path/
```

### shortcut — Create Drive shortcuts

```bash
rclone backend shortcut remote: source_item destination_shortcut
rclone backend shortcut remote: source -o target=other-remote: destination
```

### rescue — Handle orphaned files

```bash
rclone backend rescue remote:                    # list orphans
rclone backend rescue remote: Orphans            # rescue to Orphans/ directory
rclone backend rescue remote: -o delete          # delete orphans to trash
```

### query — Google Drive search

```bash
rclone backend query remote: "name contains 'budget'"
rclone backend query remote: "'FOLDER_ID' in parents and name contains 'report'"
rclone backend query remote: "modifiedTime > '2024-01-01'"
rclone backend query remote: "mimeType = 'application/pdf'"
```

See [Google Drive search syntax](https://developers.google.com/drive/api/guides/ref-search-terms).

## Service Accounts

For unattended access to Shared Drives (build machines, automation):

1. Create a service account in Google Cloud Console
2. Download the JSON credentials
3. In Workspace Admin Console, grant domain-wide delegation with scope `https://www.googleapis.com/auth/drive`
4. Configure rclone:

```bash
rclone config create sa-drive drive \
  scope drive \
  service_account_file /path/to/sa-credentials.json \
  team_drive DRIVE_ID
```

Use `--drive-impersonate user@domain.com` to act as a specific user (requires Workspace admin setup).
