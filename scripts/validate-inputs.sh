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

# Validate access before spending time and disk on a full recovery-source sync.
AUTH_URL="$DEVICE_TREE_URL"
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
  if [[ -z "${DT_TOKEN:-}" ]]; then
    fail "Cannot access '$DEVICE_TREE_BRANCH' in the device-tree repository. If the repository is private, add a read-only DT_TOKEN repository secret."
  fi
  fail "Cannot access '$DEVICE_TREE_BRANCH' with DT_TOKEN. Check the token's repository access and expiry."
fi

if [[ -n "${TG_BOT_TOKEN:-}" && -z "${TG_CHAT_ID:-}" ]] || [[ -z "${TG_BOT_TOKEN:-}" && -n "${TG_CHAT_ID:-}" ]]; then
  echo "::warning::Telegram notifications need both TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID secrets."
fi

mkdir -p "$BUILD_WORKSPACE"
echo "Input validation passed."
