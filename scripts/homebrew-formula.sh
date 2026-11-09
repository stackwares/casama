#!/usr/bin/env bash
# Writes the Homebrew formula for a release from its checksum files.
# Usage: scripts/homebrew-formula.sh <version> <dir with kasama-<v>-<os>-<arch>.tar.gz.sha256 files>
set -euo pipefail
v="$1"; dir="$2"
sum() { awk '{print $1}' "$dir/kasama-$v-$1.tar.gz.sha256"; }
base="https://github.com/stackwares/kasama/releases/download/cli-v$v"
cat <<RUBY
class Kasama < Formula
  desc "Command-line client for Kasama, the self-hostable home for AI bots with computers"
  homepage "https://github.com/stackwares/kasama"
  version "$v"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "$base/kasama-$v-darwin-arm64.tar.gz"
      sha256 "$(sum darwin-arm64)"
    end
    on_intel do
      url "$base/kasama-$v-darwin-x64.tar.gz"
      sha256 "$(sum darwin-x64)"
    end
  end
  on_linux do
    on_arm do
      url "$base/kasama-$v-linux-arm64.tar.gz"
      sha256 "$(sum linux-arm64)"
    end
    on_intel do
      url "$base/kasama-$v-linux-x64.tar.gz"
      sha256 "$(sum linux-x64)"
    end
  end

  def install
    bin.install "kasama"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kasama --version")
  end
end
RUBY
