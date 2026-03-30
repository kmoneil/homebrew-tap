class GcpCli < Formula
  desc "LLM-native Google Cloud CLI"
  homepage "https://github.com/kmoneil/gcp-cli"
  version "0.4.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.4.0/gcp-cli-darwin-arm64"
      sha256 "fdab7c99d1d777640936ff2d262539d0062ef8356057215ea90db7ba6ff5910e"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.4.0/gcp-cli-darwin-amd64"
      sha256 "cead1b12f3cd71c51c7bb1c3bf166675c8ed72bf909ce1cb98b8ba18e1388a62"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.4.0/gcp-cli-linux-arm64"
      sha256 "9c94272fe6ea6c364ca8e98de8150698c4426773e053ec53d44c9731a7528e1d"
    else
      url "https://github.com/kmoneil/gcp-cli/releases/download/v0.4.0/gcp-cli-linux-amd64"
      sha256 "8890060b0fc3992fa6382884f84e01ecf65849318c519ab05e747a4c02ff9bd3"
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
