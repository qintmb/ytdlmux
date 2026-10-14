#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  ytdlmux — one-shot installer for Termux (Android)
#
#  Usage:  bash install.sh
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
TARGET="$BIN_DIR/dl"

c()  { printf '\033[36m%s\033[0m\n' "$*"; }   # cyan
ok() { printf '\033[32m✔ %s\033[0m\n' "$*"; }  # green
wr() { printf '\033[33m⚠ %s\033[0m\n' "$*"; }  # yellow
er() { printf '\033[31m✖ %s\033[0m\n' "$*" >&2; }  # red

c "==> ytdlmux installer"

if [ ! -d "$BIN_DIR" ]; then
    er "Termux bin folder not found: $BIN_DIR"
    er "Run this script inside Termux."
    exit 1
fi

# --- 1. dependencies -------------------------------------------------------
c "==> Updating packages & installing dependencies (ffmpeg, python, nodejs)…"
pkg update -y >/dev/null 2>&1 || wr "pkg update failed, continuing anyway"
pkg install -y python ffmpeg nodejs >/dev/null 2>&1 \
    && ok "python / ffmpeg / nodejs ready" \
    || wr "Some packages failed to install — check manually with: pkg install python ffmpeg nodejs"

c "==> Installing Python libraries (yt-dlp, rich, prompt_toolkit)…"
pip install -U yt-dlp rich prompt_toolkit >/dev/null 2>&1 \
    && ok "yt-dlp / rich / prompt_toolkit ready" \
    || { er "pip install failed. Try: pip install -U yt-dlp rich prompt_toolkit"; exit 1; }

# --- 2. storage access -----------------------------------------------------
if [ ! -e "$HOME/storage" ]; then
    wr "Storage access is not enabled yet."
    wr "Allow the dialog that appears, then run install.sh again."
    termux-setup-storage || true
    exit 1
fi
ok "Storage access enabled"

# --- 3. gallery folder -----------------------------------------------------
DCIM_DIR="$HOME/storage/dcim/ytdlmux"
if mkdir -p "$DCIM_DIR" 2>/dev/null; then
    ok "Gallery folder ready: DCIM/ytdlmux"
else
    wr "Cannot create $DCIM_DIR — run: termux-setup-storage"
fi

# --- 4. install the command ------------------------------------------------
install -m 755 "$SCRIPT_DIR/dl" "$TARGET"
ok "Installed: $TARGET"

# --- 5. optional: Termux:API (clipboard, notification, media scan) ---------
if ! command -v termux-media-scan >/dev/null 2>&1; then
    c "==> Installing Termux:API (optional, for clipboard & notifications)…"
    pkg install -y termux-api >/dev/null 2>&1 || wr "termux-api package failed to install"
    wr "Remember: the 'Termux:API' app (F-Droid) must also be installed on your phone."
fi

echo
ok "Done!  Try:  dl -y \"https://youtu.be/xxxx\""
echo "   Downloaded files land in DCIM/ytdlmux and show up in the gallery."
echo "   Help:  dl -h"
