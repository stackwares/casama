# Builds the Windows desktop app and an MSIX installer (run on Windows). Signing: set
# MSIX_CERT (path to .pfx) and MSIX_CERT_PASSWORD, or sign the MSIX in the Microsoft Store flow.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\client")
$api = if ($env:KASAMA_API_URL) { $env:KASAMA_API_URL } else { "https://cloud.kasama.dev" }
flutter build windows --release --dart-define=KASAMA_API_URL=$api
$version = (Select-String -Path pubspec.yaml -Pattern '^version: (.+)\+').Matches[0].Groups[1].Value
New-Item -ItemType Directory -Force -Path ..\dist | Out-Null
Compress-Archive -Force -Path build\windows\x64\runner\Release\* -DestinationPath "..\dist\kasama-$version-windows-x64.zip"
if ($env:MSIX_CERT) {
  dart run msix:create --certificate-path $env:MSIX_CERT --certificate-password $env:MSIX_CERT_PASSWORD --output-path ..\dist
}
