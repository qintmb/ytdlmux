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
    er "Folder bin Termux tidak ditemukan: $BIN_DIR"
    er "Jalankan skrip ini di dalam Termux."
    exit 1
fi

# --- 1. dependencies -------------------------------------------------------
c "==> Update paket & install dependensi (ffmpeg, python, nodejs)…"
pkg update -y >/dev/null 2>&1 || wr "pkg update gagal, lanjut saja"
pkg install -y python ffmpeg nodejs >/dev/null 2>&1 \
    && ok "python / ffmpeg / nodejs siap" \
    || wr "Sebagian paket gagal dipasang — cek manual dengan: pkg install python ffmpeg nodejs"

c "==> Install library Python (yt-dlp, rich, prompt_toolkit)…"
pip install -U yt-dlp rich prompt_toolkit >/dev/null 2>&1 \
    && ok "yt-dlp / rich / prompt_toolkit siap" \
    || { er "pip install gagal. Coba: pip install -U yt-dlp rich prompt_toolkit"; exit 1; }

# --- 2. storage access -----------------------------------------------------
if [ ! -e "$HOME/storage" ]; then
    wr "Akses penyimpanan belum aktif."
    wr "Izinkan dialog yang muncul, lalu jalankan install.sh lagi."
    termux-setup-storage || true
    exit 1
fi
ok "Akses penyimpanan aktif"

# --- 3. gallery folder -----------------------------------------------------
DCIM_DIR="$HOME/storage/dcim/ytdlmux"
if mkdir -p "$DCIM_DIR" 2>/dev/null; then
    ok "Folder galeri siap: DCIM/ytdlmux"
else
    wr "Tidak bisa membuat $DCIM_DIR — jalankan: termux-setup-storage"
fi

# --- 4. install the command ------------------------------------------------
install -m 755 "$SCRIPT_DIR/dl" "$TARGET"
ok "Terpasang: $TARGET"

# --- 5. optional: Termux:API (clipboard, notification, media scan) ---------
if ! command -v termux-media-scan >/dev/null 2>&1; then
    c "==> Install Termux:API (opsional, untuk clipboard & notifikasi)…"
    pkg install -y termux-api >/dev/null 2>&1 || wr "paket termux-api gagal dipasang"
    wr "Ingat: aplikasi 'Termux:API' (F-Droid) juga harus di-install di HP."
fi

echo
ok "Selesai!  Coba:  dl -y \"https://youtu.be/xxxx\""
echo "   File hasil download masuk ke DCIM/ytdlmux dan tampil di galeri."
echo "   Bantuan:  dl -h"
