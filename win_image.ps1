# Block WorldTimeAPI to prevent timeouts
Write-Host "Adding WorldTimeAPI block to hosts file..." -ForegroundColor Yellow
Add-Content -Path "X:\Windows\System32\drivers\etc\hosts" -Value "`n127.0.0.1 worldtimeapi.org" -Force
Write-Host "WorldTimeAPI has been blocked successfully!" -ForegroundColor Green

# Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = $false
    RecoveryPartition = $true
    OEMActivation = $true
    WindowsUpdate = $true
    WindowsUpdateDrivers = $true
    WindowsDefenderUpdate = $true
    SetTimeZone = $true
    ClearDiskConfirm = $false
    ShutdownSetupComplete = $false
    SyncMSUpCatDriverUSB = $true
    CheckSHA1 = $true
}

# Simple ASCII banner
$banner = @"
//////////////////////////////////////////////////
//  ___  ____  ____   ____ _                 _  //
// / _ \/ ___||  _ \ / ___| | ___  _   _  __| | //
//| | | \___ \| | | | |   | |/ _ \| | | |/ _  | //
//| |_| |___) | |_| | |___| | (_) | |_| | (_| | //
// \___/|____/|____/ \____|_|\___/ \__,_|\__,_| //
//                                              //
//////////////////////////////////////////////////
"@
$loadingColor = "Yellow"
Write-Host $banner -ForegroundColor $loadingColor

Write-Host ""
Write-Host "Original created by Dave Segura (@SeguraOSD)" -ForegroundColor White
Write-Host ""

Write-Host  "Loading OSDCloud..." -ForegroundColor Green
Write-Host ".................................................." -ForegroundColor Green

# Memory check before deployment
try {
    $mem = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $mem = [math]::Round($mem, 1)
    if ($mem -lt 31.5) {  # Allowing for slight reporting variance
        Write-Host "WARNING: This device has only $mem GB of RAM. 32GB is expected!" -ForegroundColor Red
        Write-Host "This may mean a memory module is missing or not seated correctly."
        Write-Host ""
        Write-Host "Press 1 to IGNORE and continue deployment." -ForegroundColor Yellow
        Write-Host "Press 2 to SHUT DOWN the device." -ForegroundColor Yellow
        $choice = Read-Host "Enter your choice (1=Ignore, 2=Shutdown)"
        if ($choice -eq "2") {
            Write-Host "Shutting down device..." -ForegroundColor Red
            Stop-Computer
            exit
        }
        Write-Host "Proceeding with deployment despite low memory..." -ForegroundColor Yellow
    }
    else {
        Write-Host "Memory check passed: $mem GB detected." -ForegroundColor Green
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.InvocationInfo) {
        Write-Host "At: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Yellow
    }
    Write-Host "Full error record:"
    Write-Host $_ -ForegroundColor DarkGray
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit
}

# Proceed with Windows 11 installation
Write-Host "Proceeding with Windows 11 installation..." -ForegroundColor Green

# Deploy from HTTP server with error handling
$wimSource = "http://192.168.1.102:8080/Windows11_24H2_x64_Enterprise_en-gb.wim"
try {
    Write-Host "Deploying Windows from $wimSource..." -ForegroundColor Green
    Start-OSDCloud -ImageFileURL $wimSource -ZTI
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.InvocationInfo) {
        Write-Host "At: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Yellow
    }
    Write-Host "Full error record:"
    Write-Host $_ -ForegroundColor DarkGray
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit
}

# -----------------------------
# SetupComplete / Post-Build Setup
# -----------------------------
Write-Host ""
Write-Host "Waiting for Windows installation to complete..." -ForegroundColor Yellow

# Wait for C: drive to be accessible
$maxAttempts = 30
$attempt = 0
$cDriveReady = $false

while (-not $cDriveReady -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "Attempt $attempt of $maxAttempts to access C: drive..." -ForegroundColor Yellow
    if (Test-Path "C:\Windows") {
        $cDriveReady = $true
        Write-Host "C: drive is now accessible!" -ForegroundColor Green
    } else {
        Start-Sleep -Seconds 10
    }
}

if (-not $cDriveReady) {
    Write-Host "ERROR: Could not access C: drive after $maxAttempts attempts!" -ForegroundColor Red
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit
}

Write-Host ""
Write-Host "Copying SetupComplete.cmd and Post-Build.exe from WinPE (X:)..." -ForegroundColor Cyan

# Source from WinPE (RAMDisk)
$osdCloudSource      = "X:\OSDCloud"
$setupCmdSource      = "X:\OSDCloud\SetupComplete.cmd"
$postBuildSource     = "X:\OSDCloud\Post-Build.exe"

# Target in applied OS
$setupScriptFolder   = "C:\Windows\Setup\Scripts"
$setupCmdTarget      = "C:\Windows\Setup\Scripts\SetupComplete.cmd"
$postBuildTarget     = "C:\OSDCloud\Post-Build.exe"

# Create Scripts folder if it doesn't exist
if (-not (Test-Path $setupScriptFolder)) {
    New-Item -Path $setupScriptFolder -ItemType Directory -Force | Out-Null
    Write-Host "✔ Created folder: $setupScriptFolder"
}

# Copy SetupComplete.cmd to deployed OS
if (Test-Path $setupCmdSource) {
    Copy-Item -Path $setupCmdSource -Destination $setupCmdTarget -Force
    Write-Host "✔ SetupComplete.cmd copied to $setupScriptFolder"
} else {
    Write-Host "⚠ SetupComplete.cmd not found in $osdCloudSource!" -ForegroundColor Red
}

# Copy Post-Build.exe to deployed OS
if (Test-Path $postBuildSource) {
    Copy-Item -Path $postBuildSource -Destination $postBuildTarget -Force
    Write-Host "✔ Post-Build.exe copied to C:\OSDCloud"
} else {
    Write-Host "⚠ Post-Build.exe not found in $osdCloudSource!" -ForegroundColor Red
}

# -----------------------------
# Reboot into OOBE
# -----------------------------
Write-Host ""
Write-Host "OSDCloud deployment complete. Rebooting into OOBE..." -ForegroundColor Green

wpeutil reboot
