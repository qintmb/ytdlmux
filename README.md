# ytdlmux

**Video/audio downloader for Termux on Android with an interactive TUI.**

`ytdlmux` wraps [yt-dlp](https://github.com/yt-dlp/yt-dlp) in a clean terminal
interface: a resolution picker, progress bar, download speed, ETA, and a format
list. Downloads are saved to **`DCIM/ytdlmux`** on Android storage and registered
with the media scanner — so your videos **show up right in the phone's Gallery
app**, instead of hiding inside Termux's private folder.

The command is short: **`dl`**.

```
  ⬇  ytdlmux   yt-dlp TUI downloader
  Target   /storage/emulated/0/DCIM/ytdlmux
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
| **Saves to Gallery** | Output to `DCIM/ytdlmux` + automatic Android media scan |
| **Best video + audio** | Automatically merges the best streams (requires `ffmpeg`) |
| **MP3 320k audio** | Convert audio with `-a` |
| **Playlists** | Download a whole playlist with `-p` |
| **Subtitles** | Download & embed Indonesian/English subtitles with `-s` |
| **Clipboard** | Run `dl` with no arguments to grab the URL from the clipboard |
| **Notifications** | Android notification when a download finishes (Termux:API) |
| **Wake lock** | Keeps the CPU awake while a download is running |
| **Safe fallback** | Still works even without Termux:API installed |

---

## Installing on Termux (Android)

### 1. Install Termux

Install **Termux** from **F-Droid** (recommended) or GitHub Releases:

- <https://f-droid.org/packages/com.termux/>

> ⚠️ Do **not** use Termux from Google Play — that version is outdated and
> `pkg install` often fails.

### 2. Grant storage access

```bash
termux-setup-storage
```

Approve the permission dialog that appears. This is required, because the `DCIM`
folder lives in Android's shared storage.

### 3. Install dependencies

```bash
pkg update -y && pkg upgrade -y
pkg install -y python ffmpeg nodejs git
pip install -U yt-dlp rich prompt_toolkit
```

Details:

- `python` — runs the script
- `ffmpeg` — merges video+audio & converts to MP3
- `nodejs` — JavaScript runtime, so yt-dlp keeps supporting YouTube extraction
- `rich` — the TUI display
- `prompt_toolkit` — the resolution picker menu

### 4. Get this project

```bash
git clone https://github.com/qintmb/ytdlmux.git
cd ytdlmux
```

### 5. Install the `dl` command

Automatic:

```bash
bash install.sh
```

Or manual:

```bash
install -m 755 dl "$PREFIX/bin/dl"
mkdir -p ~/storage/dcim/ytdlmux
```

### 6. Done — try a download

```bash
dl -y "https://youtu.be/VIDEO_ID"
```

The file will appear in **DCIM/ytdlmux** and show up in the Gallery app.

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
dl -s <url>                 # download + embed subtitles (id/en)
dl -o ~/storage/movies <url>    # change the target folder
dl -x socks5://127.0.0.1:1080 <url>  # through a proxy
dl --limit-rate 500000 <url>     # limit speed (bytes/second)
dl                          # grab the URL from the Android clipboard
dl -U                       # update yt-dlp
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

# Copy a URL in the phone's browser, then just run:
dl
```

---

## Where Are Files Saved?

By default: **`/storage/emulated/0/DCIM/ytdlmux`**

The `DCIM` folder is Android's standard gallery location, so downloads are
indexed directly by the Gallery app, Google Photos, and other video players.

The script automatically calls the media scanner once a download finishes. If a
file doesn't show up in the gallery, scan manually:

```bash
termux-media-scan -r ~/storage/dcim/ytdlmux
```

The folders tried, in order (the first writable one is used):

1. `/storage/emulated/0/DCIM/ytdlmux`
2. `/sdcard/DCIM/ytdlmux`
3. `~/storage/dcim/ytdlmux`
4. `~/storage/downloads`
5. `~/Downloads`

To use a different folder, pass `-o`.

---

## Termux:API (optional)

A few extra features need the **Termux:API** app:

- grabbing a URL from the clipboard (`dl` with no arguments)
- notifications when a download finishes
- the official `termux-media-scan`

```bash
pkg install -y termux-api
```

Then install the **Termux:API** app from F-Droid:

- <https://f-droid.org/packages/com.termux.api/>

Without Termux:API, `ytdlmux` still works normally: the automatic media scan uses
Android's built-in `am broadcast`, and the clipboard/notification features are
skipped.

---

## Troubleshooting

**`ytdlmux: command not found`**
Make sure `$PREFIX/bin` is on your `PATH`:

```bash
echo 'export PATH="$PREFIX/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

**`Unable to extract` error / YouTube video fails**
yt-dlp needs frequent updates:

```bash
dl -U
```

**Merging video+audio fails**
`ffmpeg` is not installed:

```bash
pkg install -y ffmpeg
```

**File doesn't show up in the gallery**
Run a manual scan, then reopen the Gallery app:

```bash
termux-media-scan -r ~/storage/dcim/ytdlmux
```

**Storage permission is lost after a Termux update**
Run `termux-setup-storage` again.

**Downloads feel slow**
Android throttles background processes. Disable battery optimization for
Termux under *Settings → Apps → Termux → Battery*.

---

## Project Structure

```
ytdlmux/
├── dl           # main script (Python), installed as the `dl` command
├── install.sh   # automatic installer for Termux
├── README.md    # this documentation
├── LICENSE      # MIT license
└── .gitignore
```

---

## Requirements

- Termux (F-Droid) + Android 7.0 or newer
- Python 3.8+
- `yt-dlp`, `rich`, `prompt_toolkit`
- `ffmpeg` (for merging video+audio & MP3 conversion)
- `nodejs` (recommended, for YouTube extraction)

---

## License

MIT — see [LICENSE](LICENSE).

This project is only an interface wrapper. The download engine is
[yt-dlp](https://github.com/yt-dlp/yt-dlp). Respect copyright and the
Terms of Service of the sites you download from.
