#!/bin/bash
# End of run: package the records for the user (no network needed).
REPO="$(cd "$(dirname "$0")" && pwd)"; cd "$REPO" || exit 1
mkdir -p export
tar czf export/kaizo-run-files.tar.gz run notes CLAUDE.md
git bundle create export/kaizo-run.bundle --all >/dev/null 2>&1 && git bundle verify export/kaizo-run.bundle >/dev/null 2>&1 && echo "bundle ok"
ls -l export
