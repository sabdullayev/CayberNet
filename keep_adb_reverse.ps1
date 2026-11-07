# Keep ADB reverse active for connected devices
param(
    [string]$DeviceSerial = "89KVVSDY9LUCUKIF",
    [int]$Port = 8000
)

$adbPath = "E:\downloads\AndroidSdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbPath = "adb"
}

Write-Host "CyberNet ADB Reverse Watchdog started on port $Port..."

while ($true) {
    try {
        & $adbPath -s $DeviceSerial reverse tcp:$Port tcp:$Port 2>$null
    } catch {
        # ignore temporary errors if device unplugged
    }
    Start-Sleep -Seconds 3
}
