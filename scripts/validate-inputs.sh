#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "::error::$*"
  exit 1
}

[[ "$BUILD_FLAVOR" == "orangefox" || "$BUILD_FLAVOR" == "twrp" ]] || fail "Unsupported build flavor: $BUILD_FLAVOR"
[[ "$BUILD_TARGET" == "recovery" || "$BUILD_TARGET" == "boot" || "$BUILD_TARGET" == "vendorboot" ]] || fail "Unsupported build target: $BUILD_TARGET"
[[ "$DEVICE_PATH" =~ ^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)+$ ]] || fail "Invalid device_path: $DEVICE_PATH"
[[ "$DEVICE_PATH" != *".."* ]] || fail "device_path must not contain '..'"
[[ "$DEVICE_NAME" =~ ^[A-Za-z0-9._-]+$ ]] || fail "Invalid device_name: $DEVICE_NAME"
[[ "$MAKEFILE_NAME" =~ ^[A-Za-z0-9._-]+$ ]] || fail "Invalid makefile_name: $MAKEFILE_NAME"
[[ -n "$DEVICE_TREE_BRANCH" ]] || fail "device_tree_branch must not be empty"

case "$DEVICE_TREE_URL" in
  https://github.com/*|https://gitlab.com/*) ;;
  *) fail "device_tree_url must be an HTTPS GitHub or GitLab URL" ;;
esac

mkdir -p "$BUILD_WORKSPACE"
echo "Input validation passed."
