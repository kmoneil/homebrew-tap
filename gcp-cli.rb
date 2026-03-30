class GcpCli < Formula
  desc "LLM-native Google Cloud CLI"
  homepage "https://github.com/kmoneil/gcp-cli"
  version "0.5.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.5.0/gcp-cli-darwin-arm64"
      sha256 "f6557b0a06c280353193ff77bc579e2753794ff835c7423b652a0a34ff1e0ad4"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.5.0/gcp-cli-darwin-amd64"
      sha256 "a24a9e14089dedbc304bdcb2e441be33eb063a4fe25607b2a29534c19e0baa3d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.5.0/gcp-cli-linux-arm64"
      sha256 "e09c18f289c350f8055eb7e974af7bf883a15b26aec155a89772b3cb1dcbb915"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.5.0/gcp-cli-linux-amd64"
      sha256 "89c520a4ff7dd0a17d124c5af4fca52729215cec422a3ab9dbbc2fca813774d0"
    end
  end

  def install
    binary = Dir["gcp-cli-*"].first
    bin.install binary => "gcp-cli"
  end

  test do
    assert_match "gcp-cli", shell_output("#{bin}/gcp-cli --help")
  end
end
