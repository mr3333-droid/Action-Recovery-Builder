#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$BUILD_WORKSPACE"

case "$BUILD_FLAVOR" in
  orangefox)
    SOURCE_ROOT="$BUILD_WORKSPACE/fox_${MANIFEST_BRANCH}"
    SYNC_HELPER="$BUILD_WORKSPACE/orangefox-sync"
    rm -rf "$SYNC_HELPER"
    git clone --depth=1 --single-branch "$MANIFEST_URL" "$SYNC_HELPER"
    "$SYNC_HELPER/orangefox_sync.sh" --branch "$MANIFEST_BRANCH" --path "$SOURCE_ROOT"
    ;;
  twrp)
    SOURCE_ROOT="$BUILD_WORKSPACE/twrp_${MANIFEST_BRANCH#twrp-}"
    mkdir -p "$SOURCE_ROOT"
    cd "$SOURCE_ROOT"
    repo init --depth=1 -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH"
    repo sync -c --no-clone-bundle --no-tags --force-sync -j"$(nproc --all)"
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
