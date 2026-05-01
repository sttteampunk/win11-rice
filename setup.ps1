# =====================================================================
# WINDOWS RICING INTERACTIVE DEPLOYMENT
# Run as Administrator (Required for Symlinks & Nilesoft)
# =====================================================================

$global:DetectedApps = @()
$global:DefaultDotfilesDir = "$HOME\Dotfiles"
$global:DryRun = $false

# --- SYMLINK MAPPING (The Brains of the Operation) ---
# Format: Name, App (for detection), Target (where it lives in Windows), Source (folder in your dotfiles repo)
$global:SymlinkMap = @(
    @{ Name="Komorebi";        App="komorebic";     InstallCheck=$null;                                                           Target="$HOME\komorebi.json";                                         Source="komorebi\komorebi.json" }
    @{ Name="Whkd";            App="whkd";           InstallCheck=$null;                                                           Target="$HOME\.config\whkdrc";                                        Source="komorebi\whkdrc" }
    @{ Name="Fastfetch";       App="fastfetch";      InstallCheck=$null;                                                           Target="$HOME\.config\fastfetch";                                     Source="fastfetch" }
    @{ Name="Starship";        App="starship";       InstallCheck=$null;                                                           Target="$HOME\.config\starship.toml";                                 Source="starship\starship.toml" }
    @{ Name="WezTerm";         App="wezterm-gui";    InstallCheck=$null;                                                           Target="$HOME\.config\wezterm";                                       Source="wezterm" }
    @{ Name="Yasb";            App="yasb";           InstallCheck=$null;                                                           Target="$HOME\.config\yasb";                                          Source="yasb" }
    @{ Name="Neovim";          App="nvim";           InstallCheck=$null;                                                           Target="$env:LOCALAPPDATA\nvim";                                      Source="nvim" }
    @{ Name="Yazi";            App="yazi";           InstallCheck=$null;                                                           Target="$env:APPDATA\yazi\config";                                    Source="yazi" }
    @{ Name="FlowLauncher";    App="Flow.Launcher";  InstallCheck="$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe";              Target="$env:APPDATA\FlowLauncher\Themes";                            Source="flowlauncher" }
    @{ Name="Spicetify Themes";App="spicetify";      InstallCheck=$null;                                                           Target="$env:APPDATA\spicetify\Themes\TUI";                           Source="spicetify\Themes\TUI" }
    @{ Name="PowerShell";      App="pwsh";           InstallCheck=$null;                                                           Target="$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"; Source="powershell\Microsoft.PowerShell_profile.ps1" }
    @{ Name="Nilesoft Shell";  App="shell";          InstallCheck="C:\Program Files\Nilesoft Shell\shell.exe";                    Target="C:\Program Files\Nilesoft Shell\imports\theme.nss";           Source="nilesoft\theme.nss" }
)

# =====================================================================
# HELPER: Generate a timestamped backup path for a given target path
# =====================================================================
function Get-BackupPath {
    param([string]$Path)
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    return "$Path.backup_$timestamp"
}

# =====================================================================
# HELPER: Confirm-LiveAction
# Call before ANY destructive operation. Returns $true if safe to proceed.
# In dry-run mode: prints a preview banner and returns $false (no changes).
# In live mode: shows a confirm prompt if $PromptMessage is provided.
# =====================================================================
function Confirm-LiveAction {
    param(
        [string]$Title,
        [string]$PromptMessage = ""
    )

    if ($global:DryRun) {
        Write-Host ""
        Write-Host "  ====================================================" -ForegroundColor Magenta
        Write-Host "  DRY RUN — $Title" -ForegroundColor Magenta
        Write-Host "  No files will be created, moved, or deleted." -ForegroundColor Magenta
        Write-Host "  ====================================================" -ForegroundColor Magenta
        Write-Host ""
        return $false
    }

    if ($PromptMessage -ne "") {
        $confirm = Read-Host "  $PromptMessage"
        if ($confirm -notmatch "^[Yy]$" -and $confirm -ne "") {
            Write-Host "`n  Aborted." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return $false
        }
    }

    return $true
}


