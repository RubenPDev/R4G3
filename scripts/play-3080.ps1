# vi-3080: VIctory-NVIDIA tuned for an RTX 3080 10 GB (Ampere: DLSS yes, DLSS frame generation no),
# an 8-core Ryzen 7 9800X3D and 32 GB of RAM. Everything goes on to play-foxhound.ps1 (its options are at its top).
#
#   .\scripts\play-3080.ps1                       Series X, 2560x1440 output, DLSS Balanced, no frame rate cap
#   .\scripts\play-3080.ps1 -Dlss quality         sharper, slower (also: performance, dlaa, off)
#   .\scripts\play-3080.ps1 -SeriesS              the Series S profile (1280x720 inside): fastest
#   .\scripts\play-3080.ps1 -More @{VICTORY_THIN='0'}   override any switch (several: @{A='1'; B='0'})
#
# What it changes over play-foxhound.ps1's defaults, and why:
# - Frame generation is never made ready: the RTX 30 series has no DLSS frame generation, and "ready but off"
#   holds back part of the card's 10 GB from textures (VICTORY_TEXTURE_ROOM_PERCENT 86).
# - VICTORY_CARD_WINDOWS_MB=1024: the title's allocator reads (vertices, indices, constants) from the card's
#   memory instead of over PCIe. The default on a 10 GB card is 9 % of its budget (~765 MB); 1024 is what moved
#   an RTX 4070 SUPER's gameplay from 3 to 21-25 fps (shadow.rs). Windows still only go to the card while a
#   fifth of its budget is free, so textures keep their room.
# - VICTORY_DSTORAGE_IO=direct: game files are read past Windows' file cache, which otherwise holds gigabytes of
#   a 32 GB PC's RAM (Vice-Tay's 16 GB preset; less paging, fewer hitches).
# - VICTORY_FILL_TITLE=1: the title's small writes of constants into its heap no longer wait for every flight's
#   copy-back (host.rs: ~30 ms of a 130 ms frame there). Measured here: 41 -> 28 ms a frame waiting for the GPU,
#   about 12 -> 15-20 fps.
# - -TextureCap 2048 (VICTORY_TEXTURE_MAX_DIM, vi-3080 on the held-levels base, after Evan-Lowry's cap in
#   klbf-lab): a full card turned new textures away ~54,000 times in a few minutes of driving (black textures,
#   pop-in, U-turn stalls). World textures over 2048 start one level down; menus and screen images stay whole.
# - VICTORY_COPIES_IN_PLACE=0: the title's buffer copies go at submission again, where the card steps can do
#   them behind the flights; in place, a read of their destination waited for every flight (10-25 ms a frame
#   here, all of the "title memory read" settles). Measured: 28-48 -> 2-4 ms a frame waiting for the GPU.
# - The ray-tracing-only skinning passes are left out in the layer itself (pipeline/make.rs, vi-3080):
#   VICTORY_RT_SKIN=1 runs them again; VICTORY_SKIP_RT_HAIR=1 also leaves out the ray-tracing hair geometry.
# - A barrier on every shader write that would follow the last one with nothing recorded between them is left
#   out in the layer itself (list.rs, vi-3080: it orders nothing more); VICTORY_BARRIER_ELIDE=0 records them all.
param(
    [ValidateSet('off', 'dlaa', 'quality', 'balanced', 'performance')][string]$Dlss = 'balanced',
    [ValidateSet('1440', '1080to1440', '4k')][string]$Res = '1440',
    [switch]$SeriesS,
    [ValidateRange(1, 1000)][int]$Fps = 1000,
    [ValidateSet('release', 'diag')][string]$Build = 'release',
    # Largest side of a block-compressed world texture on the card (0: no cap). 2048 keeps them sharp at 1440p and
    # cuts a 4096x4096 one to a quarter of its memory; 1024 for even more room.
    [ValidateSet(0, 1024, 2048, 4096)][int]$TextureCap = 2048,
    [string]$Exe = '',
    [hashtable]$More = @{}
)
$repo = Split-Path $PSScriptRoot -Parent
if (-not $Exe) {
    # The title's executable in game_dir of victory.toml.
    $toml = Join-Path $repo 'victory.toml'
    $line = if (Test-Path $toml) { Get-Content $toml | Where-Object { $_ -match "^\s*game_dir\s*=\s*'(.+)'\s*$" } | Select-Object -First 1 }
    if (-not $line) { Write-Host "No game_dir in ${toml}: pass -Exe <path of game_scarlett_master.exe>."; return }
    $null = $line -match "^\s*game_dir\s*=\s*'(.+)'\s*$"
    $Exe = Join-Path $Matches[1] 'game_scarlett_master.exe'
}
$settings = @{
    VICTORY_CARD_WINDOWS_MB = '1024'
    VICTORY_DSTORAGE_IO = 'direct'
    VICTORY_FILL_TITLE = '1'
    VICTORY_COPIES_IN_PLACE = '0'
}
if ($TextureCap -gt 0) { $settings.VICTORY_TEXTURE_MAX_DIM = [string]$TextureCap }
foreach ($k in $More.Keys) { $settings[$k] = $More[$k] }
$opts = @{ Exe = $Exe; Dlss = $Dlss; Res = $Res; Fps = $Fps; Build = $Build; NoFrameGenReady = $true; More = $settings }
if ($SeriesS) { $opts.SeriesS = $true }
& (Join-Path $PSScriptRoot 'play-foxhound.ps1') @opts
