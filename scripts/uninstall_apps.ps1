# Get a list of all connected ADB devices
$devices = adb devices | ForEach-Object { $_ -match "^(.*?)\tdevice$" ? $matches[1] : $null } | Where-Object { $_ -ne $null }

# Read app package names from the file
$appList = Get-Content ".\uninstall_packages.txt"

# Loop through each package and disable it on all connected devices
foreach ($app in $appList) {
    $app_name = $app -replace "`r`n", " " -replace "`n", " " -replace "`r", " "
    # Loop through each device and send the dsiable command
    $count = 0
    foreach ($device in $devices) {
        Write-Host "Uninstalling app: $app_name on device: i:$count $device"
        # Run the ADB uninstall command
        adb -s $device shell pm uninstall --user 0 $app_name

        $count++
    }
}
