# adb debug port
$port = 5555

$localDeviceIps = Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4"} | Select-Object -ExpandProperty IPAddress

$filteredIPs = $localDeviceIps | Where-Object { $_ -match "^(192\.|10\.)" } | Out-String

$subnet = ($filteredIPs -split "\.")[0..2] -join "."

foreach ($ip in 1..255) {
    $target = "$subnet.$ip"
    $tcp = New-Object System.Net.Sockets.TcpClient
    $connect = $tcp.ConnectAsync($target, $port)
    $connect.Wait(100)
    if ($tcp.Connected) {
        Write-Host "ADB device found at ${target}:${port}"
        adb connect "${target}:${port}"
        $device = "${target}:${port}"
        $serial = adb -s $device shell getprop ro.serialno
        Write-Host "Device: $device | Serial Number: $serial"
    }
    $tcp.Close()
}