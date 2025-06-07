$port = 5555

$localDeviceIps = Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4"} | Select-Object -ExpandProperty IPAddress

$filteredIPs = $localDeviceIps | Where-Object { $_ -match "^(192\.|10\.)" } | Out-String

$subnet = ($filteredIPs -split "\.")[0..2] -join "."

foreach ($ip in 1..254) {
    $target = "$subnet.$ip"
    $tcp = New-Object System.Net.Sockets.TcpClient
    $connect = $tcp.ConnectAsync($target, $port)
    $null = $connect.Wait(100)
    if ($tcp.Connected) {
        Write-Host "✅ ADB device found at ${target}:${port}" -ForegroundColor Green
        adb connect "${target}:${port}"
        $device = "${target}:${port}"
        $serial = adb -s $device shell getprop ro.serialno
        if ($serial) {
            Write-Host "📌 Device Found: $device | Serial: $serial" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️ Device $device detected, but serial number could not be retrieved." -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ No ADB device detected at ${target}:${port}" -ForegroundColor Red
    }
    $tcp.Close()
}