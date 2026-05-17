#!/bin/sh
set -eu

DEFAULT_VERSION="v2.2.0"
REPO="moghtech/komodo"
INSTALL_PATH="/usr/local/bin/periphery"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: Dieses Script muss als root laufen." >&2
  echo "Usage: curl -fsSL <url> | sudo sh -s -- [version|latest]" >&2
  exit 1
fi

VERSION="${1:-${KOMODO_VERSION:-latest}}"

if [ "$VERSION" = "latest" ]; then
  VERSION="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1 || true)"

  if [ -z "$VERSION" ]; then
    echo "Warn: Konnte latest release nicht ermitteln, nutze $DEFAULT_VERSION" >&2
    VERSION="$DEFAULT_VERSION"
  fi
fi

case "$VERSION" in
  v*) ;;
  *) VERSION="v$VERSION" ;;
esac

ARCH="$(uname -m)"

case "$ARCH" in
  x86_64|amd64)
    BINARY_NAME="periphery-x86_64"
    ;;
  aarch64|arm64)
    BINARY_NAME="periphery-aarch64"
    ;;
  *)
    echo "Error: Unsupported architecture: $ARCH" >&2
    echo "Supported: x86_64, aarch64" >&2
    exit 1
    ;;
esac

TMP_DIR="$(mktemp -d)"
TMP_FILE="$TMP_DIR/$BINARY_NAME"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

URL="https://github.com/$REPO/releases/download/$VERSION/$BINARY_NAME"

echo "Installing Komodo Periphery $VERSION for $ARCH"
echo "Downloading $URL"

curl -fL "$URL" -o "$TMP_FILE"
chmod +x "$TMP_FILE"

install -m 755 "$TMP_FILE" "$INSTALL_PATH"

systemctl restart periphery

echo "Done."
systemctl --no-pager --full status periphery || true