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

# Prompt for next action
Write-Host ""
Write-Host "Select an option:" -ForegroundColor Yellow
Write-Host "1: Install Windows 11 (default in 20 seconds)"
Write-Host "2: Run a new Autopilot hash"
Write-Host ""
Write-Host "Waiting for input (20 seconds)..."

$choice = $null
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt 20 -and !$choice) {
    if ([System.Console]::KeyAvailable) {
        $key = [System.Console]::ReadKey($true)
        if ($key.KeyChar -eq '1' -or $key.KeyChar -eq '2') {
            $choice = $key.KeyChar
        }
    }
    Start-Sleep -Milliseconds 100
}
$sw.Stop()
if (-not $choice) { $choice = '1' }

Write-Host ""
if ($choice -eq '2') {
    Write-Host "You selected: Run a new Autopilot hash" -ForegroundColor Cyan
    # Check if Get-WindowsAutoPilotInfo is available
    if (Get-Command Get-WindowsAutoPilotInfo -ErrorAction SilentlyContinue) {
        try {
            Write-Host "Running Get-WindowsAutoPilotInfo..." -ForegroundColor Green
            Get-WindowsAutoPilotInfo -OutputFile "X:\AutopilotHWID.csv"
            Write-Host "Autopilot hash saved to X:\AutopilotHWID.csv" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to run Get-WindowsAutoPilotInfo." -ForegroundColor Red
            Write-Host "Full error record:"
            Write-Host $_ -ForegroundColor DarkGray
            Write-Host "Press Enter to exit..."
            [void][System.Console]::ReadLine()
            exit
        }
    } else {
        Write-Host "Get-WindowsAutoPilotInfo module is not available in this environment." -ForegroundColor Red
        Write-Host "You can download it from: https://www.powershellgallery.com/packages/Get-WindowsAutoPilotInfo"
        Write-Host "Press Enter to exit..."
        [void][System.Console]::ReadLine()
        exit
    }
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit
} else {
    Write-Host "Proceeding with Windows 11 installation..." -ForegroundColor Green
}

# Deploy from HTTP server with error handling
$wimSource = "http://192.168.1.95:8080/Windows11_24H2_x64_Enterprise_en-gb.wim"
try {
    Write-Host "Deploying Windows from $wimSource..." -ForegroundColor Green
    Start-OSDCloud -ImageFileURL $wimSource # -ZTI
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

wpeutil reboot
