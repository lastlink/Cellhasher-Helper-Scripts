# Get a list of all connected ADB devices
$devices = adb devices | ForEach-Object { $_ -match "^(.*?)\tdevice$" ? $matches[1] : $null } | Where-Object { $_ -ne $null }

$count = 0
# Loop through each device and send the mute command
foreach ($device in $devices) {
    $count+=1
    Write-Host "Muting device ${count}: $device"
    adb -s $device shell input keyevent 164  # KEYCODE_VOLUME_MUTE
    adb -s $device shell settings put global boot_sound_enabled 0

}
