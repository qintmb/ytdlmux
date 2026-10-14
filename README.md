# ytdlmux

**Downloader video/audio untuk Termux Android dengan tampilan TUI interaktif.**

`ytdlmux` membungkus [yt-dlp](https://github.com/yt-dlp/yt-dlp) dengan antarmuka
terminal yang rapi: pemilih resolusi, progress bar, kecepatan download, ETA, dan
daftar format. Hasil download otomatis disimpan ke **`DCIM/ytdlmux`** di
penyimpanan Android, lalu didaftarkan ke media scanner — jadi videonya **langsung
muncul di aplikasi Galeri** HP, bukan tersembunyi di folder internal Termux.

Perintahnya pendek: **`dl`**.

```
  ⬇  ytdlmux   yt-dlp TUI downloader
  Tujuan   /storage/emulated/0/DCIM/ytdlmux
  Format   1080p mp4
  Selesai  1 file
 ─────────────────────────────────────────────────────────────
  ⠹ 🎬 1080p ━━━━━━━━━━━━━━━━━━━━━━━━━━━ 24.3/48.1 MB  2.1 MB/s  00:11  0:00:12
```

---

## Fitur

| Fitur | Keterangan |
|---|---|
| **TUI interaktif** | Pilih resolusi/format lewat menu, bukan mengetik flag panjang |
| **Progress bar live** | Bar, kecepatan, ETA, dan waktu berjalan real-time |
| **Simpan ke Galeri** | Output ke `DCIM/ytdlmux` + auto media-scan Android |
| **Video + audio terbaik** | Otomatis menggabungkan stream terbaik (butuh `ffmpeg`) |
| **Audio MP3 320k** | Konversi audio dengan `-a` |
| **Playlist** | Unduh seluruh playlist dengan `-p` |
| **Subtitle** | Unduh & embed subtitle Indonesia/Inggris dengan `-s` |
| **Clipboard** | Jalankan `dl` tanpa argumen untuk mengambil URL dari clipboard |
| **Notifikasi** | Notifikasi Android saat download selesai (Termux:API) |
| **Wake lock** | CPU tetap bangun selama download berjalan |
| **Fallback aman** | Tetap jalan walau Termux:API tidak terpasang |

---

## Cara Instalasi di Termux (Android)

### 1. Install Termux

Pasang **Termux** dari **F-Droid** (disarankan) atau GitHub Releases:

- <https://f-droid.org/packages/com.termux/>

> ⚠️ **Jangan** pakai Termux dari Google Play — versinya sudah usang dan
> `pkg install` sering gagal.

### 2. Izinkan akses penyimpanan

```bash
termux-setup-storage
```

Setujui dialog izin yang muncul. Ini wajib, karena folder `DCIM` ada di
penyimpanan bersama Android.

### 3. Install dependensi

```bash
pkg update -y && pkg upgrade -y
pkg install -y python ffmpeg nodejs git
pip install -U yt-dlp rich prompt_toolkit
```

Keterangan:

- `python` — menjalankan skrip
- `ffmpeg` — menggabungkan video+audio & konversi MP3
- `nodejs` — JavaScript runtime, agar ekstraksi YouTube tetap didukung yt-dlp
- `rich` — tampilan TUI
- `prompt_toolkit` — menu pemilih resolusi

### 4. Ambil project ini

```bash
git clone https://github.com/qintmb/ytdlmux.git
cd ytdlmux
```

### 5. Install perintah `dl`

Cara otomatis:

```bash
bash install.sh
```

Atau manual:

```bash
install -m 755 dl "$PREFIX/bin/dl"
mkdir -p ~/storage/dcim/ytdlmux
```

### 6. Selesai — coba download

```bash
dl -y "https://youtu.be/VIDEO_ID"
```

File akan muncul di **DCIM/ytdlmux** dan tampil di aplikasi Galeri.

---

## Cara Pakai

```bash
dl <url>                    # pilih resolusi lewat menu, lalu download
dl -y <url>                 # langsung kualitas terbaik (tanpa menu)
dl -a <url>                 # hanya audio -> MP3 320 kbps
dl -l <url>                 # lihat daftar format yang tersedia
dl -f "137+140" <url>       # format selector yt-dlp manual
dl -p <url>                 # unduh seluruh playlist
dl --playlist-items 1-5 <url>   # hanya item 1–5 dari playlist
dl -s <url>                 # unduh + embed subtitle (id/en)
dl -o ~/storage/movies <url>    # ganti folder tujuan
dl -x socks5://127.0.0.1:1080 <url>  # lewat proxy
dl --limit-rate 500000 <url>     # batasi kecepatan (byte/detik)
dl                          # ambil URL dari clipboard Android
dl -U                       # update yt-dlp
dl -V                       # cek versi
```

### Contoh

```bash
# Video kualitas terbaik
dl -y "https://youtu.be/dQw4w9WgXcQ"

# Ekstrak audio ke MP3
dl -a "https://youtu.be/dQw4w9WgXcQ"

# Unduh playlist lengkap, pilih kualitas otomatis
dl -y -p "https://youtube.com/playlist?list=XXXX"

# Copy URL di browser HP, lalu cukup jalankan:
dl
```

---

## Ke Mana File Disimpan?

Secara default: **`/storage/emulated/0/DCIM/ytdlmux`**

Folder `DCIM` adalah lokasi standar galeri Android, jadi hasil download langsung
terindeks oleh aplikasi Galeri, Google Photos, dan pemutar video lainnya.

Skrip otomatis memanggil media scanner setelah download selesai. Kalau file belum
muncul di galeri, scan manual:

```bash
termux-media-scan -r ~/storage/dcim/ytdlmux
```

Urutan folder yang dicoba (dipakai yang pertama bisa ditulis):

1. `/storage/emulated/0/DCIM/ytdlmux`
2. `/sdcard/DCIM/ytdlmux`
3. `~/storage/dcim/ytdlmux`
4. `~/storage/downloads`
5. `~/Downloads`

Untuk memakai folder lain, gunakan `-o`.

---

## Termux:API (opsional)

Beberapa fitur tambahan butuh aplikasi **Termux:API**:

- ambil URL dari clipboard (`dl` tanpa argumen)
- notifikasi saat download selesai
- `termux-media-scan` resmi

```bash
pkg install -y termux-api
```

Lalu pasang aplikasi **Termux:API** dari F-Droid:

- <https://f-droid.org/packages/com.termux.api/>

Tanpa Termux:API, `ytdlmux` tetap berfungsi normal: media scan otomatis memakai
`am broadcast` bawaan Android, dan fitur clipboard/notifikasi dilewati.

---

## Troubleshooting

**`ytdlmux: command not found`**
Pastikan `$PREFIX/bin` ada di `PATH`:

```bash
echo 'export PATH="$PREFIX/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

**Error `Unable to extract` / video YouTube gagal**
yt-dlp perlu sering di-update:

```bash
dl -U
```

**Penggabungan video+audio gagal**
`ffmpeg` belum terpasang:

```bash
pkg install -y ffmpeg
```

**File tidak muncul di galeri**
Jalankan scan manual, lalu buka ulang aplikasi Galeri:

```bash
termux-media-scan -r ~/storage/dcim/ytdlmux
```

**Izin penyimpanan hilang setelah update Termux**
Jalankan `termux-setup-storage` lagi.

**Download terasa lambat**
Android membatasi proses latar belakang. Nonaktifkan optimasi baterai untuk
Termux di *Settings → Apps → Termux → Battery*.

---

## Struktur Project

```
ytdlmux/
├── dl           # skrip utama (Python), dipasang sebagai perintah `dl`
├── install.sh   # installer otomatis untuk Termux
├── README.md    # dokumentasi ini
├── LICENSE      # lisensi MIT
└── .gitignore
```

---

## Requirements

- Termux (F-Droid) + Android 7.0 atau lebih baru
- Python 3.8+
- `yt-dlp`, `rich`, `prompt_toolkit`
- `ffmpeg` (untuk merge video+audio & konversi MP3)
- `nodejs` (disarankan, untuk ekstraksi YouTube)

---

## Lisensi

MIT — lihat [LICENSE](LICENSE).

Project ini hanya pembungkus antarmuka. Mesin unduhnya adalah
[yt-dlp](https://github.com/yt-dlp/yt-dlp). Hormati hak cipta dan
Ketentuan Layanan situs yang kamu unduh.
