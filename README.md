# vi-3080: R4GE tuned for an RTX 3080

This branch (`vi-3080`) is a fork of
[trustno1-coder/VIctory-NVIDIA](https://github.com/trustno1-coder/VIctory-NVIDIA),
a compatibility layer that runs the title's Xbox Series build natively on
Windows from files **you** supply. It is tuned for an **RTX 3080 10 GB, a Ryzen 7
9800X3D and 32 GB of RAM**, with the Series X profile at 2560x1440 and DLSS,
and it should suit other RTX 30 cards too.

> **This repository contains no game files, code or assets.** You need your own
> legally obtained dump of the title's Xbox Series build v1.0.2.1. This project
> is not affiliated with or endorsed by the title's developer or publisher, nor
> by NVIDIA. See [docs/asset-policy.md](docs/asset-policy.md).

The upstream README follows further down, under
[VIctory on NVIDIA](#victory-on-nvidia).

## Contents

- [What you need](#what-you-need)
- [First-time setup](#first-time-setup)
- [Playing](#playing)
- [Making the stutter go away (warming up)](#making-the-stutter-go-away-warming-up)
- [Launcher options](#launcher-options)
- [What vi-3080 changes, and why](#what-vi-3080-changes-and-why)
- [How it runs](#how-it-runs)
- [Troubleshooting](#troubleshooting)
- [Updating](#updating)
- [Credits and license](#credits-and-license-vi-3080)

## What you need

- Windows 10 or 11 (x64) and a CPU with AVX2.
- 32 GB of RAM or more, and an SSD.
- An NVIDIA GeForce RTX card with a recent driver. It was tuned on an RTX
  3080 10 GB.
- **Your own dump** of the title's Xbox Series build **v1.0.2.1**: the folder
  with `game_scarlett_master.exe`. Keep it outside this repository.
- Git, Rust and the Visual Studio C++ Build Tools. The setup script installs
  any that are missing, using `winget`.
- A controller is recommended: an Xbox-style pad (an 8BitDo Ultimate worked
  here).

## First-time setup

Open a **normal** PowerShell window, not as administrator, and run:

```powershell
git clone --branch vi-3080 <this repository's URL> "$HOME\VI-3080"
cd "$HOME\VI-3080"
powershell -ExecutionPolicy Bypass -File scripts\setup-3080.ps1 -GameDir 'D:\XboxGames\GameFiles'
```

The repository's URL is under the green **Code** button on GitHub. Replace
`D:\XboxGames\GameFiles` with the folder of your own dump; subfolders are
searched for `game_scarlett_master.exe`.

`setup-3080.ps1` skips any step that's already done, so it's safe to run
again. It does six things:

1. Checks the PC and finds the game.
2. Installs Git, Rust and the C++ Build Tools if they are missing.
3. Writes `victory.toml` (git-ignored), with your game folder and a cache and
   saves folder outside the repository (default `%USERPROFILE%\vi-3080-data`).
4. Downloads NVIDIA's DLSS files from NVIDIA's own GitHub into `nvidia-sdk\`
   (git-ignored, about 70 MB). It also gets the DLSS SDK's `nvngx_dlssd.dll`,
   which avoids a crash at start on RTX 30 cards.
5. Builds the layer into `target\release\victory.exe`. This takes 5–15 minutes
   the first time.
6. With `-Play`, starts the game.

| Setup option | What |
|---|---|
| `-GameDir <folder>` | your dump's folder (required) |
| `-DataRoot <folder>` | where the cache and saves go (default `%USERPROFILE%\vi-3080-data`) |
| `-Force` | write a new `victory.toml` over the existing one |
| `-NoDlssdFix` | don't add the DLSS SDK's `nvngx_dlssd.dll` |
| `-Play` | start the game when setup is done |

<details>
<summary>Setting up by hand instead</summary>

```powershell
git clone --branch vi-3080 <this repository's URL> "$HOME\VI-3080"
cd "$HOME\VI-3080"
copy victory.example.toml victory.toml   # set game_dir, cache_dir and data_dir: all outside this folder
.\Get-NVIDIA-DLSS.cmd                     # NVIDIA's files into nvidia-sdk\ (about 70 MB)
# RTX 30 only, if DLSS crashes at start: put the DLSS SDK's copy beside the others
Invoke-WebRequest 'https://github.com/NVIDIA/DLSS/raw/main/lib/Windows_x86_64/rel/nvngx_dlssd.dll' -OutFile nvidia-sdk\Streamline\bin\x64\nvngx_dlssd.dll
rustup toolchain install
cargo build --release --locked -p victory
```

</details>

## Playing

From the repository's folder, in a normal PowerShell window:

```powershell
cd "$HOME\VI-3080"
powershell -ExecutionPolicy Bypass -File scripts\play-3080.ps1
```

This runs the Series X profile at 2560x1440 with DLSS Balanced and no frame
rate cap.

| Key | What |
|---|---|
| **F1** | settings menu (arrow keys pick and change, Enter applies). Leave its *frame generation* item alone: that's NVIDIA's, and it needs an RTX 40 or newer |
| **F3** | stats panel: frame rate, draws, GPU and memory numbers |
| close the window | quit |

- **Full screen.** Start the game, then run this in a second PowerShell window:
  `powershell -ExecutionPolicy Bypass -File scripts\fullscreen.ps1`.
- **Saves** go to the `data_dir` in `victory.toml`, which setup puts at
  `%USERPROFILE%\vi-3080-data\data`.
- **Logs** go to `%LOCALAPPDATA%\victory\logs\foxhound-*.log`. Every few
  seconds they record the frame rate and what the time went into.
- **Settings from the F1 menu** are saved in `victory-settings.txt` and
  applied at every start, over the launcher's options. Delete that file to go
  back to the defaults.

## Making the stutter go away (warming up)

The first sessions with a new build stutter, and can drop to 1 fps when new
places appear, while the NVIDIA driver compiles the game's pipelines. The
launcher writes down every pipeline the game makes. After a session or two,
build them all ahead of time:

```powershell
cd "$HOME\VI-3080"
$env:VICTORY_HOST_WAVE = '32'
target\release\victory.exe warm
```

This can take a long time, because there are tens of thousands of pipelines.
Do it again after every rebuild, after a driver update, or if you move the
folder: the driver keeps its pipelines per program path.

## Launcher options

Add these to the `play-3080.ps1` command line, for example
`... scripts\play-3080.ps1 -Dlss performance`.

| Option | Default | What |
|---|---|---|
| `-Dlss balanced` / `quality` / `performance` / `dlaa` / `off` | `balanced` | DLSS mode; `off` uses the title's own upscaling |
| `-TextureCap 2048` / `4096` / `1024` / `0` | `2048` | largest side of a block-compressed world texture on the card; `1024` frees more video memory, `0` means no cap |
| `-Res 1440` / `1080to1440` / `4k` | `1440` | output size (the image is patched for 1440p) |
| `-SeriesS` | off | the Series S profile: 1280x720 inside, softer |
| `-Fps 30` / `60` | `1000` (uncapped) | frame rate cap |
| `-Exe <path>` | from `victory.toml` | the title's `game_scarlett_master.exe` |
| `-Build diag` | `release` | the diagnostics build, which must be built first (see below). Slower, but has timelines and GPU timing |
| `-More @{VICTORY_X='1'}` | | add or override any `VICTORY_...` switch (several: `@{A='1'; B='0'}`) |

These switches are worth knowing for `-More`:

| Switch | What |
|---|---|
| `VICTORY_THIN_THREADS='12'` | 12 threads translate the game's graphics commands instead of 8. Measured: batches of draws waited 8 ms for a thread instead of 11 |
| `VICTORY_RT_SKIN='1'` | run the ray-tracing-only skinning passes again (left out by default) |
| `VICTORY_SKIP_RT_HAIR='1'` | also leave out the ray-tracing-only hair geometry |
| `VICTORY_BARRIER_ELIDE='0'` | record every redundant "wait for earlier shader writes" step |

To build the diagnostics build (10–15 minutes):

```powershell
cargo build --locked --profile diag -p victory --features diagnostics
```

Every `VICTORY_...` switch is described in a comment where the code reads it,
and the full launcher set is in `scripts/play-foxhound.ps1`.

## What vi-3080 changes, and why

All measurements were taken on the RTX 3080 10 GB, Ryzen 7 9800X3D and 32 GB
PC this was tuned on.

**Launcher defaults (`scripts/play-3080.ps1`).** Everything goes on to
`play-foxhound.ps1`.

- **DLSS Balanced, no frame rate cap.**
- **NVIDIA frame generation is never made ready.** RTX 30 cards don't have
  it, and keeping it ready holds back part of the card's 10 GB from textures.
- **`VICTORY_CARD_WINDOWS_MB=1024`.** The title's vertex, index and constant
  data is read from video memory instead of over PCIe.
- **`VICTORY_DSTORAGE_IO=direct`.** Game files are read past Windows' file
  cache, which uses less RAM and causes fewer hitches.
- **`VICTORY_FILL_TITLE=1`.** The title's small writes of constants no longer
  wait for the GPU to finish earlier work. Measured: 12 → 15–20 fps.
- **`VICTORY_COPIES_IN_PLACE=0`.** The title's buffer copies are done at
  submission, behind work already on the GPU. Measured: time waiting for the
  GPU dropped from 28–48 to 2–4 ms a frame.
- **`-TextureCap 2048`.** A full card had been refusing new textures tens of
  thousands of times in a few minutes of driving (black textures, pop-in,
  stalls on U-turns). World textures larger than 2048 now start one mip level
  down; menus and screen images stay whole.

**Layer (`crates/victory-gpu`).**

- **Ray-tracing-only skinning left out** (`pipeline/make.rs`). These passes
  only feed ray-tracing structures, and the structure builder is off. VI-BR-PORT
  measured 6.8 → 10.9 fps from this alone on an RTX 4060 Ti.
- **The texture cap** (`resource.rs`, `descriptor/host.rs`), built on the
  layer's held mip levels.
- **Redundant waits left out** (`list.rs`, `host.rs`). A "wait for earlier
  shader writes" step is dropped when nothing was recorded since the last one.
- **More numbers in the log** (`draw.rs`, `list/thin.rs`, `host.rs`). Lines
  starting with `vi-3080` show where the CPU time goes:
  - the steps of indirect draws
  - the parts of binding
  - how long batches of draws wait to be translated
  - how many waits were recorded or left out

**RTX 30 DLSS workaround.** The driver's built-in `nvngx_dlssd.dll` 310.9.0
crashed NVIDIA's NGX at start on the RTX 3080 (`0xC0000005`). The DLSS SDK's
copy beside the Streamline files fixes it, and the setup script adds it.

## How it runs

On the RTX 3080 10 GB, Ryzen 7 9800X3D and 32 GB PC, Series X profile at
1440p with DLSS Balanced:

- **About 15–23 fps.** It reaches the mid-20s on open roads and drops to about
  13 in dense downtown traffic.
- **The graphics card is the limit.** The game's own draws take about 45 ms
  of GPU time a frame, spread over roughly 12,000 small draws. Leaving out all
  ~750 "wait" steps per frame barely changed that (GPU about 84% → 80% busy).
  DLSS Performance doesn't help either, because most of that time doesn't
  depend on resolution.
- **There is no real ray tracing.** The title's ray-tracing passes are left
  out, and the layer estimates indirect light and reflections instead. Night
  scenes hide most of the difference; inside buildings it shows more.
- **Known issues:**
  - stutter until pipelines are warmed up
  - occasional drops when new areas load
  - some odd or pink textures
  - visual artifacts here and there
- **Frame generation.** NVIDIA's needs an RTX 40 or newer. An AMD FSR frame
  generation port was tried on this branch and rolled back; it isn't included.

## Troubleshooting

| Problem | What to do |
|---|---|
| "running scripts is disabled on this system" | start scripts the way shown above: `powershell -ExecutionPolicy Bypass -File ...` |
| `No game_dir in victory.toml` | run `setup-3080.ps1`, or pass `-Exe <path of game_scarlett_master.exe>` |
| the game crashes at start, with NGX or `0xC0000005` in the log | the RTX 30 DLSS workaround above, or play with `-Dlss off` |
| heavy stutter, 1 fps moments | warm up the pipelines (above); the first session after every build is slow |
| black or missing textures, pop-in | `-TextureCap 1024` |
| everything stutters and the shader cache seems to be ignored | don't run PowerShell as administrator: the driver keeps its cache per user |
| asking for help | attach the newest `%LOCALAPPDATA%\victory\logs\foxhound-*.log` |

## Updating

```powershell
cd "$HOME\VI-3080"
git pull
cargo build --release --locked -p victory
```

Then warm up the pipelines again (see above).

## Credits and license (vi-3080)

- **[trustno1-coder/VIctory-NVIDIA](https://github.com/trustno1-coder/VIctory-NVIDIA)**
  is the base, and through it foxhound, VIctory and the projects credited
  below.
- **[PastiiJay/klbf-lab](https://github.com/PastiiJay/klbf-lab)** for the idea
  of capping textures (after Evan-Lowry's cap there).
- **[edsuuu/VI-BR-PORT](https://github.com/edsuuu/VI-BR-PORT)** for the
  measurement on ray-tracing-only skinning.
- **[TaynanGT/Vice-Tay](https://github.com/TaynanGT/Vice-Tay)** for the 16 GB
  preset's file-reading setting and the DLSS SDK workaround.
- The vi-3080 changes were written with
  [Claude](https://claude.com/claude-code).
- **License:** GPL-3.0-or-later, as the projects it comes from. See
  [LICENSE](LICENSE). NVIDIA's Streamline and DLSS files are NVIDIA's; they
  are downloaded from NVIDIA and are not part of this repository.

---

# VIctory on NVIDIA

## Quick start: how to run it

**The easy way: one file, nothing to build**

1. Download `victory.exe` from the
   [latest release](https://github.com/trustno1-coder/VIctory-NVIDIA/releases/latest).
2. Put it into the folder of **your own dump** of the title's Xbox Series
   build v1.0.2.1, next to `game_scarlett_master.exe`.
3. Double-click it. Windows may say the publisher is unknown (the file is not
   signed): "More info", then "Run anyway".

- The first start asks once whether to download NVIDIA's DLSS and frame
  generation files (about 70 MB) from NVIDIA's own GitHub. They are NVIDIA's
  and are not part of this program; say no and the game still runs, with its
  own upscaling and no frame generation.
- Nothing is written into your game folder: settings, saves, caches, logs and
  NVIDIA's files are kept under `%LOCALAPPDATA%\victory`.
- You need Windows 10 or 11, 32 GB of RAM or more, an SSD and an NVIDIA
  GeForce RTX card with a recent driver. This repository and its releases
  contain no game files.

**In the game**

- **F1** brings up the settings menu (arrow keys pick and change, Enter does
  it): DLSS, frame generation, frame rate cap and more.
- **F3** shows the stats panel (frame rate, frame generation, draws, GPU and
  memory numbers).

**Building it yourself instead**

Install [Rust](https://rustup.rs) and the
[Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
with "Desktop development with C++", then in PowerShell:

```powershell
git clone https://github.com/trustno1-coder/VIctory-NVIDIA
cd VIctory-NVIDIA
.\Get-NVIDIA-DLSS.cmd
powershell -ExecutionPolicy Bypass -File scripts\play-nvidia.ps1 -Exe 'D:\Games\MyDump\game_scarlett_master.exe'
```

Put the path to **your** `game_scarlett_master.exe` in the last line. The
first start builds the layer, which takes a few minutes.

Options, requirements in full and the details are under
[How to run it](#how-to-run-it).

A fork of [VIctory](https://github.com/Marvisak/VIctory), a compatibility layer
that runs an Xbox Series title natively on Windows from files **you** supply,
tuned for **NVIDIA RTX** cards.

> **This repository contains no game files, code or assets.** You need your
> own legally obtained copy of the title. It is not affiliated with or endorsed
> by the title's developer or publisher, nor by NVIDIA. See
> [docs/asset-policy.md](docs/asset-policy.md).

## Built from many projects, and from running every one of them

This repository did not come from one place, and the base it stands on today
is the end of a long comparison, not the start of the work. Over several weeks
we built, ran and measured many projects on the same NVIDIA PC: Leonida,
[Marvisak's VIctory](https://github.com/Marvisak/VIctory),
[fxceless's fork](https://github.com/fxceless/victory-fork),
[the 7900 XTX fork](https://github.com/avatarmanz/VIctory-7900XTX),
[Belobug's](https://github.com/Belobug/VIctory-Belobug-AMD),
[DexNom's](https://github.com/DexNom/VIctory),
[CGBJ's cool_fox](https://github.com/codec-d/cool_fox), Kelvaroq's, Neptune,
xcl (another layer for the same title) and then
[foxhound](https://github.com/readmet3xt-lab/foxhound). On each we found what
stopped it on an RTX card, fixed or worked around it, measured the result, and
carried what we learned to the next. Every pull request sent here was built
and run on the same card before it was merged. No single project got here
alone, and choosing the base that runs best was only one result of that work.

### What this fork brings

Not one fix but a long line of them: days of work, much of it around the clock,
across every one of those codebases, more than 300 measured runs on the same
RTX PC, and each fault chased towards its cause before the next build. In rendering, in
speed, in the picture and in simply being able to play it:

**Rendering fixes**

- **Draws no longer skipped on NVIDIA.** NVIDIA caps the view heap below what
  the title asks for; thousands of draws a frame were dropped, the screen
  rarely updated and the character jumped from place to place. The pool of
  descriptor slots was reworked until almost none were.
- **Menus, loading screens and subtitles on Series S**, black until then (the
  interface plane laid over the game), and **faces that move** (their network
  carried through as integers): ported from fxceless's pull requests 1189 and
  927 and made to work on this card.
- **The intro video without flicker**: its frames came out of order.
- **Black blobs gone**: a single bad number from a shader, spread by blur and
  the upscaler into patches on faces and in the air, is caught where it is
  written.
- **White, hazy rooms explained and tamed**: the title's ray tracing was
  running with its structure builder off, so every ray missed. Which passes
  can be left out without filling the picture with rainbow glitter was worked
  out pass by pass.
- **The ray-tracing structure builder running on NVIDIA**, on CGBJ's renderer:
  the draws dropped for it went from thousands a frame to one.
- **White-outs with black holes further into the game** followed up in frames
  captured in play: thousands of draws a frame were being dropped there for
  that same missing structure.

**Speed**

- **Memory compares moved to the card**: 11 to about 22 frames a second on the
  base of the time.
- **Settings measured, not guessed**: one switch at a time, on the same scene,
  run after run.
- **The base itself chosen by measurement**: the same rooms went from 15-17
  frames a second to 26-30, at a higher resolution.
- **The 30 frames a second were the title's own frame interval**, not the
  layer's limit: found, and lifted.

**Picture and frames**

- **DLSS in place of the title's upscaler**, with its model and mode to choose.
- **DLSS frame generation with up to six frames shown for each one rendered**,
  switched and changed while playing, without a restart (foxhound's is 2x, set
  at the start). By Streamline's own count it shows exactly 2, 4 and 6.
- **Why frame generation showed nothing on a full 12 GB card**, found and
  fixed: the card's memory is now shared out so that it has room.
- **The frame rate at the top left of the picture**: frames rendered a second
  and, with frame generation, frames shown (`FPS: 28.4  FG: 170.4`).

**Playing it**

- **The F1 settings menu**, in every build: DLSS, frame generation, frame rate
  cap, console profile, picture size, the light estimates and the main speed
  switches, saved to `victory-settings.txt` and applied at the next start
  ("SAVE AND RESTART NOW" does that for you; lines marked LIVE change at once).
- **The F3 stats panel**, in every build: frame rate and frame time, frames
  shown with frame generation, draws, how busy the GPU and the submitting
  thread are, copies, RAM and VRAM. The menu switches it too.
- **Open water without dark blocks.** Two of the title's water light programs
  run on 32-lane cards only in a form that left whole tiles of the sea dark
  (around boats, along shores, under bridges) and cost about 15 ms of the
  card a frame. They are left out there: no blocks and 30 fps instead of 25
  on the first boat ride (RTX 5070), with water that is darker and bluer.
  WATER LIGHT in the menu (`VICTORY_WATER_LIGHT=1`) runs them again.
- **One command to play**: the launcher builds the layer the first time and
  applies what the menu saved.
- **`Get-NVIDIA-DLSS.cmd`**: the eight NVIDIA files that are loaded, about
  70 MB, taken out of NVIDIA's 263 MB release without downloading the rest.
  NVIDIA's licence does not let a repository carry them, so they come from
  NVIDIA.

**Tested, not assumed**

- Every pull request sent here was read line by line and, where it touched the
  game, built and run on this card before it was merged: ten so far.

Where each of these is today: this fork's own code in this tree is the F1
menu, the stats panel in every build, the water light switch, frame
generation from 2x to 6x with its live switching and memory handling, the
lifted frame rate cap, the frame rate line, the launcher and the NVIDIA file
fetcher. The foxhound line carries the descriptor slots, the
compares on the card, the interface plane and the face network in its own
form. The black-blob scrub, the graphics card picker and the ray-tracing
builder path are in this repository's history, and come over as this base
turns out to need them.

### The base since 2026-11-26: foxhound

On 2026-11-26 this fork moved onto
[readmet3xt-lab/foxhound](https://github.com/readmet3xt-lab/foxhound)
(`02fc18a`, GPL-3.0-or-later). On the same PC it ran the same rooms at close to
twice the frame rate of what this fork had, at a higher resolution, so its
tree is now this one's, with its history kept, and this fork's own additions
are on top. What foxhound is and how it got there is in its own README, kept as
[docs/README-foxhound.md](docs/README-foxhound.md); its measurements are in
[docs/findings.md](docs/findings.md).

What foxhound brings:

- the Series X profile at a native 2560x1440;
- DLSS Super Resolution and DLSS Frame Generation through NVIDIA Streamline,
  loaded when the game runs (nothing of NVIDIA's is needed to build);
- an estimate of indirect light and of reflections in place of the title's ray
  tracing, and fewer stalls at scene cuts.

What this fork has on top of it is under
[What this fork brings](#what-this-fork-brings) above.

## Where it stands

Tested on one PC: Windows 11, Ryzen 7 9800X3D, 64 GB RAM, **GeForce RTX 5070
12 GB**; the title's Xbox Series build v1.0.2.1, Series X profile, 2560x1440
output, DLSS Quality. Frame rates are the layer's own count, in the opening
rooms.

| | |
|---|---|
| Opening rooms | mostly 26-30 frames a second rendered (33-38 ms a frame) |
| Frame generation | 2x to 6x on top of that: by Streamline's own count, exactly 2, 4 and 6 frames shown for each one rendered |
| Device losses, crashes | none in the measured runs |
| Before this base (Series S, 720p to 1080p by DLSS) | 15-17 frames a second in the same rooms |

foxhound's own measurements, on an RTX 4070 SUPER, are in its README.

What is known to be wrong:

- **No ray tracing.** The title's own is off (`VICTORY_BVH_BUILDER=1`, or the
  menu's RAY TRACING, turns it on: slow and with a broken picture on this
  base). An estimate stands in for indirect light and reflections.
- **Frame generation needs room in the card's memory.** The layer fills the
  card with textures up to its budget; with frame generation on from the start
  the launcher holds a fifth of the budget back (a little less while it is only
  ready), so a few more textures can come late. Switched on from the menu on a
  full 12 GB card it can still say that memory is past the budget; it then
  runs, perhaps unevenly.
- **Frames are only generated while the game's window has the focus**, and
  about a second passes after a change before they come.
- **The first run of every new build stutters** while the driver compiles
  pipelines (foxhound's README, *Warming up*, says how to make them ahead).
- "SAVE AND RESTART NOW" can leave the old game's process behind without a
  window; it goes when the PC restarts.
- What foxhound lists as wrong (the heat-haze pass left out, hitches in
  cutscenes) applies here too.

## How to run it

You need Windows 10 or 11 (x64), a CPU with AVX2, 32 GB of RAM or more, an
SSD, an NVIDIA GeForce RTX card with a recent driver (RTX 40 or later for frame
generation, with hardware-accelerated GPU scheduling on; more than 2x needs an
RTX 50), [Rust](https://rustup.rs) (the toolchain is pinned), the Visual Studio
Build Tools with "Desktop development with C++", and **your own dump** of the
title's Xbox Series build v1.0.2.1 (the folder with
`game_scarlett_master.exe`).

```powershell
git clone https://github.com/trustno1-coder/VIctory-NVIDIA
cd VIctory-NVIDIA
copy victory.example.toml victory.toml      # then set game_dir to your dump's folder, outside this one
.\Get-NVIDIA-DLSS.cmd                        # once: NVIDIA's DLSS and frame generation files, about 70 MB
scripts\play-nvidia.ps1 -Exe 'D:\Games\MyDump\game_scarlett_master.exe'
```

The first start builds the layer (a few minutes). `Get-NVIDIA-DLSS.cmd` gets
NVIDIA's files from
[NVIDIA-RTX/Streamline](https://github.com/NVIDIA-RTX/Streamline) into
`nvidia-sdk\` (git-ignored). They are NVIDIA's, under NVIDIA's licences, which
are saved beside them; this repository does not carry them and may not. Nothing
is downloaded unless you run that file; `VICTORY_STREAMLINE_DIR` names another
folder if you have the Streamline SDK already.

`scripts\play-nvidia.ps1` is `scripts\play-foxhound.ps1` under the name this
fork has always had; its options:

| Option | What |
|---|---|
| *(none)* | Series X profile, 2560x1440, DLSS Quality, no frame rate cap, frame generation ready but off |
| `-FrameGen`, `-FrameGenX 4` | frame generation on from the start, 2 to 6 frames shown for each one rendered |
| `-Dlss off` / `dlaa` / `balanced` / `performance` | the title's own upscaling, or another DLSS mode |
| `-Fps 60` | a frame rate cap (30 is the title's own) |
| `-SeriesS` | the Series S profile: 1280x720 inside, faster, softer |
| `-Res 1080to1440` / `4k` | scene at 1080p upscaled by the title / the stock 3840x2160 output |
| `-NoFrameGenReady` | frame generation only with `-FrameGen` (it is otherwise made ready at every start, so the menu can switch it) |
| `-Build diag` | the diagnostics build (slower; captures, timelines, recording time in the F3 panel) |
| `-More @{VICTORY_X='1'}` | add or override any switch |

What the F1 menu saved (`victory-settings.txt`) goes over these at every start;
delete that file to go back to them. Full screen: start the game, then run
`.\scripts\fullscreen.ps1` in another window. Logs go to
`%LOCALAPPDATA%\victory\logs`, saves to `%LOCALAPPDATA%\victory\data`.

## How it works, and the findings

- [docs/README-foxhound.md](docs/README-foxhound.md): foxhound's own README
  (set-up by hand, warming up, its switches).
- [docs/architecture.md](docs/architecture.md): the layer's parts.
- [docs/findings.md](docs/findings.md): measurements behind the choices.
- [docs/dlss.md](docs/dlss.md): DLSS and Frame Generation.
- [docs/fork-ray-tracing.md](docs/fork-ray-tracing.md): the title's ray tracing
  and the light estimate.
- [docs/asset-policy.md](docs/asset-policy.md): what may and may not be in this
  repository.

## Credits

A tree of other people's work with a little on top; the history is kept.

- **[foxhound](https://github.com/readmet3xt-lab/foxhound)** by
  readmet3xt-lab: the base of this fork since 2026-11-26, and through it:
- **[VIctory](https://github.com/Marvisak/VIctory)** by Marvisak and its
  contributors: the loader, the runtime services, the Direct3D 12 back end and
  the shader recompiler.
- **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)**,
  **[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX)**,
  **[codec-d/cool_fox](https://github.com/codec-d/cool_fox)**,
  **[DexNom/VIctory](https://github.com/DexNom/VIctory)**,
  **[Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)**
  and the others foxhound's README names.
- Everyone who sent pull requests to this fork before the move; that work is
  in the history, on the branch that was `main` until then.
- NVIDIA Streamline, DLSS and Reflex are NVIDIA's; they are loaded at run time
  from a folder you supply.
- Much of this fork's code was written with
  [Claude Code](https://claude.com/claude-code).

## License

GPL-3.0-or-later, as VIctory and foxhound. See [LICENSE](LICENSE); the one file
that is not covered is named in [docs/asset-policy.md](docs/asset-policy.md).
