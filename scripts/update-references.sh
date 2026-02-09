#!/usr/bin/env bash
#
# update-references.sh — Helper for updating rclone-gdrive skill references
#
# Usage: ./scripts/update-references.sh <path-to-rclone-repo>
#    or: RCLONE_REPO_DIR=/path/to/rclone ./scripts/update-references.sh
#
# This script does NOT auto-regenerate the references (they are curated
# summaries, not raw copies). Instead it:
#   1. Validates the rclone repo exists with expected doc files
#   2. Shows the current vs new rclone version
#   3. Prints which source files map to which reference files
#   4. Shows a summary of what changed in the source docs
#
# After running this, update the references manually or ask Claude to
# re-extract from the source docs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REFS_DIR="$SKILL_DIR/references"

# Resolve rclone repo path
RCLONE_REPO_DIR="${1:-${RCLONE_REPO_DIR:-}}"

if [[ -z "$RCLONE_REPO_DIR" ]]; then
    echo "Usage: $0 <path-to-rclone-repo>"
    echo "   or: RCLONE_REPO_DIR=/path/to/rclone $0"
    exit 1
fi

if [[ ! -d "$RCLONE_REPO_DIR" ]]; then
    echo "Error: '$RCLONE_REPO_DIR' is not a directory"
    exit 1
fi

# Source files we depend on
DRIVE_DOC="$RCLONE_REPO_DIR/docs/content/drive.md"
FILTER_DOC="$RCLONE_REPO_DIR/docs/content/filtering.md"
VERSION_FILE="$RCLONE_REPO_DIR/VERSION"

# Validate source files exist
echo "=== Validating rclone repo at: $RCLONE_REPO_DIR ==="
echo ""

missing=0
for f in "$DRIVE_DOC" "$FILTER_DOC" "$VERSION_FILE"; do
    if [[ -f "$f" ]]; then
        echo "  OK  $(basename "$f")"
    else
        echo "  MISSING  $f"
        missing=1
    fi
done

if [[ $missing -eq 1 ]]; then
    echo ""
    echo "Error: Some source files are missing. Is this a valid rclone repo?"
    exit 1
fi

echo ""

# Show version info
NEW_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
CURRENT_VERSION=$(grep -m1 'rclone version:' "$REFS_DIR/drive-options.md" 2>/dev/null | sed 's/.*rclone version: //' | sed 's/ *-->//' || echo "unknown")

echo "=== Version ==="
echo "  Current references: $CURRENT_VERSION"
echo "  rclone repo:        $NEW_VERSION"
if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]]; then
    echo "  (same version — source may still have changed)"
fi
echo ""

# Source mapping
echo "=== Source Mapping ==="
echo ""
echo "  Reference File              Source"
echo "  ─────────────────────────── ──────────────────────────────────────────────────────"
echo "  references/drive-options.md ← docs/content/drive.md (Standard options, Advanced options, Backend commands)"
echo "  references/filtering.md     ← docs/content/filtering.md (entire file, condensed)"
echo "  references/shared-drives.md ← docs/content/drive.md (Shared drives, Backend commands)"
echo ""

# Show source file sizes and modification dates
echo "=== Source File Info ==="
echo ""
for f in "$DRIVE_DOC" "$FILTER_DOC"; do
    lines=$(wc -l < "$f" | tr -d ' ')
    mod=$(stat -f "%Sm" -t "%Y-%m-%d" "$f" 2>/dev/null || stat -c "%y" "$f" 2>/dev/null | cut -d' ' -f1)
    echo "  $(basename "$f"): $lines lines, last modified $mod"
done
echo ""

# If this is a git repo, show recent changes to the source docs
if [[ -d "$RCLONE_REPO_DIR/.git" ]]; then
    echo "=== Recent Changes to Source Docs (last 10 commits) ==="
    echo ""
    git -C "$RCLONE_REPO_DIR" log --oneline -10 -- docs/content/drive.md docs/content/filtering.md 2>/dev/null || echo "  (could not read git log)"
    echo ""
fi

echo "=== Next Steps ==="
echo ""
echo "  The reference files are curated summaries, not raw copies."
echo "  To update them:"
echo ""
echo "  1. Review the source changes above"
echo "  2. Update the reference files in $REFS_DIR/"
echo "     - Or ask Claude: 'Update the rclone-gdrive skill references from $RCLONE_REPO_DIR'"
echo "  3. Update the version comments in each reference file"
echo "  4. Re-package: package_skill.py $SKILL_DIR"
echo ""
