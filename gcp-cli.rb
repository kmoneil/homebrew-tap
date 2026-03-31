class GcpCli < Formula
  desc "LLM-native Google Cloud CLI"
  homepage "https://github.com/kmoneil/gcp-cli"
  version "0.6.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.6.0/gcp-cli-darwin-arm64"
      sha256 "caae9b18377da3682799d5e95e0b8e04384c8e9f43ea9ad9a9b6bd2c13622e02"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.6.0/gcp-cli-darwin-amd64"
      sha256 "24b72158976421c7e9f3a77d0fa59c772489a4ac333dbe3a9eed4fadf249627b"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.6.0/gcp-cli-linux-arm64"
      sha256 "fc1fb69820f8fa03e1148e480b7938ec1aa231d14f68893ca3a10db5a346d2ad"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.6.0/gcp-cli-linux-amd64"
      sha256 "f2926933370242aa9b8003fe0cfeacc9c364ac8efcd0a11bfa0f478f997be615"
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
