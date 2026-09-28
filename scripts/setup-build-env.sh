#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  adb autoconf automake axel bc bison build-essential ccache clang cmake curl expat fastboot flex \
  g++ g++-multilib gawk gcc gcc-multilib git git-lfs gnupg gperf imagemagick \
  lib32ncurses-dev lib32z1-dev libc6-dev libcap-dev libexpat1-dev libgmp-dev liblz4-dev \
  liblzma-dev libmpc-dev libmpfr-dev libncurses-dev libncurses6 libssl-dev libtool libxml2-dev \
  libxml2-utils lzip lzop maven ncftp patch patchelf pkg-config pngcrush pngquant python-is-python3 \
  python3 python3-dev python3-pip re2c schedtool squashfs-tools subversion texinfo unzip w3m wget \
  xsltproc zip zlib1g-dev libxml-simple-perl libswitch-perl aria2

sudo apt-get install -y "linux-modules-extra-$(uname -r)" || true

if ! command -v repo >/dev/null 2>&1; then
  if sudo apt-get install -y repo; then
    :
  else
    mkdir -p "$HOME/bin"
    curl --fail --location --retry 3 --retry-delay 2 \
      https://storage.googleapis.com/git-repo-downloads/repo \
      -o "$HOME/bin/repo"
    chmod +x "$HOME/bin/repo"
    echo "$HOME/bin" >> "$GITHUB_PATH"
    export PATH="$HOME/bin:$PATH"
  fi
fi

git lfs install --skip-repo

for cmd in git python3 repo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "::error::Required command is unavailable after setup: $cmd"
    exit 1
  fi
done

echo "Build environment ready."
