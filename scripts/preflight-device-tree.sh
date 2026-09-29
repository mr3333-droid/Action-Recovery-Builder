#!/usr/bin/env bash
set -euo pipefail

: "${DEVICE_TREE_URL:?DEVICE_TREE_URL is required}"
: "${DEVICE_TREE_BRANCH:?DEVICE_TREE_BRANCH is required}"
: "${MAKEFILE_NAME:?MAKEFILE_NAME is required}"

TMP_TREE="${RUNNER_TEMP:-/tmp}/device-tree-preflight"
AUTH_URL="$DEVICE_TREE_URL"

cleanup() {
  rm -rf "$TMP_TREE"
}
trap cleanup EXIT

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

rm -rf "$TMP_TREE"

if ! git ls-remote --exit-code "$AUTH_URL" "refs/heads/$DEVICE_TREE_BRANCH" >/dev/null 2>&1; then
  echo "::error::Cannot access branch '$DEVICE_TREE_BRANCH' in the device tree repository."
  exit 1
fi

git clone --quiet --depth=1 --single-branch --branch "$DEVICE_TREE_BRANCH" "$AUTH_URL" "$TMP_TREE"

if [[ ! -f "$TMP_TREE/AndroidProducts.mk" ]]; then
  echo "::error::Device tree is missing AndroidProducts.mk"
  exit 1
fi

if [[ ! -f "$TMP_TREE/$MAKEFILE_NAME.mk" ]]; then
  echo "::error::Device tree is missing expected product makefile: $MAKEFILE_NAME.mk"
  exit 1
fi

mapfile -t forbidden_board_api < <(
  grep -RInE --include='*.mk' '^[[:space:]]*BOARD_API_LEVEL[[:space:]]*[:+?]?=' "$TMP_TREE" || true
)

if (( ${#forbidden_board_api[@]} > 0 )); then
  echo "::error::BOARD_API_LEVEL must not be assigned by current OrangeFox/AOSP device trees; the build system derives it automatically."
  printf '%s\n' "${forbidden_board_api[@]}"
  exit 1
fi

echo "Device-tree preflight passed: $DEVICE_TREE_BRANCH / $MAKEFILE_NAME"
