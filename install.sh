#!/usr/bin/env bash
#  ytdlmux — one-shot installer for Termux (Android), macOS, Linux and Windows
#  (Git Bash / WSL).
#
#  Usage:  bash install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/dl"

c()  { printf '\033[36m%s\033[0m\n' "$*"; }        # cyan
ok() { printf '\033[32m✔ %s\033[0m\n' "$*"; }      # green
wr() { printf '\033[33m⚠ %s\033[0m\n' "$*"; }      # yellow
er() { printf '\033[31m✖ %s\033[0m\n' "$*" >&2; }  # red

# --- 0. detect platform ----------------------------------------------------
OS="unknown"
case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux)
        if [ -n "${ANDROID_ROOT:-}" ] || [ -d /data/data/com.termux/files/usr ] \
           || [ -n "${TERMUX_VERSION:-}" ]; then
            OS="termux"
        elif grep -qi microsoft /proc/version 2>/dev/null; then
            OS="wsl"
        else
            OS="linux"
        fi
        ;;
    Darwin) OS="macos" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
esac

pick_bin_dir() {
    if [ "$OS" = "termux" ]; then
        printf '%s\n' "${PREFIX:-/data/data/com.termux/files/usr}/bin"
        return
    fi
    # Desktop: strongly prefer the per-user dir. Writing to /usr/local/bin
    # needs elevated rights on most setups and would let one user's install
    # shadow the "dl" every other user gets -- not what a personal tool wants.
    local d
    for d in "$HOME/.local/bin" "$HOME/bin"; do
        case ":$PATH:" in
            *":$d:"*) printf '%s\n' "$d"; return ;;
        esac
    done
    for d in "$HOME/.local/bin" "$HOME/bin"; do
        [ -d "$d" ] && printf '%s\n' "$d" && return
    done
    # Only reach for a shared location when the user has no writable dir of
    # their own AND it is genuinely writable without sudo.
    for d in "/usr/local/bin" "/opt/homebrew/bin"; do
        case ":$PATH:" in
            *":$d:"*) [ -w "$d" ] && { printf '%s\n' "$d"; return; } ;;
        esac
    done
    printf '%s\n' "$HOME/.local/bin"
}

BIN_DIR="$(pick_bin_dir)"
TARGET="$BIN_DIR/dl"

c "==> ytdlmux installer  (detected: $OS)"

# --- 1. dependencies -------------------------------------------------------
install_deps() {
    case "$OS" in
        termux)
            c "==> Updating packages & installing dependencies (python, ffmpeg, nodejs)…"
            pkg update -y >/dev/null 2>&1 || wr "pkg update failed, continuing anyway"
            pkg install -y python ffmpeg nodejs >/dev/null 2>&1 \
                && ok "python / ffmpeg / nodejs ready" \
                || wr "Some packages failed — run: pkg install python ffmpeg nodejs"
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                c "==> Installing dependencies via Homebrew…"
                brew list ffmpeg >/dev/null 2>&1 || brew install ffmpeg \
                    || wr "ffmpeg install failed — run: brew install ffmpeg"
                brew list node   >/dev/null 2>&1 || brew install node \
                    || wr "node install failed — run: brew install node"
                ok "ffmpeg / node checked"
            else
                wr "Homebrew not found. Install it from https://brew.sh then run:"
                wr "  brew install ffmpeg node"
            fi
            ;;
        linux|wsl)
            if command -v ffmpeg >/dev/null 2>&1; then
                ok "ffmpeg already installed"
            elif command -v apt-get >/dev/null 2>&1; then
                c "==> Installing ffmpeg via apt (needs sudo)…"
                sudo apt-get install -y ffmpeg || wr "run: sudo apt install ffmpeg"
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y ffmpeg-free || wr "run: sudo dnf install ffmpeg"
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm ffmpeg || wr "run: sudo pacman -S ffmpeg"
            else
                wr "Install ffmpeg with your distro's package manager."
            fi
            ;;
        windows)
            if command -v winget >/dev/null 2>&1; then
                c "==> Installing ffmpeg via winget…"
                winget install --id Gyan.FFmpeg -e --accept-source-agreements \
                    --accept-package-agreements >/dev/null 2>&1 \
                    || wr "run: winget install Gyan.FFmpeg"
            else
                wr "Install ffmpeg from https://www.gyan.dev/ffmpeg/builds/ and add it to PATH."
            fi
            ;;
    esac
}
install_deps

