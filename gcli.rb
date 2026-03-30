class Gcli < Formula
  desc "LLM-native Google Cloud CLI"
  homepage "https://github.com/kmoneil/gcli"
  version "0.2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcli/releases/download/v0.2.0/gcli-darwin-arm64"
      sha256 "44c8b15f98c3f7f8ee153f23bff8f748bc60b5643a3ba887561ab15ff98d8226"
    else
      url "https://github.com/kmoneil/gcli/releases/download/v0.2.0/gcli-darwin-amd64"
      sha256 "ad8bbd78412e8201bdd0f4ea49f4737efb27d1db34b79689fc2090963c35ea40"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gcli/releases/download/v0.2.0/gcli-linux-arm64"
      sha256 "e90869c61aa6839692cdafaaf296ed7999f6678be5583d6286728b4a958a67c0"
    else
      url "https://github.com/kmoneil/gcli/releases/download/v0.2.0/gcli-linux-amd64"
      sha256 "0b2ba755ee2d24faf39dc375a96c09486baa293ed53127b83853c53ad0ab7087"
    end
  end

  def install
    binary = Dir["gcli-*"].first
    bin.install binary => "gcli"
  end

  test do
    assert_match "gcli", shell_output("#{bin}/gcli --help")
  end
end
