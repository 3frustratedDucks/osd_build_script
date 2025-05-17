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

# Deploy from HTTP server with error handling
$wimSource = "http://192.168.1.95:8080/Windows11_24H2_x64_Enterprise_en-gb.wim"
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

wpeutil reboot
