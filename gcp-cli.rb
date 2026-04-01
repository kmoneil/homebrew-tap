class GcpCli < Formula
  desc "LLM-native Google Cloud CLI"
  homepage "https://github.com/kmoneil/gcp-cli"
  version "0.7.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.7.0/gcp-cli-darwin-arm64"
      sha256 "cda80007ae00f52d8d3b9695585a94616e12ff91b255f5ba6a89a40dffd6cc3d"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.7.0/gcp-cli-darwin-amd64"
      sha256 "ab26e0be342536d9e5a016b146f374db8a9a0d81578bcf8fb77bb1fd869f10ae"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.7.0/gcp-cli-linux-arm64"
      sha256 "c78ba76f06601754c2a5a7b56d56ab1666c79bf1df53f0dc766c25e093b0b340"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.7.0/gcp-cli-linux-amd64"
      sha256 "87c6dcca06b1079188f191465d499d191a9669ffd290c40bbf0f3e7b2289eb5a"
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
