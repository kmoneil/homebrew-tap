class GcpCli < Formula
  desc "LLM-native Google Cloud CLI"
  homepage "https://github.com/kmoneil/gcp-cli"
  version "0.8.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.8.0/gcp-cli-darwin-arm64"
      sha256 "a0312a38bc13fb73411058d662b8e2f91aba7288f5a14cfb3b79c0371061efb7"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.8.0/gcp-cli-darwin-amd64"
      sha256 "0869c8f2d3e8ed46565f1036ce8211c8a47141fb859eaff7bcbc7d9e84388a31"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.8.0/gcp-cli-linux-arm64"
      sha256 "2dae83f47927180df82610de38ef9da9b49bd3c9f55c767e70dfc060e88365c2"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.8.0/gcp-cli-linux-amd64"
      sha256 "796fe1599636e4b7a9feb386a3e79be0a60b17a25496a44955b83a20a501d430"
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
