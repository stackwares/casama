# Builds the Windows desktop app and an MSIX installer (run on Windows). Signing: set
# MSIX_CERT (path to .pfx) and MSIX_CERT_PASSWORD, or sign the MSIX in the Microsoft Store flow.
# With WINSPARKLE_KEY (the DSA private key, ~/.config/casama/winsparkle-dsa-private.pem) and
# openssl on PATH (Git for Windows has one), it also signs the MSIX for WinSparkle and writes
# dist\appcast-windows.xml for scripts/publish-desktop-release.sh.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\client")
$api = if ($env:CASAMA_API_URL) { $env:CASAMA_API_URL } else { "https://api.casama.ai" }
$defines = @("--dart-define=CASAMA_API_URL=$api")
if ($env:CASAMA_OFFICIAL_BUILD -eq "1" -and (Test-Path "config\telemetry.json")) {
  $defines += "--dart-define-from-file=config/telemetry.json"
}
flutter build windows --release @defines
$version = (Select-String -Path pubspec.yaml -Pattern '^version: (.+)\+').Matches[0].Groups[1].Value
New-Item -ItemType Directory -Force -Path ..\dist | Out-Null
Compress-Archive -Force -Path build\windows\x64\runner\Release\* -DestinationPath "..\dist\casama-$version-windows-x64.zip"
if ($env:MSIX_CERT) {
  dart run msix:create --certificate-path $env:MSIX_CERT --certificate-password $env:MSIX_CERT_PASSWORD --output-path ..\dist
}

# WinSparkle update feed (D-159): the MSIX just built, with its DSA signature.
$msix = Get-ChildItem ..\dist -Filter *.msix -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($env:WINSPARKLE_KEY -and $msix) {
  $full = (Select-String -Path pubspec.yaml -Pattern '^version: (.+)$').Matches[0].Groups[1].Value
  $repo = if ($env:CASAMA_RELEASES_REPO) { $env:CASAMA_RELEASES_REPO } else { "stackwares/casama-releases" }
  $digest = Join-Path $env:TEMP "casama-update.sha1"
  & openssl dgst -sha1 -binary -out $digest $msix.FullName
  $signature = (& openssl dgst -sha1 -sign $env:WINSPARKLE_KEY $digest | openssl enc -base64 -A)
  Remove-Item $digest
  $date = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss +0000", [Globalization.CultureInfo]::InvariantCulture)
  @"
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Casama</title>
    <item>
      <title>Casama $version</title>
      <sparkle:releaseNotesLink>https://github.com/$repo/releases/tag/v$version</sparkle:releaseNotesLink>
      <pubDate>$date</pubDate>
      <sparkle:version>$full</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <enclosure url="https://github.com/$repo/releases/download/v$version/$($msix.Name)" sparkle:dsaSignature="$signature" length="$($msix.Length)" type="application/octet-stream"/>
    </item>
  </channel>
</rss>
"@ | Set-Content -Encoding UTF8 ..\dist\appcast-windows.xml
  Write-Output "..\dist\appcast-windows.xml"
}

