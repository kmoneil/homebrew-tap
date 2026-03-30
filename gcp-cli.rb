class GcpCli < Formula
  desc "LLM-native Google Cloud CLI"
  homepage "https://github.com/kmoneil/gcp-cli"
  version "0.3.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.3.0/gcp-cli-darwin-arm64"
      sha256 "eead28098f65f383399318bcce6e1a3892e01ed8d42f63d808238c45dbb32262"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.3.0/gcp-cli-darwin-amd64"
      sha256 "07df80981a08c5affa971ca1069de584dfc750442380ed5fccf76ab7a7ca2440"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.3.0/gcp-cli-linux-arm64"
      sha256 "f399df30a77cd5292cb3a1d7c9f9bbf80507e301c97b7a10490add7c8f5218b8"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.3.0/gcp-cli-linux-amd64"
      sha256 "3f336be7591771fd0442e42b64517a6cd77eb0a63d81c5269ba3db909d0c7a85"
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
