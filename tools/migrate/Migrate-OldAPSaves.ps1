# Copies AP seed saves made before DRAP 1.2.0 into the game folder.
#
# Older versions saved each seed into Steam's store, as
#   Steam\userdata\<SteamID>\2527390\remote\win64_save_AP_<Slot>_s<Seed>
# Newer versions save to
#   <game folder>\AP_Saves\<Slot>_s<Seed>
# The files are the same; only the folder moved. This copies each old seed
# folder to its new place. It never deletes or moves the originals, and it
# skips any seed that already has saves in AP_Saves.
#
# Run it from the game folder (where DRDR.exe is), with the game closed.

$ErrorActionPreference = "Stop"
$GameDir = $PSScriptRoot

function Done($code) {
    Write-Host ""
    Read-Host "Press Enter to close"
    exit $code
}

if (-not (Test-Path (Join-Path $GameDir "DRDR.exe"))) {
    Write-Host "DRDR.exe is not in this folder:" -ForegroundColor Red
    Write-Host "  $GameDir"
    Write-Host "Put this file in the Dead Rising Deluxe Remaster install folder and run it again."
    Done 1
}

if (Get-Process -Name "DRDR" -ErrorAction SilentlyContinue) {
    Write-Host "Dead Rising is running. Close the game first, then run this again." -ForegroundColor Red
    Done 1
}

# Steam's own install folder holds userdata, even when the game is in another library.
$SteamDir = $null
try { $SteamDir = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name SteamPath).SteamPath } catch {}
if (-not $SteamDir) { $SteamDir = Join-Path ${env:ProgramFiles(x86)} "Steam" }
$SteamDir = $SteamDir -replace "/", "\"
$UserData = Join-Path $SteamDir "userdata"

if (-not (Test-Path $UserData)) {
    Write-Host "Could not find Steam's userdata folder at:" -ForegroundColor Red
    Write-Host "  $UserData"
    Done 1
}

$Prefix = "win64_save_AP_"
$Old = @(Get-ChildItem -Path $UserData -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName "2527390\remote" } |
    Where-Object { Test-Path $_ } |
    ForEach-Object { Get-ChildItem -Path $_ -Directory -Filter "$Prefix*" })

if ($Old.Count -eq 0) {
    Write-Host "No old AP saves found in Steam's store. Nothing to do." -ForegroundColor Green
    Done 0
}

$NewRoot = Join-Path $GameDir "AP_Saves"
New-Item -ItemType Directory -Path $NewRoot -Force | Out-Null

$copied = 0; $skipped = 0
foreach ($dir in $Old) {
    $name = $dir.Name.Substring($Prefix.Length)
    $dest = Join-Path $NewRoot $name
    $files = @(Get-ChildItem -Path $dir.FullName -File)
    if ($files.Count -eq 0) { continue }

    if ((Test-Path $dest) -and @(Get-ChildItem -Path $dest -File).Count -gt 0) {
        Write-Host "  skipped  $name  (already has saves in AP_Saves)" -ForegroundColor Yellow
        $skipped++
        continue
    }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item -Path (Join-Path $dir.FullName "*") -Destination $dest -Recurse
    Write-Host ("  copied   {0}  ({1} file(s))" -f $name, $files.Count) -ForegroundColor Green
    $copied++
}

Write-Host ""
Write-Host "$copied seed(s) copied, $skipped skipped."
Write-Host "The originals in Steam's store were left alone."
Done 0
