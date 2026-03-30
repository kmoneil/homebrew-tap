class GcpCli < Formula
  desc "LLM-native Google Cloud CLI"
  homepage "https://github.com/kmoneil/gcp-cli"
  version "0.3.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.3.0/gcp-cli-darwin-arm64"
      sha256 "0c55a78339ed25889492784bc1e425fd748b65ddf249c71b8c7a4039cea119f0"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.3.0/gcp-cli-darwin-amd64"
      sha256 "bb4146bb38e81455608d93d0839f420b1bc82ecc7532e7a222f9ed4b933f5aac"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.3.0/gcp-cli-linux-arm64"
      sha256 "9c925fe356d8fac706db222f644c70dae68fed22703b486df43bb02c1ea495d6"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.3.0/gcp-cli-linux-amd64"
      sha256 "9f5891e17554508c2317dd195e066180b67e36af9b61e776d66000f2d6199a4d"
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
