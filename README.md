# ytdlmux

**Video/audio downloader with an interactive TUI — for Termux on Android,
macOS, Linux, and Windows.**

`ytdlmux` wraps [yt-dlp](https://github.com/yt-dlp/yt-dlp) in a clean terminal
interface: a resolution picker, progress bar, download speed, ETA, and a format
list. Downloads land in the folder your OS actually shows in its gallery app:

| Platform | Default folder |
|---|---|
| Android (Termux) | `/storage/emulated/0/DCIM/ytdlmux` → Gallery app |
| macOS | `~/Movies/ytdlmux` → Photos / QuickTime |
| Linux | `~/Videos/ytdlmux` (respects `XDG_VIDEOS_DIR`) |
| Windows | `%USERPROFILE%\Videos\ytdlmux` → Videos library |

The command is short: **`dl`**.

```
  ⬇  ytdlmux   yt-dlp TUI downloader
  Target   /Users/you/Movies/ytdlmux
  Format   1080p mp4
  Done     1 file
 ─────────────────────────────────────────────────────────────
  ⠹ 🎬 1080p ━━━━━━━━━━━━━━━━━━━━━━━━━━━ 24.3/48.1 MB  2.1 MB/s  00:11  0:00:12
```

---

## Features

| Feature | Description |
|---|---|
| **Interactive TUI** | Pick resolution/format from a menu instead of typing long flags |
| **Live progress bar** | Real-time bar, speed, ETA, and elapsed time |
| **Saves to your gallery** | Writes to the OS video/DCIM folder and auto-registers with the media scanner |
| **Best video + audio** | Automatically merges the best streams (requires `ffmpeg`) |
| **MP3 320k audio** | Convert audio with `-a` |
| **Playlists** | Download a whole playlist with `-p` |
| **Subtitles** | Download & embed subtitles with `-s` |
| **Clipboard** | Run `dl` with no arguments to grab the URL from the clipboard |
| **Notifications** | Native notification when a download finishes |
| **Self-update** | `dl -U` updates both yt-dlp and `ytdlmux` itself |
| **Cross-platform** | Termux/Android, macOS, Linux, WSL, and Windows |
| **Safe fallback** | Works even without optional extras like Termux:API or `notify-send` |

---

## Installation

Pick your platform. All of them end with the same `dl` command.

`install.sh` auto-detects the platform and installs to the right place
(`$PREFIX/bin` on Termux, `~/.local/bin` on desktop).

---

### Android — Termux

#### 1. Install Termux

Install **Termux** from **F-Droid** (recommended) or GitHub Releases:

- <https://f-droid.org/packages/com.termux/>

> ⚠️ Do **not** use Termux from Google Play — that version is outdated and
> `pkg install` often fails.

#### 2. Grant storage access

```bash
termux-setup-storage
```

Approve the permission dialog. This is required, because `DCIM` lives in
Android's shared storage.

#### 3. Clone and install

```bash
pkg install -y git
git clone https://github.com/qintmb/ytdlmux.git
cd ytdlmux
bash install.sh
```

Or manually:

```bash
pkg update -y && pkg upgrade -y
pkg install -y python ffmpeg nodejs
pip install -U yt-dlp rich prompt_toolkit
install -m 755 dl "$PREFIX/bin/dl"
```

#### 4. Try it

```bash
dl -y "https://youtu.be/VIDEO_ID"
```

The file appears in **DCIM/ytdlmux** and shows up in the Gallery app.

---

### macOS

#### 1. Install Homebrew (if you don't have it)

- <https://brew.sh>

#### 2. Clone and install

```bash
git clone https://github.com/qintmb/ytdlmux.git
cd ytdlmux
bash install.sh
```

The installer uses Homebrew for `ffmpeg`, pip for the Python libraries, and
installs `dl` into `~/.local/bin`.

#### 3. Make sure `~/.local/bin` is on your PATH

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

> On macOS the default shell is zsh, so use `~/.zshrc`. Use `~/.bashrc` only if
> you run bash.

#### 4. Try it

```bash
dl -y "https://youtu.be/VIDEO_ID"
```

Files land in `~/Movies/ytdlmux`.

---

### Linux

#### 1. Clone and install

```bash
git clone https://github.com/qintmb/ytdlmux.git
cd ytdlmux
bash install.sh
```

The installer picks your package manager (`apt`, `dnf`, or `pacman`) to get
`ffmpeg`, and installs `dl` into `~/.local/bin`.

#### 2. Make sure `~/.local/bin` is on your PATH

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

#### 3. Optional: clipboard and notifications

```bash
# Wayland
sudo apt install wl-clipboard libnotify-bin
# X11
sudo apt install xclip libnotify-bin
```

Without these, `dl URL` still works — only the bare `dl` clipboard shortcut and
desktop notifications are skipped.

#### 4. Try it

```bash
dl -y "https://youtu.be/VIDEO_ID"
```

Files land in `~/Videos/ytdlmux` (or `$XDG_VIDEOS_DIR/ytdlmux` if set).

---

### Windows

Use **Git Bash** (bundled with [Git for Windows](https://git-scm.com/download/win))
or **WSL**.

#### Option A — Git Bash

```bash
git clone https://github.com/qintmb/ytdlmux.git
cd ytdlmux
bash install.sh
```

`dl` is installed to `~/.local/bin`. Add it to your PATH (Git Bash):

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

For `ffmpeg`, either let the installer use `winget`:

```powershell
winget install Gyan.FFmpeg
```

…or download it from <https://www.gyan.dev/ffmpeg/builds/> and add its `bin`
folder to PATH.

#### Option B — WSL (recommended for the smoothest experience)

Follow the **Linux** instructions above inside your WSL distro. Files land in the
WSL home directory; use `-o /mnt/c/Users/you/Videos` to save them on Windows.

#### Try it

```bash
dl -y "https://youtu.be/VIDEO_ID"
```

Files land in `%USERPROFILE%\Videos\ytdlmux`.

---

## Usage

```bash
dl <url>                    # pick a resolution from the menu, then download
dl -y <url>                 # go straight to best quality (no menu)
dl -a <url>                 # audio only -> MP3 320 kbps
dl -l <url>                 # list the available formats
dl -f "137+140" <url>       # manual yt-dlp format selector
dl -p <url>                 # download the whole playlist
dl --playlist-items 1-5 <url>   # only items 1–5 of the playlist
dl -s <url>                 # download + embed subtitles
dl -o ~/Videos <url>        # change the target folder
dl -x socks5://127.0.0.1:1080 <url>  # through a proxy
dl --limit-rate 500000 <url>     # limit speed (bytes/second)
dl                          # grab the URL from the clipboard
dl -U                       # update yt-dlp + ytdlmux
dl -V                       # check the version
```

### Examples

```bash
# Best-quality video
dl -y "https://youtu.be/dQw4w9WgXcQ"

# Extract audio to MP3
dl -a "https://youtu.be/dQw4w9WgXcQ"

# Download a full playlist, auto-pick quality
dl -y -p "https://youtube.com/playlist?list=XXXX"

# Copy a URL in your browser, then just run:
dl
```

### Updating

```bash
dl -U
```

This does two things:

1. Updates **yt-dlp** (which you need regularly — YouTube changes often).
2. Checks the latest **ytdlmux release tag** on GitHub and updates the `dl`
   script itself when a newer version exists.

The script is replaced atomically and keeps its executable bit. If `dl` is
installed somewhere read-only (like `/usr/bin`), it tells you to re-run with
elevated rights instead of failing silently. Offline, it simply skips the script
update.

---

## Where Are Files Saved?

The default is the first writable folder in this list:

| Platform | Candidate folders, in order |
|---|---|
| Android | `/storage/emulated/0/DCIM/ytdlmux`, `/sdcard/DCIM/ytdlmux`, `~/storage/dcim/ytdlmux`, `~/storage/downloads`, `~/Downloads` |
| macOS | `~/Movies/ytdlmux`, `~/Downloads` |
| Linux | `$XDG_VIDEOS_DIR/ytdlmux`, `~/Videos/ytdlmux`, `~/Downloads` |
| Windows | `%USERPROFILE%\Videos\ytdlmux`, `%USERPROFILE%\Downloads` |

An existing gallery/video folder always wins. If none exists, `ytdlmux` creates
the preferred one rather than quietly filling `~/Downloads`.

To use a different folder, pass `-o`:

```bash
dl -o ~/Desktop/videos "https://youtu.be/XXXX"
```

### Gallery registration

On **Android**, the script calls the media scanner after each download so files
appear in the Gallery app. If a file does not show up, scan manually:

```bash
termux-media-scan -r ~/storage/dcim/ytdlmux
```

On **macOS, Linux, and Windows** no scan is needed — those video folders are
indexed live by the OS.

---

## Platform Extras

### Android — Termux:API (optional)

A few extras need the **Termux:API** app:

- grabbing a URL from the clipboard (`dl` with no arguments)
- notifications when a download finishes
- the official `termux-media-scan`

```bash
pkg install -y termux-api
```

Then install the **Termux:API** app from F-Droid:

- <https://f-droid.org/packages/com.termux.api/>

Without it, `ytdlmux` still works: the media scan falls back to Android's
built-in `am broadcast`, and the clipboard/notification features are skipped.

### Desktop — clipboard and notifications

| Platform | Clipboard | Notifications |
|---|---|---|
| macOS | `pbpaste` (built in) | `osascript` (built in) |
| Linux | `wl-paste` (Wayland), `xclip`/`xsel` (X11) | `notify-send` (libnotify) |
| Windows | PowerShell `Get-Clipboard` (built in) | PowerShell `NotifyIcon` balloon (built in) |

All of these are optional. When a tool is missing, `dl` degrades gracefully and
tells you to pass a URL explicitly.

---

## Troubleshooting

**`dl: command not found`**
`~/.local/bin` (or `$PREFIX/bin` on Termux) is not on your `PATH`.

```bash
# Linux / macOS / Git Bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

```bash
# Termux
echo 'export PATH="$PREFIX/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

**`Unable to extract` error / YouTube video fails**
yt-dlp needs frequent updates:

```bash
dl -U
```

**Merging video+audio fails**
`ffmpeg` is missing:

```bash
pkg install ffmpeg          # Termux
brew install ffmpeg         # macOS
sudo apt install ffmpeg     # Debian/Ubuntu
winget install Gyan.FFmpeg  # Windows
```

**`dl -U` says it cannot write the script**
`dl` is installed in a read-only location. Re-run the update with elevated
rights, or install to a user-writable folder:

```bash
install -m 755 dl ~/.local/bin/dl
```

**File doesn't show up in the gallery (Android)**
Run a manual scan, then reopen the Gallery app:

```bash
termux-media-scan -r ~/storage/dcim/ytdlmux
```

**Storage permission is lost after a Termux update**
Run `termux-setup-storage` again.

**Downloads feel slow on Android**
Android throttles background processes. Disable battery optimization for
Termux under *Settings → Apps → Termux → Battery*.

**Bare `dl` does nothing**
No clipboard tool was found. Pass the URL directly: `dl <url>`.

---

## Project Structure

```
ytdlmux/
├── dl           # main script (Python), installed as the `dl` command
├── install.sh   # cross-platform installer (Termux/macOS/Linux/Windows)
├── README.md    # this documentation
├── LICENSE      # MIT license
└── .gitignore
```

---

## Requirements

- Python 3.8+ (3.10+ recommended)
- `yt-dlp`, `rich`, `prompt_toolkit`
- `ffmpeg` (for merging video+audio & MP3 conversion)
- `nodejs` (recommended, for YouTube extraction)
- Termux:API *(Android, optional)*
- `wl-clipboard` / `xclip` / `xsel` and `libnotify` *(Linux, optional)*

---

## License

MIT — see [LICENSE](LICENSE).

This project is only an interface wrapper. The download engine is
[yt-dlp](https://github.com/yt-dlp/yt-dlp). Respect copyright and the
Terms of Service of the sites you download from.
