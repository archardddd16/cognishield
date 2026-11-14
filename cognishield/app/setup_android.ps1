# CogniShield: one-time Android setup for Notification Guard.
# Run from the app folder AFTER `flutter create . --project-name cognishield --platforms=web,android`:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\setup_android.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kotlinRoot = Join-Path $here 'android\app\src\main\kotlin'
if (-not (Test-Path $kotlinRoot)) {
    throw "Android folder not found. Run: flutter create . --project-name cognishield --platforms=web,android"
}
$main = Get-ChildItem -Path $kotlinRoot -Recurse -Filter 'MainActivity.kt' | Select-Object -First 1
if (-not $main) { throw 'MainActivity.kt not found under android\app\src\main\kotlin.' }

$line = Select-String -Path $main.FullName -Pattern '^\s*package\s+([\w\.]+)' | Select-Object -First 1
if (-not $line) { throw 'Could not read the package name from MainActivity.kt.' }
$pkg = $line.Matches[0].Groups[1].Value
$dir = $main.DirectoryName
$utf8 = New-Object System.Text.UTF8Encoding($false)

foreach ($name in 'MainActivity', 'CogniNotificationService') {
    $src = Get-Content (Join-Path $here "android_native\$name.kt.txt") -Raw
    [System.IO.File]::WriteAllText((Join-Path $dir "$name.kt"), $src.Replace('__PACKAGE__', $pkg), $utf8)
}

$manifest = Join-Path $here 'android\app\src\main\AndroidManifest.xml'
Copy-Item $manifest "$manifest.bak" -Force
Copy-Item (Join-Path $here 'android_native\AndroidManifest.xml') $manifest -Force

Write-Host "Done. Package: $pkg"
Write-Host "Next: flutter run   (use an Android emulator or phone), then Protection > Notification Guard."
