#!/bin/bash
set -euo pipefail

# Usage: ./scripts/release.sh [patch|minor|major] [--dry-run]
# Bumps version in package.json, syncs to version.json, commits, tags, and pushes.

BUMP="${1:-patch}"
DRY_RUN=false

for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then
    DRY_RUN=true
  fi
done

if [[ "$BUMP" != "patch" && "$BUMP" != "minor" && "$BUMP" != "major" ]]; then
  echo "Usage: $0 [patch|minor|major] [--dry-run]"
  exit 1
fi

# Ensure clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is not clean. Commit or stash changes first."
  exit 1
fi

# Bump version in package.json (no git tag — we do it ourselves)
cd electron
NEW_VERSION=$(npm version "$BUMP" --no-git-tag-version | tr -d 'v')
cd ..

# Sync version to docs/version.json
node -e "
  const fs = require('fs');
  const p = 'docs/version.json';
  const d = JSON.parse(fs.readFileSync(p, 'utf8'));
  d.version = '$NEW_VERSION';
  fs.writeFileSync(p, JSON.stringify(d, null, 2) + '\n');
"

if $DRY_RUN; then
  echo "Dry run: would release v${NEW_VERSION}"
  echo ""
  echo "Files changed:"
  git diff --stat
  echo ""
  echo "version.json:"
  cat docs/version.json
  echo ""
  echo "package.json version:"
  node -e "console.log(require('./electron/package.json').version)"
  echo ""
  # Undo the version bump
  git checkout -- electron/package.json electron/package-lock.json docs/version.json
  echo "Reverted all changes."
  exit 0
fi

# Commit, tag, push
git add electron/package.json electron/package-lock.json docs/version.json
git commit -m "release: v${NEW_VERSION}"
git tag "v${NEW_VERSION}"
git push && git push origin "v${NEW_VERSION}"

echo "Released v${NEW_VERSION}"
