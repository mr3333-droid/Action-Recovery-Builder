#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_ROOT:?SOURCE_ROOT is required}"
DEST="$SOURCE_ROOT/$DEVICE_PATH"
AUTH_URL="$DEVICE_TREE_URL"
DISPLAY_URL="${DEVICE_TREE_URL%.git}"

if [[ -n "${DT_TOKEN:-}" ]]; then
  echo "::add-mask::$DT_TOKEN"
  TOKEN_ENCODED="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$DT_TOKEN")"
  case "$DEVICE_TREE_URL" in
    https://github.com/*)
      AUTH_URL="${DEVICE_TREE_URL/https:\/\/github.com\//https:\/\/x-access-token:${TOKEN_ENCODED}@github.com\/}"
      ;;
    https://gitlab.com/*)
      AUTH_URL="${DEVICE_TREE_URL/https:\/\/gitlab.com\//https:\/\/oauth2:${TOKEN_ENCODED}@gitlab.com\/}"
      ;;
  esac
fi

if ! git ls-remote --exit-code "$AUTH_URL" "refs/heads/$DEVICE_TREE_BRANCH" >/dev/null 2>&1; then
  echo "::error::Cannot access branch '$DEVICE_TREE_BRANCH' in the device tree repository."
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
git clone --depth=1 --single-branch --branch "$DEVICE_TREE_BRANCH" "$AUTH_URL" "$DEST"

cd "$DEST"
git remote set-url origin "$DEVICE_TREE_URL"
LATEST_COMMIT="$(git rev-parse --short=7 HEAD)"
LATEST_COMMIT_FULL="$(git rev-parse HEAD)"

case "$DISPLAY_URL" in
  https://gitlab.com/*) COMMIT_URL="$DISPLAY_URL/-/commit/$LATEST_COMMIT_FULL" ;;
  *) COMMIT_URL="$DISPLAY_URL/commit/$LATEST_COMMIT_FULL" ;;
esac

{
  echo "LATEST_COMMIT=$LATEST_COMMIT"
  echo "LATEST_COMMIT_FULL=$LATEST_COMMIT_FULL"
  echo "COMMIT_URL=$COMMIT_URL"
} >> "$GITHUB_ENV"

{
  echo "latest_commit=$LATEST_COMMIT"
  echo "latest_commit_full=$LATEST_COMMIT_FULL"
  echo "commit_url=$COMMIT_URL"
} >> "$GITHUB_OUTPUT"

echo "Device tree: $DEVICE_TREE_BRANCH @ $LATEST_COMMIT"