function Show-Menu {
    Clear-Host
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "          WINDOWS DOTFILES DEPLOYMENT UTILITY        " -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host ""

    if ($global:DetectedApps.Count -gt 0) {
        Write-Host "  [STATUS] Apps detected: $($global:DetectedApps.Count) / $($global:SymlinkMap.Count)" -ForegroundColor Green
    } else {
        Write-Host "  [STATUS] No scan performed yet. Run Option 1 first." -ForegroundColor Yellow
    }

    if ($global:DryRun) {
        Write-Host "  [MODE]   DRY RUN — no changes will be made" -ForegroundColor Magenta
    } else {
        Write-Host "  [MODE]   Live" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  1. Scan system for installed ricing programs"
    Write-Host "  2. Scan system for existing symbolic links"
    Write-Host "  3. Deploy:  Create folders and symlinks"
    Write-Host "  4. Check:   Verify symlink health" -ForegroundColor Cyan
    Write-Host "  5. Dry-run: Toggle preview mode  $(if ($global:DryRun) { '[ON]' } else { '[off]' })" -ForegroundColor Magenta
    Write-Host "  6. Repair:  Fix missing and broken symlinks" -ForegroundColor Green
    Write-Host "  0. Cleanup: Remove existing symlinks  [DANGER ZONE]"
    Write-Host "  Q. Quit"
    Write-Host ""
}

# =====================================================================
# OPTION 1: Scan for installed programs
# =====================================================================
function Scan-Programs {
    Write-Host "`n  Scanning system for core utilities...`n" -ForegroundColor Cyan
    $global:DetectedApps = @()

    foreach ($item in $global:SymlinkMap) {
        # Primary: check if executable is on PATH
        $found = Get-Command $item.App -ErrorAction SilentlyContinue

        # Fallback: GUI apps not on PATH — check known install location
        if (-not $found -and $item.InstallCheck) {
            $found = Test-Path $item.InstallCheck
        }

        if ($found) {
            Write-Host "  [ OK ] $($item.Name)" -ForegroundColor Green
            $global:DetectedApps += $item.Name
        } else {
            Write-Host "  [ -- ] $($item.Name)  (not found)" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "  Scan complete: $($global:DetectedApps.Count) / $($global:SymlinkMap.Count) apps found." -ForegroundColor Cyan
    Write-Host "  Press any key to return to menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# =====================================================================
# OPTION 2: Scan for existing symlinks
# =====================================================================
function Scan-Symlinks {
    Write-Host "`n  --- SYMLINK SCAN (home + managed system paths) ---`n" -ForegroundColor Cyan

    # Collect all symlinks found under home directory (depth 4)
    $homeLinks = Get-ChildItem -Path ~ -Recurse -Depth 4 -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LinkType -eq 'SymbolicLink' }

    # Also collect managed out-of-home paths from SymlinkMap
    $extraPaths = $global:SymlinkMap | Where-Object { -not $_.Target.StartsWith($HOME) } | ForEach-Object { $_.Target }

    # Build a combined list: home symlinks + any out-of-home SymlinkMap entries
    $allEntries = @()

    foreach ($link in $homeLinks) {
        $mapEntry = $global:SymlinkMap | Where-Object { $_.Target -eq $link.FullName } | Select-Object -First 1
        $allEntries += [PSCustomObject]@{
            FullName  = $link.FullName
            Target    = $link.Target
            IsManaged = $null -ne $mapEntry
            AppName   = if ($mapEntry) { $mapEntry.Name } else { '' }
        }
    }

    foreach ($path in $extraPaths) {
        if (Test-Path $path) {
            $item = Get-Item $path -ErrorAction SilentlyContinue
            if ($item.LinkType -eq 'SymbolicLink') {
                if (-not ($allEntries | Where-Object { $_.FullName -eq $path })) {
                    $mapEntry = $global:SymlinkMap | Where-Object { $_.Target -eq $path } | Select-Object -First 1
                    $allEntries += [PSCustomObject]@{
                        FullName  = $path
                        Target    = $item.Target
                        IsManaged = $true
                        AppName   = if ($mapEntry) { $mapEntry.Name } else { '' }
                    }
                }
            }
        }
    }

    if ($allEntries.Count -eq 0) {
        Write-Host "  No symlinks found." -ForegroundColor DarkGray
    } else {
        foreach ($entry in $allEntries) {
            $nameTag       = if ($entry.AppName) { " $($entry.AppName):" } else { '' }
            $managedMarker = if ($entry.IsManaged) { ' *' } else { '  ' }
            $targetDisplay = if ($entry.Target) { $entry.Target } else { '(no target)' }

            if ($entry.Target -and (Test-Path $entry.Target)) {
                Write-Host "  [LINKED]$managedMarker$nameTag $($entry.FullName) -> $targetDisplay" -ForegroundColor Green
            } else {
                Write-Host "  [BROKEN]$managedMarker$nameTag $($entry.FullName) -> $targetDisplay" -ForegroundColor Red
            }
        }
        Write-Host ""
        Write-Host "  * = managed by this script" -ForegroundColor DarkGray
    }

    # Report managed out-of-home paths that are NOT symlinks or don't exist
    $hasExtras = $false
    foreach ($item in ($global:SymlinkMap | Where-Object { -not $_.Target.StartsWith($HOME) })) {
        if (Test-Path $item.Target) {
            $entry = Get-Item $item.Target -ErrorAction SilentlyContinue
            if ($entry.LinkType -ne 'SymbolicLink') {
                if (-not $hasExtras) { Write-Host ""; $hasExtras = $true }
                Write-Host "  [NOT LNK]  $($item.Name): $($item.Target)  (exists but is a real file)" -ForegroundColor Yellow
            }
        } else {
            if (-not $hasExtras) { Write-Host ""; $hasExtras = $true }
            Write-Host "  [  --   ]  $($item.Name): $($item.Target)  (not found)" -ForegroundColor DarkGray
        }
    }

    Write-Host "`n  Scan complete. Press any key to return to menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# =====================================================================
# OPTION 3: Deploy symlinks
# =====================================================================
function Deploy-Symlinks {
    if ($global:DetectedApps.Count -eq 0) {
        Write-Host "`n  [ERROR] Run Option 1 (Scan Programs) before deploying." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $modeLabel = if ($global:DryRun) { " [DRY RUN — no changes will be made]" } else { "" }
    Write-Host "`n  --- SYMLINK DEPLOYMENT$modeLabel ---`n" -ForegroundColor $(if ($global:DryRun) { 'Magenta' } else { 'Cyan' })

    $userInput = Read-Host "  Enter dotfiles directory path (Enter for default: $global:DefaultDotfilesDir)"

    $dotfilesDir = if ([string]::IsNullOrWhiteSpace($userInput)) { $global:DefaultDotfilesDir } else { $userInput }

    Write-Host ""
    Write-Host "  Dotfiles directory : " -NoNewline; Write-Host $dotfilesDir -ForegroundColor Yellow
    Write-Host "  Apps to link       : " -NoNewline; Write-Host $global:DetectedApps.Count -ForegroundColor Yellow
    if ($global:DryRun) {
        Write-Host "  Mode               : " -NoNewline; Write-Host "DRY RUN (no files will be created, moved, or deleted)" -ForegroundColor Magenta
    }
    Write-Host ""

    $confirm = Read-Host "  Proceed with deployment? [Y/n]"
    if ($confirm -notmatch "^[Yy]$" -and $confirm -ne "") {
        Write-Host "`n  Deployment aborted." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    # Create root dotfiles directory if missing (skipped in dry-run)
    if (-not (Test-Path $dotfilesDir)) {
        if ($global:DryRun) {
            Write-Host "`n  [DRY RUN] Would create dotfiles directory: $dotfilesDir" -ForegroundColor Magenta
        } else {
            New-Item -ItemType Directory -Path $dotfilesDir -Force | Out-Null
            Write-Host "`n  Created dotfiles directory: $dotfilesDir" -ForegroundColor Green
        }
    }

    # --- Counters for deploy summary ---
    $countLinked  = 0
    $countSkipped = 0
    $countBacked  = 0
    $countFailed  = 0

    Write-Host ""

    foreach ($item in $global:SymlinkMap) {
        if ($global:DetectedApps -notcontains $item.Name) { continue }

        $sourcePath = Join-Path -Path $dotfilesDir -ChildPath $item.Source
        $targetPath = $item.Target

        # Check source exists in dotfiles before attempting to link
        if (-not (Test-Path $sourcePath)) {
            Write-Host "  [SKIP]   $($item.Name)  (source not found: $sourcePath)" -ForegroundColor DarkGray
            $countSkipped++
            continue
        }

        # Ensure parent directory of target exists
        $targetParent = Split-Path $targetPath
        if ($targetParent -and -not (Test-Path $targetParent)) {
            if ($global:DryRun) {
                Write-Host "  [DRY RUN] Would create parent directory: $targetParent" -ForegroundColor Magenta
            } else {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }
        }

        if ($global:DryRun) {
            # --- Dry-run: describe what would happen ---
            if (Test-Path $targetPath) {
                $existing = Get-Item $targetPath -ErrorAction SilentlyContinue
                if ($existing.LinkType -eq 'SymbolicLink') {
                    Write-Host "  [DRY RUN] Would re-link  : $($item.Name)  (existing symlink replaced)" -ForegroundColor Magenta
                } else {
                    $backupPath = Get-BackupPath -Path $targetPath
                    Write-Host "  [DRY RUN] Would backup   : $($item.Name)  -> $backupPath" -ForegroundColor Magenta
                    Write-Host "  [DRY RUN] Would link     : $($item.Name)  $targetPath -> $sourcePath" -ForegroundColor Magenta
                    $countBacked++
                }
            } else {
                Write-Host "  [DRY RUN] Would link     : $($item.Name)  $targetPath -> $sourcePath" -ForegroundColor Magenta
            }
            $countLinked++

        } else {
            # --- Live deploy ---
            try {
                if (Test-Path $targetPath) {
                    $existing = Get-Item $targetPath -ErrorAction SilentlyContinue

                    if ($existing.LinkType -eq 'SymbolicLink') {
                        Remove-Item $targetPath -Force -ErrorAction Stop
                    } else {
                        $backupPath = Get-BackupPath -Path $targetPath
                        Rename-Item -Path $targetPath -NewName $backupPath -ErrorAction Stop
                        Write-Host "  [BACKUP] $($item.Name)  -> $backupPath" -ForegroundColor DarkYellow
                        $countBacked++
                    }
                }

                New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                Write-Host "  [LINKED] $($item.Name)  $targetPath -> $sourcePath" -ForegroundColor Green
                $countLinked++

            } catch {
                Write-Host "  [FAILED] $($item.Name)  — $($_.Exception.Message)" -ForegroundColor Red
                $countFailed++
            }
        }
    }

    # --- Deploy Summary ---
    $summaryColor = if ($global:DryRun) { 'Magenta' } else { 'Cyan' }
    $summaryTitle = if ($global:DryRun) { "DRY RUN SUMMARY  (no changes were made)" } else { "DEPLOY SUMMARY" }
    Write-Host ""
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host "  $summaryTitle" -ForegroundColor $summaryColor
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host "  $(if ($global:DryRun) { 'Would link' } else { 'Linked  ' }) : $countLinked" -ForegroundColor Green
    if ($countBacked  -gt 0) { Write-Host "  $(if ($global:DryRun) { 'Would backup' } else { 'Backed up' }): $countBacked" -ForegroundColor DarkYellow }
    if ($countSkipped -gt 0) { Write-Host "  Skipped  : $countSkipped  (source missing in dotfiles)" -ForegroundColor DarkGray }
    if ($countFailed  -gt 0) { Write-Host "  Failed   : $countFailed   (check admin rights)" -ForegroundColor Red }
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host ""
    Write-Host "  Done! Press any key to return to menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# =====================================================================
# OPTION 0: Cleanup symlinks
# =====================================================================
function Cleanup-Symlinks {
    Write-Host ""
    if ($global:DryRun) {
        Write-Host "  =====================================================" -ForegroundColor Magenta
        Write-Host "   CLEANUP PREVIEW (DRY RUN — nothing will be removed)" -ForegroundColor Magenta
        Write-Host "  =====================================================" -ForegroundColor Magenta
    } else {
        Write-Host "  =====================================================" -ForegroundColor Red
        Write-Host "   DANGER ZONE: REMOVE SYMLINKS" -ForegroundColor Red
        Write-Host "  =====================================================" -ForegroundColor Red
        Write-Host "  This removes all ricing symlinks managed by this script."
        Write-Host "  Your actual dotfiles in the dotfiles directory are NOT deleted."
    }
    Write-Host ""

    # In live mode, require explicit Y before doing anything
    if (-not $global:DryRun) {
        $confirm = Read-Host "  Type Y to confirm removal, anything else to cancel"
        if ($confirm -notmatch "^[Yy]$") {
            Write-Host "`n  Cleanup cancelled." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }
        Write-Host ""
    }

    $countRemoved = 0
    $countSkipped = 0
    $countMissing = 0

    foreach ($item in $global:SymlinkMap) {
        if (Test-Path $item.Target) {
            $entry = Get-Item $item.Target -ErrorAction SilentlyContinue
            if ($entry.LinkType -eq 'SymbolicLink') {
                if ($global:DryRun) {
                    Write-Host "  [DRY RUN] Would remove: $($item.Name)  ($($item.Target))" -ForegroundColor Magenta
                } else {
                    Remove-Item $item.Target -Force -ErrorAction SilentlyContinue
                    Write-Host "  [REMOVED] $($item.Name)  ($($item.Target))" -ForegroundColor Yellow
                }
                $countRemoved++
            } else {
                Write-Host "  [SKIP]    $($item.Name)  (not a symlink — left untouched)" -ForegroundColor DarkGray
                $countSkipped++
            }
        } else {
            Write-Host "  [  --  ]  $($item.Name)  (target not found)" -ForegroundColor DarkGray
            $countMissing++
        }
    }

    Write-Host ""
    $summaryColor = if ($global:DryRun) { 'Magenta' } else { 'Green' }
    $removedLabel = if ($global:DryRun) { 'Would remove' } else { 'Removed     ' }
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host "  $(if ($global:DryRun) { 'CLEANUP DRY RUN SUMMARY' } else { 'CLEANUP SUMMARY' })" -ForegroundColor $summaryColor
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host "  $removedLabel : $countRemoved" -ForegroundColor $(if ($countRemoved -gt 0) { 'Yellow' } else { 'DarkGray' })
    if ($countSkipped -gt 0) { Write-Host "  Skipped      : $countSkipped  (real files, not symlinks)" -ForegroundColor DarkGray }
    if ($countMissing -gt 0) { Write-Host "  Not found    : $countMissing" -ForegroundColor DarkGray }
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host ""
    Write-Host "  Press any key to return to menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# =====================================================================
# HELPER: Get-SymlinkHealth
# Returns an array of result objects — used by both Check and Repair.
# Each object: Name, TargetPath, SourcePath, Status, Detail
# Status values: OK | MISSING | DANGLING | WRONG | NOT_LINK | NO_SOURCE
# =====================================================================
function Get-SymlinkHealth {
    param([string]$DotfilesDir)

    $results = @()

    foreach ($item in $global:SymlinkMap) {
        if ($global:DetectedApps -notcontains $item.Name) { continue }

        $expectedSource = Join-Path -Path $DotfilesDir -ChildPath $item.Source
        $targetPath     = $item.Target

        $result = [PSCustomObject]@{
            Name       = $item.Name
            TargetPath = $targetPath
            SourcePath = $expectedSource
            Status     = ''
            Detail     = ''
        }

        if (-not (Test-Path $targetPath)) {
            $result.Status = 'MISSING'
            $result.Detail = "Target does not exist: $targetPath"
            $results += $result
            continue
        }

        $entry = Get-Item $targetPath -ErrorAction SilentlyContinue

        if ($entry.LinkType -ne 'SymbolicLink') {
            $result.Status = 'NOT_LINK'
            $result.Detail = "Real file/folder at target (not a symlink)"
            $results += $result
            continue
        }

        $actualTarget = $entry.Target

        if (-not (Test-Path $expectedSource)) {
            $result.Status = 'NO_SOURCE'
            $result.Detail = "Source missing in dotfiles: $expectedSource"
            $results += $result
            continue
        }

        if (-not (Test-Path $actualTarget)) {
            $result.Status = 'DANGLING'
            $result.Detail = "Symlink points to missing path: $actualTarget"
            $results += $result
            continue
        }

        # Resolve both paths for reliable comparison (handles ~, env vars, etc.)
        # Using try/catch per-call for PS5 compatibility (no ?. operator)
        $resolvedExpected = $null
        $resolvedActual   = $null
        try { $resolvedExpected = (Resolve-Path $expectedSource -ErrorAction SilentlyContinue).Path } catch {}
        try { $resolvedActual   = (Resolve-Path $actualTarget   -ErrorAction SilentlyContinue).Path } catch {}

        if ($resolvedExpected -and $resolvedActual -and ($resolvedExpected -eq $resolvedActual)) {
            $result.Status = 'OK'
            $result.Detail = "$targetPath -> $actualTarget"
        } else {
            $result.Status = 'WRONG'
            $result.Detail = "Points to: $actualTarget  |  Expected: $expectedSource"
        }

        $results += $result
    }

    return $results
}

# =====================================================================
# HELPER: Ask for dotfiles directory (shared prompt)
# =====================================================================
function Get-DotfilesDir {
    $userInput = Read-Host "  Enter dotfiles directory path (Enter for default: $global:DefaultDotfilesDir)"
    if ([string]::IsNullOrWhiteSpace($userInput)) { return $global:DefaultDotfilesDir }
    return $userInput
}

# =====================================================================
# OPTION 4: Check symlink health
# =====================================================================
function Check-Symlinks {
    if ($global:DetectedApps.Count -eq 0) {
        Write-Host "`n  [ERROR] Run Option 1 (Scan Programs) before checking." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    Write-Host "`n  --- SYMLINK HEALTH CHECK ---`n" -ForegroundColor Cyan
    $dotfilesDir = Get-DotfilesDir
    Write-Host ""

    $results = Get-SymlinkHealth -DotfilesDir $dotfilesDir

    foreach ($r in $results) {
        switch ($r.Status) {
            'OK'       { Write-Host "  [   OK   ] $($r.Name)" -ForegroundColor Green;   Write-Host "             $($r.Detail)" -ForegroundColor DarkGray }
            'MISSING'  { Write-Host "  [ MISSING] $($r.Name)" -ForegroundColor Red;     Write-Host "             $($r.Detail)" -ForegroundColor DarkGray }
            'DANGLING' { Write-Host "  [DANGLING] $($r.Name)" -ForegroundColor Red;     Write-Host "             $($r.Detail)" -ForegroundColor DarkGray }
            'WRONG'    { Write-Host "  [ WRONG  ] $($r.Name)" -ForegroundColor Yellow;  Write-Host "             $($r.Detail)" -ForegroundColor DarkGray }
            'NOT_LINK' { Write-Host "  [NOT LINK] $($r.Name)" -ForegroundColor Yellow;  Write-Host "             $($r.Detail)" -ForegroundColor DarkGray }
            'NO_SOURCE'{ Write-Host "  [NO SRCCE] $($r.Name)" -ForegroundColor DarkGray; Write-Host "             $($r.Detail)" -ForegroundColor DarkGray }
        }
    }

    $countOk      = ($results | Where-Object { $_.Status -eq 'OK'                          }).Count
    $countMissing = ($results | Where-Object { $_.Status -eq 'MISSING'                     }).Count
    $countBroken  = ($results | Where-Object { $_.Status -in 'DANGLING','WRONG','NOT_LINK' }).Count
    $countNoSrc   = ($results | Where-Object { $_.Status -eq 'NO_SOURCE'                   }).Count

    Write-Host ""
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "  HEALTH CHECK SUMMARY" -ForegroundColor Cyan
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "  Healthy   : $countOk" -ForegroundColor Green
    if ($countMissing -gt 0) { Write-Host "  Missing   : $countMissing  (not yet linked — run Deploy)" -ForegroundColor Red }
    if ($countBroken  -gt 0) { Write-Host "  Broken    : $countBroken  (dangling, wrong target, or not a link — run Repair)" -ForegroundColor Yellow }
    if ($countNoSrc   -gt 0) { Write-Host "  No source : $countNoSrc  (source missing in dotfiles — cannot repair)" -ForegroundColor DarkGray }
    Write-Host "  =====================================================" -ForegroundColor Cyan

    if ($countMissing -gt 0 -or $countBroken -gt 0) {
        Write-Host ""
        Write-Host "  Tip: Run Option 6 (Repair) to fix missing and broken links automatically." -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "  Press any key to return to menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# =====================================================================
# OPTION 6: Repair broken/missing symlinks
# =====================================================================
function Repair-Symlinks {
    if ($global:DetectedApps.Count -eq 0) {
        Write-Host "`n  [ERROR] Run Option 1 (Scan Programs) before repairing." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $modeLabel = if ($global:DryRun) { " [DRY RUN]" } else { "" }
    Write-Host "`n  --- SYMLINK REPAIR$modeLabel ---`n" -ForegroundColor $(if ($global:DryRun) { 'Magenta' } else { 'Cyan' })

    $dotfilesDir = Get-DotfilesDir
    Write-Host ""

    # Run health check silently to find what needs fixing
    $results    = Get-SymlinkHealth -DotfilesDir $dotfilesDir

    # Repairable: MISSING (no target yet) + DANGLING/WRONG/NOT_LINK (target exists but broken)
    # Not repairable: NO_SOURCE (source file missing in dotfiles — nothing to link to)
    $repairable = $results | Where-Object { $_.Status -in 'MISSING','DANGLING','WRONG','NOT_LINK' }
    $noSource   = $results | Where-Object { $_.Status -eq 'NO_SOURCE' }
    $alreadyOk  = $results | Where-Object { $_.Status -eq 'OK' }

    if ($repairable.Count -eq 0) {
        Write-Host "  Nothing to repair — all symlinks are healthy!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Press any key to return to menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    # Show what will be repaired
    Write-Host "  Items that will be repaired:" -ForegroundColor Cyan
    foreach ($r in $repairable) {
        $statusLabel = switch ($r.Status) {
            'MISSING'  { 'MISSING ' }
            'DANGLING' { 'DANGLING' }
            'WRONG'    { 'WRONG   ' }
            'NOT_LINK' { 'NOT LINK' }
        }
        Write-Host "    [$statusLabel] $($r.Name)" -ForegroundColor Yellow
        Write-Host "               $($r.Detail)" -ForegroundColor DarkGray
    }

    if ($noSource.Count -gt 0) {
        Write-Host ""
        Write-Host "  Items that CANNOT be repaired (source missing in dotfiles):" -ForegroundColor DarkGray
        foreach ($r in $noSource) {
            Write-Host "    [NO SOURCE] $($r.Name)  — $($r.SourcePath)" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    if ($global:DryRun) {
        Write-Host "  [DRY RUN] Previewing repairs — no changes will be made." -ForegroundColor Magenta
    } else {
        $confirm = Read-Host "  Repair $($repairable.Count) item(s)? [Y/n]"
        if ($confirm -notmatch "^[Yy]$" -and $confirm -ne "") {
            Write-Host "`n  Repair aborted." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }
    }

    Write-Host ""

    $countRepaired = 0
    $countFailed   = 0

    foreach ($r in $repairable) {
        $targetPath = $r.TargetPath
        $sourcePath = $r.SourcePath

        if ($global:DryRun) {
            if ($r.Status -ne 'MISSING') {
                Write-Host "  [DRY RUN] Would backup + re-link : $($r.Name)" -ForegroundColor Magenta
            } else {
                Write-Host "  [DRY RUN] Would create link      : $($r.Name)  $targetPath -> $sourcePath" -ForegroundColor Magenta
            }
            $countRepaired++
            continue
        }

        try {
            # Ensure parent directory exists
            $targetParent = Split-Path $targetPath
            if ($targetParent -and -not (Test-Path $targetParent)) {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }

            # Handle existing item at target path
            if (Test-Path $targetPath) {
                $existing = Get-Item $targetPath -ErrorAction SilentlyContinue
                if ($existing.LinkType -eq 'SymbolicLink') {
                    # Remove broken/wrong symlink cleanly
                    Remove-Item $targetPath -Force -ErrorAction Stop
                } else {
                    # Real file — back it up first
                    $backupPath = Get-BackupPath -Path $targetPath
                    Rename-Item -Path $targetPath -NewName $backupPath -ErrorAction Stop
                    Write-Host "  [BACKUP ] $($r.Name)  -> $backupPath" -ForegroundColor DarkYellow
                }
            }

            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
            Write-Host "  [REPAIRED] $($r.Name)  $targetPath -> $sourcePath" -ForegroundColor Green
            $countRepaired++

        } catch {
            Write-Host "  [FAILED ] $($r.Name)  — $($_.Exception.Message)" -ForegroundColor Red
            $countFailed++
        }
    }

    # --- Repair summary ---
    $summaryColor = if ($global:DryRun) { 'Magenta' } else { 'Cyan' }
    $summaryTitle = if ($global:DryRun) { "DRY RUN REPAIR SUMMARY  (no changes were made)" } else { "REPAIR SUMMARY" }
    Write-Host ""
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host "  $summaryTitle" -ForegroundColor $summaryColor
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host "  Already OK     : $($alreadyOk.Count)" -ForegroundColor Green
    Write-Host "  $(if ($global:DryRun) { 'Would repair' } else { 'Repaired    ' }) : $countRepaired" -ForegroundColor $(if ($countRepaired -gt 0) { 'Green' } else { 'DarkGray' })
    if ($noSource.Count -gt 0) { Write-Host "  Skipped (no source): $($noSource.Count)" -ForegroundColor DarkGray }
    if ($countFailed    -gt 0) { Write-Host "  Failed             : $countFailed  (check admin rights)" -ForegroundColor Red }
    Write-Host "  =====================================================" -ForegroundColor $summaryColor
    Write-Host ""
    Write-Host "  Press any key to return to menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# =====================================================================
# OPTION 5: Toggle dry-run mode
# =====================================================================
function Toggle-DryRun {
    $global:DryRun = -not $global:DryRun
    if ($global:DryRun) {
        Write-Host "`n  Dry-run mode ENABLED." -ForegroundColor Magenta
        Write-Host "  All options are safe to run — Deploy, Repair, and Cleanup" -ForegroundColor Magenta
        Write-Host "  will preview their actions without touching any files." -ForegroundColor Magenta
    } else {
        Write-Host "`n  Dry-run mode DISABLED — all operations will make real changes." -ForegroundColor Green
    }
    Start-Sleep -Seconds 3
}

# =====================================================================
# MAIN LOOP
# =====================================================================
while ($true) {
    Show-Menu
    $choice = Read-Host "  Select an option"

    switch ($choice.ToUpper()) {
        '1'   { Scan-Programs }
        '2'   { Scan-Symlinks }
        '3'   { Deploy-Symlinks }
        '4'   { Check-Symlinks }
        '5'   { Toggle-DryRun }
        '6'   { Repair-Symlinks }
        '0'   { Cleanup-Symlinks }
        'Q'   { Write-Host "`n  Goodbye!`n"; exit }
        default {
            Write-Host "  Invalid option. Please choose 0–6 or Q." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
