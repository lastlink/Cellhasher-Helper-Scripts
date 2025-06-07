# Get list of connected devices
$devices = adb devices | Select-String "device$" | ForEach-Object { ($_ -split "\s+")[0] }

$labels = @{}
Import-Csv -Path ".\devices.csv" | ForEach-Object {
    $labels[$_.SerialNumber] = $_
}

$devicesList = @()

# Loop through each device and retrieve serial number & device name
foreach ($device in $devices) {
    $serial = adb -s $device shell getprop ro.serialno
    $usbNumber = [int]$labels[$serial]."Usb #"
    $tags = $labels[$serial]."Tags"
    $imei = adb -s $device shell "service call iphonesubinfo 1 s16 com.android.shell | cut -c 50-64 | tr -d '.[:space:]'"
    $name = adb -s $device shell getprop ro.product.model

    $deviceIps = adb -s $device shell ip -o a

    # Extract only IPv4 addresses
    $ipAddresses = $deviceIps | ForEach-Object {
        if ($_ -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b") {
            $matches[0]
        }
    }

    $filteredIPs = $ipAddresses | Where-Object { $_ -match "^(192\.|10\.)" } | Out-String
    $filteredIPs = $filteredIPs -replace "`r`n", " " -replace "`n", " " -replace "`r", " "

    $devicesList += [PSCustomObject]@{ "Usb #" = $usbNumber; "Device" = "scrcpy -s $device"; "Label" = "$name"; "Tags" = "$tags"; "SerialNumber" = "$serial"; "IMEI" = "$imei"; "Ip" = "$filteredIPs" }
    Write-Host "# $usbNumber | Device: $device | Name $name | Serial Number: $serial | IMEI: $imei"
}

# Find missing devices from CSV
$missingDevices = $devicesList | Where-Object { $_.SerialNumber -notin $labels.Keys }

foreach ($missing in $missingDevices) {
    $devicesList += [PSCustomObject]@{
        "Usb #" = $missing."Usb #"
        "Device" = "N/A"
        "Label" = $missing.Label
        "Tags" = $missing.Tags
        "SerialNumber" = $missing.SerialNumber
        "IMEI" = $missing.Imei
        "Ip" = "N/A"
    }
}

$sortedDevices = $devicesList | Sort-Object -Property "Usb #"
$sortedDevices | Format-Table 

Write-Host "Total Records: $($sortedDevices.Count)"
$mhSpeed = 3.5
Write-Host "Total Speed: $($sortedDevices.Count*$mhSpeed)"

$sortedDevices | Export-Csv -Path ".\cellhasher_scripts\phone_labels2.csv" -NoTypeInformation -UseQuotes Never

