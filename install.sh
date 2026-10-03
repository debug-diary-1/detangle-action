#!/usr/bin/env bash
# Installs a detangle release binary for this runner and puts it on PATH.
# Inputs come from the environment: DETANGLE_VERSION ("latest" or a version
# such as 0.2.2), RUNNER_OS, RUNNER_ARCH, RUNNER_TEMP, GITHUB_PATH, GITHUB_OUTPUT.
set -euo pipefail

repo=https://github.com/debug-diary-1/detangle
version=${DETANGLE_VERSION:-latest}
version=${version#v}
if [ "$version" = latest ]; then
  # The /releases/latest page redirects to the newest tag; no API call, so
  # no rate limit.
  tag=$(curl -fsSI "$repo/releases/latest" | tr -d '\r' | sed -n 's|^[Ll]ocation: .*/tag/||p')
  version=${tag#v}
  [ -n "$version" ] || { echo "::error::detangle: couldn't find the latest release"; exit 1; }
fi

case "$RUNNER_OS-$RUNNER_ARCH" in
  Linux-X64) target=x86_64-unknown-linux-musl ext=tar.gz ;;
  Linux-ARM64) target=aarch64-unknown-linux-musl ext=tar.gz ;;
  macOS-X64) target=x86_64-apple-darwin ext=tar.gz ;;
  macOS-ARM64) target=aarch64-apple-darwin ext=tar.gz ;;
  Windows-X64) target=x86_64-pc-windows-msvc ext=zip ;;
  Windows-ARM64) target=aarch64-pc-windows-msvc ext=zip ;;
  *) echo "::error::detangle: no release binary for $RUNNER_OS $RUNNER_ARCH"; exit 1 ;;
esac

name=detangle-$version-$target
dir=$RUNNER_TEMP/detangle-$version
mkdir -p "$dir"
cd "$dir"
curl -fsSLO "$repo/releases/download/v$version/$name.$ext"
curl -fsSL -o SHA256SUMS "$repo/releases/download/v$version/SHA256SUMS"

want=$(grep " $name.$ext\$" SHA256SUMS | cut -d' ' -f1)
if command -v sha256sum >/dev/null; then
  got=$(sha256sum "$name.$ext" | cut -d' ' -f1)
else
  got=$(shasum -a 256 "$name.$ext" | cut -d' ' -f1)
fi
if [ -z "$want" ] || [ "$want" != "$got" ]; then
  echo "::error::detangle: checksum mismatch for $name.$ext"
  exit 1
fi

if [ "$ext" = zip ]; then
  pwsh -NoProfile -Command "Expand-Archive -Force -Path '$name.$ext' -DestinationPath '.'"
else
  tar xzf "$name.$ext"
fi

echo "$dir/$name" >>"$GITHUB_PATH"
echo "version=$version" >>"$GITHUB_OUTPUT"
echo "Installed detangle $version ($target)"
