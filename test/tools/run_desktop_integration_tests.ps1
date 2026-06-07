$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Resolve-FlutterCommand {
  if ($env:FLUTTER_BIN) {
    return @($env:FLUTTER_BIN)
  }

  $flutter = Get-Command flutter -ErrorAction SilentlyContinue
  if ($flutter) {
    return @($flutter.Source)
  }

  $fvm = Get-Command fvm -ErrorAction SilentlyContinue
  if ($fvm) {
    return @($fvm.Source, "flutter")
  }

  throw "flutter executable not found. Add flutter to PATH, install fvm, or set FLUTTER_BIN."
}

function Resolve-DesktopDevice {
  if ($env:DESKTOP_DEVICE) {
    return $env:DESKTOP_DEVICE
  }

  if ($IsMacOS) {
    return "macos"
  }

  if ($IsLinux) {
    return "linux"
  }

  if ($IsWindows) {
    return "windows"
  }

  throw "Unsupported OS. Set DESKTOP_DEVICE explicitly to macos, linux, or windows."
}

function Run-IntegrationTest {
  param(
    [string]$TestPath,
    [string[]]$FlutterCommand,
    [string]$DesktopDevice
  )

  Write-Host "== Running $TestPath on $DesktopDevice =="
  $command = $FlutterCommand[0]
  $arguments = @()
  if ($FlutterCommand.Length -gt 1) {
    $arguments += $FlutterCommand[1..($FlutterCommand.Length - 1)]
  }
  $arguments += @("test", $TestPath, "-d", $DesktopDevice)

  & $command @arguments
}

$flutterCommand = Resolve-FlutterCommand
$desktopDevice = Resolve-DesktopDevice

Push-Location $RootDir
try {
  Run-IntegrationTest -TestPath "integration_test/root/favorite_sync_flow_test.dart" -FlutterCommand $flutterCommand -DesktopDevice $desktopDevice
  Run-IntegrationTest -TestPath "integration_test/watchlist/watchlist_flow_test.dart" -FlutterCommand $flutterCommand -DesktopDevice $desktopDevice
} finally {
  Pop-Location
}
