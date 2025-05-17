# Override Global Variables

#Variables to define the Windows OS / Edition to be applied during OSDCloud
#$OSName = 'Windows 11 23H2 x64' < commented out 23/08/2024 as we may need W10 in niche cases
$OSEdition = 'Enterprise'
$OSActivation = 'Retail'
$OSLanguage = 'en-gb'
$usbDrive = Get-Volume | Where-Object {$_.DriveType -eq 'Removable'} | Select-Object -First 1 -ExpandProperty DriveLetter
$osdCloudLocalPath = "$usbDrive"+":\OSDCloud"

#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
    CheckSHA1 = [bool]$true
}

$banner = @"
//////////////////////////////////////////////////
//  ___  ____  ____   ____ _                 _  //
// / _ \/ ___||  _ \ / ___| | ___  _   _  __| | //
//| | | \___ \| | | | |   | |/ _ \| | | |/ _  | //
//| |_| |___) | |_| | |___| | (_) | |_| | (_| | //
// \___/|____/|____/ \____|_|\___/ \__,_|\__,_| //
//                                              //
//////////////////////////////////////////////////

// This is a bespoke version of the script
"@
$loadingColor = "Yellow"
Write-Host $banner -ForegroundColor $loadingColor

$loadingMessage1 = "Original created by Dave Segura (@SeguraOSD)"
$loadingColor = "White"
$delay = 30  # Delay between each character in milliseconds

# Function to simulate typing effect
function Type-Write ($message, $color, $delay) {
    foreach ($char in $message.ToCharArray()) {
        Write-Host -NoNewline $char -ForegroundColor $color
        Start-Sleep -Milliseconds $delay
    }
    Write-Host  # Move to the next line after the message is fully typed
}

# Type out the messages with a delay
Write-Host ""
Type-Write $loadingMessage1 $loadingColor $delay
Start-Sleep -Seconds 1  # Optional pause between the lines

write-host ""

Write-Host  "Loading OSDCloud..." -ForegroundColor Green
Write-Host ".................................................." -ForegroundColor Green

# Memory check before deployment
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

# Deploy from HTTP server
$wimSource = "http://192.168.1.95:8080/Windows11_24H2_x64_Enterprise_en-gb.wim"
Write-Host "Deploying Windows from $wimSource..." -ForegroundColor Green
Start-OSDCloud -ImageFileURL $wimSource -ZTI -Autopilot

wpeutil reboot
