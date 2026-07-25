# ZeroLive — Free Live Sports Streaming Proxy & Player

**Watch live sports free** — football, cricket, basketball, tennis, Formula 1, UFC, WWE, rugby, hockey, and more. ZeroLive is a lightweight local proxy and HLS/DASH player that lets you stream live sports from multiple sources with zero server bandwidth.

> **Keywords**: live sports streaming, watch cricket live, watch football live free, live sports free, sports streaming proxy, HLS player, live cricket score, football live stream, NBA live, F1 stream, UFC live, IPL live, Premier League live, Champions League live, World Cup live, tennis live, rugby live, live sports online free

---

## Quick Start

### Option 1: Installer (Windows)

1. Download **ZeroLive_Installer.exe** from the [download page](https://zerolive.page.gd/download.html) or any of the [official mirrors](#official-download-mirrors)
2. Run the EXE — pick your theme & install path (default: `C:\Zero_live`)
3. Click **Launch** — your browser opens to `http://127.0.0.1:9090`

### Option 2: Manual (any OS)

```bash
git clone https://github.com/rafu-milonmart/Zerolive.git
cd Zerolive
pip install -r requirements.txt
python app.py 9090
```

Then open `http://127.0.0.1:9090` in your browser.

### Option 3: Docker

```bash
docker build -t zerolive .
docker run -p 9090:9090 zerolive
```

---

## Features

### Player

- **Auto-format detection** — DASH (with ClearKey DRM), HLS, or direct MP4
- **Smart server fallback** — auto-switches to the next server on failure, no refresh needed
- **Custom progress bar** — full-width scrubber with hover tooltip, smooth thumb, no jitter
- **Double-tap fullscreen** — tap left/right half of player for 10s skip
- **Speed control** — persistent per-event playback speed (0.25x–3x)
- **Stream info overlay** — quality, format, server name at a glance
- **Auto-watch next** — auto-plays the next available event when current ends
- **Volume** — scroll wheel, drag slider, keyboard shortcuts
- **Keyboard-driven** — play/pause, mute, seek, fullscreen, all accessible without mouse

### UI & Themes

- **11 themes** — dark, light, amethyst, emerald, ruby, ocean, cyberpunk, sunset, nord, matrix, midnight
- **Glassmorphism cards** — animated gradient orbs, glow effects, smooth transitions
- **Skeleton loading** — shimmer placeholders while data loads
- **System theme detection** — auto-switches between dark/light based on OS preference
- **Settings modal** — theme picker, version info, update checker
- **Responsive** — works on mobile, tablet, and desktop

### ZL1 — Event Grid (`/`)

- Live event cards with team logos, sport badges, and countdown timers
- Search by team name, league, or sport
- Filter by sport category or favorites
- Sorted by priority (live first, then starting soon)
- Custom M3U naming — give any event a short name and access it at `/<name>.m3u`

### M3U Support

| Route | Description |
|---|---|
| `/playlist.m3u` | Full playlist of all live events |
| `/playlist/<slug>.m3u` | Single event M3U |
| `/<custom-name>.m3u` | Custom named M3U (see below) |
| `/+M3U` button | Name any event, access it at `/<name>.m3u` |

**Custom M3U naming**: Click **`+M3U`** on any event card → type a name (e.g. `morocco-vs-canada`) → Save → stream at `/morocco-vs-canada.m3u`. Names persist across restarts. Fuzzy matching works too — `/england.m3u`, `/cricket.m3u`, `/f1.m3u`.

### M3U URLs (copy/share)

Each event card has:
- **VLC** — downloads the `.m3u` file directly
- **M3U** — copies the M3U URL to clipboard

Open these URLs in VLC or any media player on any device on your local network.

### Lite Version

- `/faster` — zero-CSS event table, search, click to watch
- `/lite/<slug>` — minimal player with native controls, no themes

### Auto-Update

- Checks GitHub for new commits on startup
- One-click **Check** + **Apply** in settings modal
- Staging system — downloads to temp, applies on next restart
- `Zero_live.bat` also auto-updates on launch

---

## Routes

| Route | Description |
|---|---|
| `/` | Full UI — event cards, search, sport filters, favorites |
| `/faster` | Lite index — table layout, minimal CSS |
| `/watch/<slug>` | Full player — 11 themes, custom SVG controls |
| `/lite/<slug>` | Minimal player — native browser controls |
| `/playlist.m3u` | Full M3U playlist |
| `/playlist/<slug>.m3u` | Event-specific M3U |
| `/<name>.m3u` | Custom named M3U |

---

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/api/events` | GET | All live events (upstream + FanCode + TapMad) |
| `/api/version` | GET | Current version (commit SHA) |
| `/api/default-theme` | GET | Default theme from installer |
| `/api/custom-m3u` | GET/POST/DELETE | Custom M3U name CRUD |
| `/api/update/check` | GET | Check GitHub for newer commit |
| `/api/update/apply` | GET | Download update (staging) |
| `/api/update/restart` | GET | Restart the server |

---

## Architecture

```
User Browser  ←→  ZeroLive Server (Flask)  ←→  Upstream API (Sportzfy)
                       │
                       ├── /proxy/hls/*    →  proxied .m3u8 (few KB)
                       └── /stream/*       →  direct CDN URL (browser fetches segments)
```

### How streaming works

- **DASH** — MPD manifest + segments fetched directly by browser from CDN. ClearKey DRM decryption via `setProtectionData()`. Server only provides the decrypted manifest URL.
- **HLS** — Manifest proxied through server (few KB), sub-playlists rewritten to route `.ts` segments through CDN directly. Zero server bandwidth for video data.
- **CDN fix** — No `Referer` header sent to CDN endpoints (was causing 400 errors from Fastly).

### Deduplication & merge

Events from multiple sources (upstream, FanCode, TapMad) are merged by fuzzy team-name matching. When the same match appears in multiple sources, streams from all sources are combined into a single event card. This gives you fallback options if one source goes down.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | Flask + curl-cffi (TLS fingerprint impersonation) + cryptography (AES-GCM decrypt) |
| **Server** | Hypercorn (ASGI, 4 workers) → gunicorn gthread (4w×8t) → Flask dev fallback |
| **Player** | hls.js, dash.js, native HTML5 video |
| **Frontend** | Vanilla JS, CSS custom properties (11 themes), glassmorphism, SVG controls |
| **Installer** | PyQt6 GUI → PyInstaller → `ZeroLive_Installer.exe` (~35 MB) |
| **Deploy** | Embedded portable Python (no registry/PATH pollution), robocopy updates |

---

## Configuration

### Files

| File | Purpose |
|---|---|
| `custom_m3u_url.txt` | Custom M3U URL override (gitignored) |
| `custom_m3u_names.json` | Custom M3U name mappings (gitignored) |
| `default_theme.txt` | Theme chosen at install (gitignored) |
| `version.txt` | Current commit SHA (gitignored, managed by app) |

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `ZL_DEBUG` | `0` | Set to `1` for debug logging + template auto-reload |
| `PORT` | `9090` | Override the listening port |

---

## Keyboard Shortcuts

### Global (event grid)

| Key | Action |
|---|---|
| `?` | Toggle shortcuts help |
| `/` | Focus search |
| `F` | Toggle favorites filter |
| `R` | Refresh events |
| `1-9` | Quick sport filter |
| `Esc` | Close modal / exit fullscreen |

### Player

| Key | Action |
|---|---|
| `Space` | Play / pause |
| `M` | Mute toggle |
| `F` | Fullscreen toggle |
| `←` | Skip back 10s |
| `→` | Skip forward 10s |
| `↑` | Volume up |
| `↓` | Volume down |
| `I` | Stream info overlay |

---

## FAQ

### What is ZeroLive?

ZeroLive is a free live sports streaming app that acts as a local proxy on your PC. It fetches live sports streams — cricket, football, basketball, tennis, F1, UFC, WWE, rugby, hockey — from multiple sources and serves them through a clean web UI with a built-in video player. It never stores or re-broadcasts video — your browser fetches segments directly from the CDN. Works as a live cricket streaming app, live football streaming app, and for all major sports.

### Is it free?

Yes. ZeroLive is open source and free to use. No subscriptions, no accounts, no tracking. Just free live sports streaming.

### What sports are supported?

Football (soccer) — Premier League, Champions League, La Liga, Serie A, Bundesliga, Ligue 1, MLS, World Cup. Cricket — IPL, BBL, PSL, CPL, ICC events, T20 World Cup, ODI series. Basketball — NBA, EuroLeague. Tennis — ATP, WTA, Grand Slams. Formula 1 (F1). UFC / MMA. WWE. Rugby — Six Nations, World Cup. Ice Hockey — NHL. And more — depends on what's live at any given time.

### Do I need a VPN?

It depends on your region and the source. Some streams may be geo-restricted. A VPN can help if a source blocks your region.

### Why does the video buffer or fail to load?

- **Source down** — the upstream CDN may be temporarily unavailable. Try switching servers (click a different server button below the player).
- **Geo-restricted** — some streams only work in certain countries. A VPN may help.
- **Network issues** — try lowering the quality if your connection is slow.
- **ISP blocking** — some ISPs block streaming CDNs. A VPN usually fixes this.

### Can I watch on my phone or TV?

Yes. Open `http://<your-pc-ip>:9090` on any device connected to the same local network. You can also use the M3U URLs in VLC or any media player app.

### How do I use the M3U URLs in VLC?

1. Copy the M3U URL from an event card (click the **M3U** button)
2. Open VLC → **Media** → **Open Network Stream**
3. Paste the URL and click **Play**

Or on mobile: copy the URL, open VLC, tap the three dots → **Streams** → paste.

### What's the difference between `/watch` and `/lite`?

- `/watch/<slug>` — full custom player with 11 themes, custom SVG controls, speed control, and keyboard shortcuts.
- `/lite/<slug>` — minimal player using native browser controls. Lighter, works everywhere.

### How does the auto-fallback work?

When a stream fails (CDN error, timeout, etc.), the player automatically tries the next available server for that event. You'll see a brief spinner and then playback resumes on the new server. No manual intervention needed.

### How do I update ZeroLive?

- **Installer version**: Open settings (gear icon) → **Check for Updates** → **Apply**
- **Manual version**: `git pull origin master`, then restart

### Does it work on Mac/Linux?

Yes. The manual install works on any OS with Python 3.10+. The installer is Windows-only, but you can run the same commands manually.

### What ports does it use?

Default is `9090`. You can change it via the `PORT` environment variable or by passing a port number to `python app.py <port>`.

### Is my data private?

Yes. ZeroLive runs entirely on your local machine. No data is sent to any external server except the upstream stream sources. There's no telemetry, no analytics, no tracking.

---

## Issues & Contact

For bug reports, feature requests, or help: **milonmartsupershop@gmail.com**

---

## License

Open source — use however you like.

---

## Official Download Mirrors

| Mirror | URL |
|---|---|
| GitHub | https://github.com/rafu-milonmart/Zerolive/releases |
| ZeroLive (Primary) | https://zerolive.iceiy.com/ |
| ZeroLive (Alt) | https://zerolive.page.gd/ |
| Netlify | https://bejewelled-fenglisu-31730c.netlify.app/ |
| TinyURL | https://tinyurl.com/Zero-live-sports |
