
# Get list of connected devices
$devices = adb devices | Select-String "device$" | ForEach-Object { ($_ -split "\s+")[0] }

$apkFolderPath = "C:\Users\xxx\Documents\cellhasher_apks"
$apkPaths = Get-ChildItem -Path "$apkFolderPath" -Recurse -Filter "*.apk" | Select-Object -ExpandProperty FullName

# $devices = @("xxx", "xx2")
# Loop through each device and install all apks in the folder
$count = 0
foreach ($device in $devices) {
    foreach ($apkPath in $apkPaths) {
        Write-Host "Installing apk:$apkPath on i:$count $device..."

        adb -s $device install $apkPath

        $count++
    }
}

Write-Host "Apks installed for all devices!"