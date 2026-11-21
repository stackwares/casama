#!/usr/bin/env bash
# Writes the Homebrew cask for a macOS desktop release.
# Usage: scripts/homebrew-cask.sh <version> <dmg-path-or-sha256>
set -euo pipefail
v="$1"
arg="$2"
if [[ -f "$arg" ]]; then
  sha=$(shasum -a 256 "$arg" | awk '{print $1}')
else
  sha="$arg"
fi
cat <<RUBY
cask "casama" do
  version "$v"
  sha256 "$sha"

  url "https://github.com/stackwares/casama-releases/releases/download/v#{version}/Casama-#{version}-macos.dmg"
  name "Casama"
  desc "Self-hostable home for AI teammates with their own computers"
  homepage "https://casama.ai/"

  livecheck do
    url "https://raw.githubusercontent.com/stackwares/casama-releases/main/appcast-macos.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :ventura

  app "Casama.app"

  zap trash: [
    "~/Library/Application Support/ai.casama.app",
    "~/Library/Caches/ai.casama.app",
    "~/Library/Caches/ai.casama.app.sparkle",
    "~/Library/Containers/ai.casama.app",
    "~/Library/Containers/ai.casama.app.CasamaWidgetsMac",
    "~/Library/Group Containers/V8V5US964Z.ai.casama.app",
    "~/Library/Preferences/ai.casama.app.plist",
    "~/Library/Saved Application State/ai.casama.app.savedState",
  ]
end
RUBY
