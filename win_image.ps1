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

# Ensure the share is accessible
net use \\192.168.1.2\Harddisk

# Create 8GB RAM disk as R: using AIM Toolkit
$aimPath = "\\192.168.1.2\Harddisk\dl\aim_cli.exe"
Write-Host "Creating 8GB RAM disk as R: using AIM Toolkit..." -ForegroundColor Yellow
Start-Process -FilePath $aimPath -ArgumentList '-a -s 8G -m R:' -Wait
Start-Process -FilePath "format.com" -ArgumentList 'R: /FS:NTFS /Q /Y' -Wait

# Copy the WIM to the RAM disk
$wimSource = "\\192.168.1.2\Harddisk\dl\win11.wim"
$wimDest = "R:\win11.wim"
Write-Host "Copying WIM from $wimSource to $wimDest..." -ForegroundColor Yellow
Copy-Item $wimSource $wimDest

# Deploy from RAM disk
Write-Host "Deploying Windows from RAM disk..." -ForegroundColor Green
Start-OSDCloud -ImageFileFullName $wimDest

#wpeutil reboot