# --- 2. python libraries ---------------------------------------------------
# Homebrew and Debian mark their Python "externally managed" (PEP 668) and
# refuse system-wide installs -- deliberately, to protect the OS Python. The
# right answer is a dedicated virtualenv, which also keeps dl on a modern
# interpreter instead of whatever python3 happens to be first on PATH.
#
# Why this matters: on macOS the fallback python3 is often Xcode's 3.9, and
# yt-dlp no longer works well there for YouTube extraction
# ("The page needs to be reloaded"). A venv pins a good interpreter.
VENV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ytdlmux/venv"

pick_python() {
    # Prefer a modern interpreter (>= 3.10, required by current yt-dlp).
    for cand in python3.14 python3.13 python3.12 python3.11 python3 python; do
        if command -v "$cand" >/dev/null 2>&1; then
            if "$cand" -c 'import sys; sys.exit(0 if sys.version_info>=(3,10) else 1)' 2>/dev/null; then
                printf '%s\n' "$cand"; return 0
            fi
        fi
    done
    command -v python3 >/dev/null 2>&1 && { printf 'python3\n'; return 0; }
    command -v python  >/dev/null 2>&1 && { printf 'python\n';  return 0; }
    return 1
}

if [ "$OS" = "termux" ]; then
    # Termux is not PEP 668 managed; a plain user install is lighter.
    c "==> Installing Python libraries (yt-dlp, rich, prompt_toolkit)…"
    PY="$(pick_python)" || { er "Python not found. Run: pkg install python"; exit 1; }
    if "$PY" -m pip install -U yt-dlp rich prompt_toolkit >/dev/null 2>&1; then
        ok "yt-dlp / rich / prompt_toolkit ready  ($("$PY" -V 2>&1))"
        DL_PYTHON="$PY"
    else
        er "pip install failed. Try: $PY -m pip install -U yt-dlp rich prompt_toolkit"
        exit 1
    fi
else
    PY="$(pick_python)" || { er "Python 3 not found. Install Python 3.10+ first."; exit 1; }
    c "==> Creating virtualenv for ytdlmux…"
    c "    interpreter: $("$PY" -V 2>&1)   ($(command -v "$PY"))"

    # Reuse an existing venv so re-running is cheap, but only when it still
    # points at a usable (>= 3.10) interpreter.
    if [ -x "$VENV_DIR/bin/python" ] \
       && "$VENV_DIR/bin/python" -c 'import sys; sys.exit(0 if sys.version_info>=(3,10) else 1)' 2>/dev/null; then
        ok "Existing venv reused: $VENV_DIR"
    else
        rm -rf "$VENV_DIR" 2>/dev/null || true
        if ! "$PY" -m venv "$VENV_DIR" >/dev/null 2>&1; then
            er "Could not create a virtualenv at $VENV_DIR"
            er "Hint: install python3-venv (Debian/Ubuntu) and re-run."
            exit 1
        fi
        ok "Virtualenv created: $VENV_DIR"
    fi

    c "==> Installing yt-dlp, rich, prompt_toolkit into the venv…"
    "$VENV_DIR/bin/python" -m pip install --quiet --upgrade pip >/dev/null 2>&1 || true
    if "$VENV_DIR/bin/python" -m pip install --quiet -U yt-dlp rich prompt_toolkit >/dev/null 2>&1; then
        ok "yt-dlp / rich / prompt_toolkit ready  ($("$VENV_DIR/bin/python" -V 2>&1))"
    else
        er "pip install into the venv failed. Try:"
        er "  $VENV_DIR/bin/pip install -U yt-dlp rich prompt_toolkit"
        exit 1
    fi
    DL_PYTHON="$VENV_DIR/bin/python"
fi

# --- 3. platform-specific storage setup ------------------------------------
if [ "$OS" = "termux" ]; then
    if [ ! -e "$HOME/storage" ]; then
        wr "Storage access is not enabled yet."
        wr "Allow the dialog that appears, then run install.sh again."
        termux-setup-storage || true
        exit 1
    fi
    ok "Storage access enabled"
    DCIM_DIR="$HOME/storage/dcim/ytdlmux"
    if mkdir -p "$DCIM_DIR" 2>/dev/null; then
        ok "Gallery folder ready: DCIM/ytdlmux"
    else
        wr "Cannot create $DCIM_DIR — run: termux-setup-storage"
    fi
