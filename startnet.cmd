@echo off
wpeinit

PowerShell -Nol -C Initialize-OSDCloudStartnet
PowerShell -Nol -C Initialize-OSDCloudStartnetUpdate

start /wait PowerShell -Nol -C "Invoke-WebPSScript https://raw.githubusercontent.com/3frustratedDucks/osd_build_script/refs/heads/main/win_image.ps1"
