<# : batch launcher (this file is both a .bat and a PowerShell script)
@echo off
set "NOX_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText($env:NOX_SELF))"
exit /b
#>
# Nox OS - Windows updater.
# Downloads the latest Nox OS release from GitHub and installs it on the
# NOXBOOT partition of the external disk. Safe to run any time: it does
# nothing if the installed version is already the latest one.

$ErrorActionPreference = 'Stop'
$Repo    = 'LordZeroSama/Nox'
$Variant = 'perf'
$Label   = 'NOXBOOT'
$KeepFiles = @('nox-release.txt', 'Mettre-a-jour-Nox.bat')

function Stop-WithMessage([string]$message) {
    Write-Host ""
    Write-Host $message -ForegroundColor Red
    Read-Host "Entree pour fermer" | Out-Null
    exit 1
}

# ---- Administrator rights (needed to mount the ISO) ----------------------
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process -FilePath $env:NOX_SELF -Verb RunAs
    exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
Write-Host "=== Nox OS - mise a jour ===" -ForegroundColor Cyan

# ---- 1. Find the Nox disk --------------------------------------------------
$volume = Get-Volume | Where-Object { $_.FileSystemLabel -eq $Label -and $_.DriveLetter } | Select-Object -First 1
if (-not $volume) {
    Stop-WithMessage "Disque Nox introuvable : branche le disque externe (partition '$Label') et relance."
}
$target = "$($volume.DriveLetter):\"
$versionFile = Join-Path $target 'nox-release.txt'
$installed = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { '(inconnue)' }
Write-Host "Disque Nox      : $target"
Write-Host "Version actuelle: $installed"

# ---- 2. Latest release on GitHub --------------------------------------------
try {
    $releases = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases?per_page=20" -Headers @{ 'User-Agent' = 'nox-updater' }
} catch {
    Stop-WithMessage "Impossible de contacter GitHub. Verifie ta connexion Internet."
}
$release = $releases | Where-Object { $_.tag_name -like "$Variant-*" -and -not $_.draft } | Select-Object -First 1
if (-not $release) { Stop-WithMessage "Aucune version '$Variant' publiee pour l'instant." }
Write-Host "Derniere version: $($release.tag_name)"

if ($release.tag_name -eq $installed) {
    Write-Host ""
    Write-Host "Nox OS est deja a jour." -ForegroundColor Green
    Read-Host "Entree pour fermer" | Out-Null
    exit 0
}

$parts = @($release.assets | Where-Object { $_.name -like '*.iso.part*' } | Sort-Object name)
$shaAsset = $release.assets | Where-Object { $_.name -like '*.iso.sha256' } | Select-Object -First 1
if ($parts.Count -eq 0 -or -not $shaAsset) { Stop-WithMessage "Release incomplete sur GitHub." }
$isoName = $shaAsset.name -replace '\.sha256$', ''
$totalBytes = ($parts | Measure-Object -Property size -Sum).Sum
$sizeGb = [math]::Round($totalBytes / 1GB, 2)

Write-Host ""
Write-Host "Le contenu de $target va etre remplace par la nouvelle version ($sizeGb Go a telecharger)."
Write-Host "Tes jeux et reglages (partition NOXHOME) ne sont pas touches."
$answer = Read-Host "Continuer ? (O/N)"
if ($answer -notmatch '^[oOyY]') { exit 0 }

# ---- 3. Working folder on the internal drive with the most free space ------
$work = Get-Volume |
    Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -and $_.DriveLetter -ne $volume.DriveLetter } |
    Sort-Object SizeRemaining -Descending | Select-Object -First 1
if (-not $work -or $work.SizeRemaining -lt ($totalBytes * 2 + 500MB)) {
    Stop-WithMessage "Pas assez d'espace libre pour le telechargement (il faut environ $([math]::Round($totalBytes * 2 / 1GB, 1)) Go)."
}
$workDir = "$($work.DriveLetter):\NoxUpdate"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
Write-Host "Dossier temporaire : $workDir"

# ---- 4. Download (resumable: relaunch the script if the connection drops) --
foreach ($part in $parts) {
    $file = Join-Path $workDir $part.name
    if ((Test-Path $file) -and ((Get-Item $file).Length -eq $part.size)) {
        Write-Host "Deja telecharge : $($part.name)"
        continue
    }
    Write-Host "Telechargement de $($part.name) ($([math]::Round($part.size / 1MB)) Mo)..."
    & curl.exe -L --fail -C - --retry 5 -o $file $part.browser_download_url
    if ($LASTEXITCODE -ne 0) { Stop-WithMessage "Telechargement interrompu. Relance le script pour reprendre." }
}
$expectedSha = ((& curl.exe -L -s --fail $shaAsset.browser_download_url) | Out-String).Trim().ToLower()

# ---- 5. Join the parts and check the ISO -----------------------------------
$iso = Join-Path $workDir $isoName
Write-Host "Assemblage de l'ISO..."
$output = [IO.File]::Create($iso)
try {
    foreach ($part in $parts) {
        $partStream = [IO.File]::OpenRead((Join-Path $workDir $part.name))
        try { $partStream.CopyTo($output) } finally { $partStream.Dispose() }
    }
} finally { $output.Dispose() }

Write-Host "Verification de l'integrite (SHA-256)..."
$actualSha = (Get-FileHash -Algorithm SHA256 $iso).Hash.ToLower()
if ($actualSha -ne $expectedSha) {
    Remove-Item -Force $iso, (Join-Path $workDir '*.part*')
    Stop-WithMessage "Fichier corrompu. Les fichiers ont ete supprimes : relance le script."
}

# ---- 6. Mount the ISO and copy it to the Nox disk --------------------------
Write-Host "Copie vers $target (quelques minutes, ne debranche pas le disque)..."
$image = Mount-DiskImage -ImagePath $iso -PassThru
try {
    $isoLetter = ($image | Get-Volume).DriveLetter
    $excludes = @('/XF') + $KeepFiles + @('/XD', 'System Volume Information')
    & robocopy.exe "$($isoLetter):\" $target /MIR /FFT /R:2 /W:2 /NFL /NDL /NP @excludes | Out-Host
    if ($LASTEXITCODE -ge 8) { throw "robocopy a echoue (code $LASTEXITCODE)" }
} finally {
    Dismount-DiskImage -ImagePath $iso | Out-Null
}
Set-Content -Path $versionFile -Value $release.tag_name -Encoding ASCII

# ---- 7. Clean up -------------------------------------------------------------
Remove-Item -Recurse -Force $workDir
Write-Host ""
Write-Host "Nox OS $($release.tag_name) installe sur $target." -ForegroundColor Green
Write-Host "Redemarre le PC, appuie sur Echap et choisis 'UEFI OS (ANKEJE...)'."
Read-Host "Entree pour fermer" | Out-Null