else
    case "$OS" in
        macos)   VIDEO_DIR="$HOME/Movies/ytdlmux" ;;
        windows) VIDEO_DIR="$HOME/Videos/ytdlmux" ;;
        *)       VIDEO_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/ytdlmux" ;;
    esac
    if mkdir -p "$VIDEO_DIR" 2>/dev/null; then
        ok "Video folder ready: $VIDEO_DIR"
    else
        wr "Cannot create $VIDEO_DIR (optional; use -o to pick another folder)"
    fi
fi

# --- 4. install the command ------------------------------------------------
if [ ! -f "$SOURCE" ]; then
    er "Cannot find the 'dl' script next to install.sh."
    exit 1
fi

if [ ! -d "$BIN_DIR" ]; then
    mkdir -p "$BIN_DIR" 2>/dev/null || { er "Cannot create $BIN_DIR"; exit 1; }
fi

# Write dl with a shebang pointing at the interpreter that actually has the
# dependencies. Otherwise `./dl` falls back to /usr/bin/env python3 -- on macOS
# the outdated Xcode 3.9 -- and YouTube extraction fails.
INTERP=""
if [ -n "${DL_PYTHON:-}" ] && command -v "$DL_PYTHON" >/dev/null 2>&1; then
    INTERP="$(command -v "$DL_PYTHON")"
fi

if [ -n "$INTERP" ]; then
    if SOURCE="$SOURCE" TARGET="$TARGET" INTERP="$INTERP" python3 - <<'PYEOF'
import os
src, dst = os.environ["SOURCE"], os.environ["TARGET"]
lines = open(src, encoding="utf-8").read().split("\n")
if lines and lines[0].startswith("#!"):
    lines[0] = "#!" + os.environ["INTERP"]
open(dst, "w", encoding="utf-8").write("\n".join(lines))
PYEOF
    then
        chmod 755 "$TARGET"
        ok "Installed: $TARGET"
        ok "  shebang -> $INTERP"
    else
        install -m 755 "$SOURCE" "$TARGET" 2>/dev/null \
            || { cp "$SOURCE" "$TARGET" && chmod 755 "$TARGET"; } \
            || { er "Cannot write $TARGET (try: sudo bash install.sh)"; exit 1; }
        wr "Installed, but could not retarget the shebang — dl may use the wrong python"
        ok "Installed: $TARGET"
    fi
else
    install -m 755 "$SOURCE" "$TARGET" 2>/dev/null \
        || { cp "$SOURCE" "$TARGET" && chmod 755 "$TARGET"; } \
        || { er "Cannot write $TARGET (try: sudo bash install.sh)"; exit 1; }
    ok "Installed: $TARGET"
fi

# --- 5. PATH hint ----------------------------------------------------------
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        wr "$BIN_DIR is not on your PATH. Add it with:"
        if [ "$OS" = "windows" ]; then
            echo "     setx PATH \"%PATH%;$BIN_DIR\""
        else
            echo "     echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
        fi
        ;;
esac

# --- 6. optional extras ----------------------------------------------------
if [ "$OS" = "termux" ]; then
    if ! command -v termux-media-scan >/dev/null 2>&1; then
        c "==> Installing Termux:API (optional, for clipboard & notifications)…"
        pkg install -y termux-api >/dev/null 2>&1 || wr "termux-api package failed to install"
        wr "Remember: the 'Termux:API' app (F-Droid) must also be installed on your phone."
    fi
else
    if [ "$OS" = "linux" ] && ! command -v notify-send >/dev/null 2>&1; then
        wr "Optional: install libnotify for desktop notifications (notify-send)."
    fi
    if [ "$OS" = "linux" ] && [ -z "${WAYLAND_DISPLAY:-}" ] \
       && ! command -v xclip >/dev/null 2>&1 && ! command -v xsel >/dev/null 2>&1; then
        wr "Optional: install xclip or xsel to use 'dl' with no URL (clipboard)."
    fi
fi

echo
ok "Done!  Try:  dl -y \"https://youtu.be/xxxx\""
echo "   Help:      dl -h"
echo "   Update:    dl -U   (updates yt-dlp + ytdlmux itself)"
