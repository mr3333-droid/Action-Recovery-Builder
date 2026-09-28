#!/usr/bin/env bash
set -euo pipefail

{
  echo "### $BUILD_LABEL recovery build"
  echo "- Device: `$DEVICE_NAME`"
  echo "- Target: `$BUILD_TARGET`"
  echo "- Manifest: `$MANIFEST_BRANCH`"
  echo "- Device tree: `$DEVICE_TREE_BRANCH` @ [`$LATEST_COMMIT`]($COMMIT_URL)"
  echo "- Image: `$(basename "$IMG_PATH")`"
  if [[ -n "${ZIP_PATH:-}" ]]; then
    echo "- Installer: `$(basename "$ZIP_PATH")`"
  fi
  echo
  echo "#### SHA-256"
  echo '~~~text'
  cat "$CHECKSUMS_PATH"
  echo '~~~'
  echo
  echo "#### Runner"
  echo '~~~text'
  echo "CPU: $(nproc --all) threads"
  free -h || true
  df -h "$RUNNER_TEMP" || true
  echo '~~~'
} >> "$GITHUB_STEP_SUMMARY"
