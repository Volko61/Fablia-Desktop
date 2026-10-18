#!/usr/bin/env sh
# Fablia Desktop installer / updater for Linux.
#   curl -fsSL https://raw.githubusercontent.com/Volko61/Fablia-Desktop/main/install.sh | sh
#   wget -qO- https://raw.githubusercontent.com/Volko61/Fablia-Desktop/main/install.sh | sh
# Re-run it at any time to update. Uninstall: ... | sh -s -- --uninstall
# The app also updates itself in the background (AppImage + GitHub releases).
set -eu

REPO="Volko61/Fablia-Desktop"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_DIR="$DATA_DIR/fablia"
BIN_DIR="${FABLIA_BIN_DIR:-$HOME/.local/bin}"
DESKTOP_FILE="$DATA_DIR/applications/fablia.desktop"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

fetch() { # fetch URL [OUTPUT]
  if command -v curl >/dev/null 2>&1; then
    if [ $# -gt 1 ]; then curl -fL --progress-bar -o "$2" "$1"; else curl -fsSL "$1"; fi
  elif command -v wget >/dev/null 2>&1; then
    if [ $# -gt 1 ]; then wget -q --show-progress -O "$2" "$1"; else wget -qO- "$1"; fi
  else
    die "curl or wget is required"
  fi
}

if [ "${1:-}" = "--uninstall" ]; then
  rm -rf "$APP_DIR" "$BIN_DIR/fablia" "$DESKTOP_FILE"
  say "Fablia removed (user data in ~/.config/Fablia was kept)."
  exit 0
fi

[ "$(uname -s)" = "Linux" ] || die "this installer is for Linux (on Windows: winget install Volko61.Fablia)"
case "$(uname -m)" in
  x86_64|amd64)  ARCH_RE='x86_64|x64|amd64' ;;
  aarch64|arm64) ARCH_RE='arm64|aarch64' ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

if [ -n "${FABLIA_VERSION:-}" ]; then
  API="https://api.github.com/repos/$REPO/releases/tags/v${FABLIA_VERSION#v}"
else
  API="https://api.github.com/repos/$REPO/releases/latest"
fi
say "Looking up the release..."
URL="$(fetch "$API" | grep -o '"browser_download_url": *"[^"]*\.AppImage"' | cut -d'"' -f4 | grep -E "[-_.]($ARCH_RE)\.AppImage$" | head -n1)" \
  || true
[ -n "$URL" ] || die "no AppImage found for this architecture in $API"
VERSION="$(printf '%s' "$URL" | sed -E 's|.*/v([^/]+)/.*|\1|')"

if [ -x "$APP_DIR/Fablia.AppImage" ] && [ "$(cat "$APP_DIR/version" 2>/dev/null)" = "$VERSION" ]; then
  say "Fablia $VERSION is already installed and up to date."
  exit 0
fi

mkdir -p "$APP_DIR" "$BIN_DIR" "$DATA_DIR/applications"
TMP="$(mktemp "$APP_DIR/download.XXXXXX")"
trap 'rm -f "$TMP"' EXIT
say "Downloading Fablia $VERSION..."
fetch "$URL" "$TMP"
chmod +x "$TMP"
mv -f "$TMP" "$APP_DIR/Fablia.AppImage"
printf '%s\n' "$VERSION" > "$APP_DIR/version"

fetch "https://raw.githubusercontent.com/$REPO/main/build/icon.png" "$APP_DIR/icon.png" 2>/dev/null || true

# Launcher: falls back to extract-and-run when FUSE 2 is missing.
cat > "$BIN_DIR/fablia" <<LAUNCHER
#!/usr/bin/env sh
if ! [ -e /dev/fuse ] || ! command -v fusermount >/dev/null 2>&1; then
  export APPIMAGE_EXTRACT_AND_RUN=1
fi
exec "$APP_DIR/Fablia.AppImage" "\$@"
LAUNCHER
chmod +x "$BIN_DIR/fablia"

cat > "$DESKTOP_FILE" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Fablia
Comment=Interactive AI stories
Exec=$BIN_DIR/fablia %U
Icon=$APP_DIR/icon.png
Categories=Game;
Terminal=false
StartupWMClass=Fablia
DESKTOP

say "Fablia $VERSION installed. Run 'fablia' or find it in your application menu."
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) say "Note: add $BIN_DIR to your PATH to use the 'fablia' command." ;; esac
