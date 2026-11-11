#!/usr/bin/env bash
# Writes the Homebrew formula for a release from its checksum files.
# Usage: scripts/homebrew-formula.sh <version> <dir with casama-<v>-<os>-<arch>.tar.gz.sha256 files>
set -euo pipefail
v="$1"; dir="$2"
sum() { awk '{print $1}' "$dir/casama-$v-$1.tar.gz.sha256"; }
base="https://github.com/stackwares/casama/releases/download/cli-v$v"
cat <<RUBY
class Casama < Formula
  desc "Command-line client for Casama, the self-hostable home for AI bots with computers"
  homepage "https://github.com/stackwares/casama"
  version "$v"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "$base/casama-$v-darwin-arm64.tar.gz"
      sha256 "$(sum darwin-arm64)"
    end
    on_intel do
      url "$base/casama-$v-darwin-x64.tar.gz"
      sha256 "$(sum darwin-x64)"
    end
  end
  on_linux do
    on_arm do
      url "$base/casama-$v-linux-arm64.tar.gz"
      sha256 "$(sum linux-arm64)"
    end
    on_intel do
      url "$base/casama-$v-linux-x64.tar.gz"
      sha256 "$(sum linux-x64)"
    end
  end

  def install
    bin.install "casama"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/casama --version")
  end
end
RUBY
