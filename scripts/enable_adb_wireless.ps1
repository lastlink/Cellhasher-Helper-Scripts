# Get list of connected devices
$devices = adb devices | Select-String "device$" | ForEach-Object { ($_ -split "\s+")[0] }

# Loop through each device and enable wireless debugging
foreach ($device in $devices) {
    Write-Host "Enabling wireless debugging on $device..."
    # termux ssh port
    adb -s $device forward tcp:8022 tcp:8022
    # will turn off on phone reset
    adb -s $device tcpip 5555
}

Write-Host "Wireless debugging enabled for all devices!"