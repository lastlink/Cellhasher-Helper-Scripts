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
    $rack = $labels[$serial]."Rack"
    $cpuDetails = $labels[$serial]."CPU"
    $maxCpuSpeedGHz = $labels[$serial]."Max CPU Speed"
    $cpuCores = $labels[$serial]."CPU Cores"
    $chipsetLookup = $labels[$serial]."CPU Lookup"
    $gpuName = $labels[$serial]."GPU"
    $tags = $labels[$serial]."Tags"
    $imei = $labels[$serial]."IMEI"
    $name = $labels[$serial]."Label"
    if (-not $imei) {
        $imei = adb -s $device shell "service call iphonesubinfo 1 s16 com.android.shell | cut -c 50-64 | tr -d '.[:space:]'"
        $imei = $imei.ToString()
        $imei = -join ($imei -split '(?<=\G.{4})' -join '-')
    }
    if (-not $name) {
        $name = adb -s $device shell getprop ro.product.model
    }
    if (-not $cpuDetails) {
        $chipset = adb -s $device shell "getprop ro.board.platform"

        $chipsetLookup = "https://phonedb.net/index.php?m=processor&s=query&d=detailed_specs&codename=$chipset#result"
    
        # Get CPU (SoC) name
        $cpuName = adb -s $device shell "getprop ro.hardware.chipname"
        if (-not $cpuName) {
            $cpuName = adb -s $device shell "cat /proc/cpuinfo | grep Hardware"
        }

        # Method 2: Extract from /proc/cpuinfo
        if (-not $cpuName) {
            $cpuName = adb -s $device shell "cat /proc/cpuinfo | grep Hardware"
        }
    
        # Method 3: Check /sys/devices/soc0 (for Qualcomm devices)
        if (-not $cpuName) {
            $cpuName = adb -s $device shell "cat /sys/devices/soc0/family"
        }
        $socRevision = adb -s $device shell "cat /sys/devices/soc0/revision"

        $cpuDetails = "$cpuName ($chipset) rv:$socRevision"

        # Get number of CPU cores
        $cpuCores = adb -s $device shell "cat /sys/devices/system/cpu/possible"
        # Get GPU name (for Qualcomm devices)
        $gpuName = adb -s $device shell "cat /sys/class/kgsl/kgsl-3d0/gpu_model"
    }

    # Get current CPU speed (Core 0)
    $cpuSpeedKHz = adb -s $device shell "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
    $cpuSpeedGHz = "$([math]::Round($cpuSpeedKHz / 1000000, 2)) GHz"

    if (-not $maxCpuSpeedGHz) {
        # # Get max CPU speed
        $maxCpuSpeedKHz = adb -s $device shell "cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
        $maxCpuSpeedGHz = "$([math]::Round($maxCpuSpeedKHz / 1000000, 2)) GHz"
    }

    $deviceIps = adb -s $device shell ip -o a

    # Extract only IPv4 addresses
    $ipAddresses = $deviceIps | ForEach-Object {
        if ($_ -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b") {
            $matches[0]
        }
    }

    $filteredIPs = $ipAddresses | Where-Object { $_ -match "^(192\.|10\.)" } | Out-String
    $filteredIPs = $filteredIPs -replace "`r`n", " " -replace "`n", " " -replace "`r", " "
    $filteredIPs = $filteredIPs.Trim()

    $devicesList += [PSCustomObject]@{ "Rack" = $rack; "Usb #" = $usbNumber; "Device" = "scrcpy -s $device"; "Label" = "$name"; "Tags" = "$tags"; "SerialNumber" = "$serial"; "IMEI" = "$imei"; "Ip" = "$filteredIPs"; "CPU" = "$cpuDetails"; "CPU Speed" = "$cpuSpeedGHz"; "Max CPU Speed" = "$maxCpuSpeedGHz"; "CPU Cores" = "$cpuCores"; "CPU Lookup" = "$chipsetLookup"; "GPU" = "$gpuName" }
    Write-Host "Rack: $rack | # $usbNumber | Device: $device | Name $name | Serial Number: $serial | IMEI: $imei"
}

# Find missing devices from CSV
$missingDevices = $labels.Keys | Where-Object { $_ -notin $devicesList.SerialNumber }

foreach ($missing in $missingDevices) {
    $missingDevice = $labels[$missing];
    $devicesList += [PSCustomObject]@{
        "Rack"         = $missingDevice."Rack"
        "Usb #"         = $missingDevice."Usb #"
        "Device"        = "N/A"
        "Label"         = $missingDevice.Label
        "Tags"          = $missingDevice.Tags
        "SerialNumber"  = $missingDevice.SerialNumber
        "IMEI"          = $missingDevice.IMEI
        "Ip"            = "N/A"
        "CPU"           = $missingDevice.CPU
        "CPU Speed"     = $missingDevice."CPU Speed"
        "Max CPU Speed" = $missingDevice."Max CPU Speed"
        "CPU Cores"     = $missingDevice."CPU Cores"
        "CPU Lookup"    = $missingDevice."CPU Lookup"
        "GPU"           = $missingDevice."GPU"
    }
}

$sortedDevices = $devicesList | Sort-Object -Property "Usb #"
$sortedDevices | Format-Table 

Write-Host "Total Records: $($sortedDevices.Count)"
$mhSpeed = 3.5
Write-Host "Total Speed: $($sortedDevices.Count*$mhSpeed)"

$sortedDevices | Export-Csv -Path ".\cellhasher_scripts\phone_labels2.csv" -NoTypeInformation -UseQuotes Never

