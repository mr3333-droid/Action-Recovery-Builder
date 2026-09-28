#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_ROOT:?SOURCE_ROOT is required}"
OUT_DIR="$SOURCE_ROOT/out/target/product/$DEVICE_NAME"

case "$BUILD_TARGET" in
  vendorboot) SOURCE_IMAGE="$OUT_DIR/vendor_boot.img" ;;
  boot) SOURCE_IMAGE="$OUT_DIR/boot.img" ;;
  recovery) SOURCE_IMAGE="$OUT_DIR/recovery.img" ;;
  *) echo "::error::Unsupported build target: $BUILD_TARGET"; exit 1 ;;
esac

if [[ ! -s "$SOURCE_IMAGE" ]]; then
  echo "::error::Expected build image was not found: $SOURCE_IMAGE"
  ls -lah "$OUT_DIR" || true
  exit 1
fi

if [[ "$BUILD_FLAVOR" == "twrp" && "$BUILD_TARGET" == "recovery" ]]; then
  VERSION="${MANIFEST_BRANCH#twrp-}"
  IMG_PATH="$OUT_DIR/twrp-${VERSION}-${DEVICE_NAME}.img"
  cp -f "$SOURCE_IMAGE" "$IMG_PATH"
else
  IMG_PATH="$SOURCE_IMAGE"
fi

ZIP_PATH=""
if [[ "$BUILD_FLAVOR" == "orangefox" ]]; then
  ZIP_PATH="$(find "$OUT_DIR" -maxdepth 1 -type f -name 'OrangeFox-R*.zip' -print | sort | head -n 1 || true)"
else
  ZIP_PATH="$(find "$OUT_DIR" -maxdepth 1 -type f -name '*.zip' -print | sort | head -n 1 || true)"
fi

CHECKSUMS_PATH="$OUT_DIR/SHA256SUMS"
(
  cd "$OUT_DIR"
  sha256sum "$(basename "$IMG_PATH")"
  if [[ -n "$ZIP_PATH" && -s "$ZIP_PATH" ]]; then
    sha256sum "$(basename "$ZIP_PATH")"
  fi
) > "$CHECKSUMS_PATH"

{
  echo "OUT_DIR=$OUT_DIR"
  echo "IMG_PATH=$IMG_PATH"
  echo "ZIP_PATH=$ZIP_PATH"
  echo "CHECKSUMS_PATH=$CHECKSUMS_PATH"
} >> "$GITHUB_ENV"

file "$IMG_PATH" || true
ls -lh "$IMG_PATH" "$CHECKSUMS_PATH"
[[ -z "$ZIP_PATH" ]] || ls -lh "$ZIP_PATH"
