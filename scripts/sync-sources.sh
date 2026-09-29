#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$BUILD_WORKSPACE"
SYNC_LOG="${RUNNER_TEMP:-/tmp}/recovery-sync.log"
: > "$SYNC_LOG"

case "$BUILD_FLAVOR" in
  orangefox)
    SOURCE_ROOT="$BUILD_WORKSPACE/fox_${MANIFEST_BRANCH}"
    SYNC_HELPER="$BUILD_WORKSPACE/orangefox-sync"
    rm -rf "$SYNC_HELPER"

    git clone --depth=1 --single-branch "$MANIFEST_URL" "$SYNC_HELPER" 2>&1 | tee -a "$SYNC_LOG"

    # OrangeFox's sync helper resolves its patches relative to the current
    # directory. Run it from the cloned sync repository, as upstream documents.
    (
      cd "$SYNC_HELPER"
      ./orangefox_sync.sh --branch "$MANIFEST_BRANCH" --path "$SOURCE_ROOT"
    ) 2>&1 | tee -a "$SYNC_LOG"
    ;;
  twrp)
    SOURCE_ROOT="$BUILD_WORKSPACE/twrp_${MANIFEST_BRANCH#twrp-}"
    mkdir -p "$SOURCE_ROOT"
    (
      cd "$SOURCE_ROOT"
      repo init --depth=1 -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH"
      repo sync -c --no-clone-bundle --no-tags --force-sync -j"$(nproc --all)"
    ) 2>&1 | tee -a "$SYNC_LOG"
    ;;
  *)
    echo "::error::Unsupported build flavor: $BUILD_FLAVOR"
    exit 1
    ;;
esac

{
  echo "SOURCE_ROOT=$SOURCE_ROOT"
  echo "DEVICE_TREE_DEST=$SOURCE_ROOT/$DEVICE_PATH"
} >> "$GITHUB_ENV"

echo "Source root: $SOURCE_ROOT"
