class Yaml < Formula
  desc "Check YAML files, read values by path, and convert YAML to and from JSON"
  homepage "https://github.com/kmoneil/yaml.zig"
  license "MIT"

  # No `version` stanza. Homebrew scans it out of the release URL's
  # /releases/download/vX.Y.Z/ segment, and `brew audit` refuses a declaration
  # that agrees with what it already scanned.

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/yaml.zig/releases/download/v0.3.0/yaml-darwin-arm64"
      sha256 "7cef5652037a74e1bf86b348303b1157a1f174710a1be06d76df35137240a94e"
    else
      url "https://github.com/kmoneil/yaml.zig/releases/download/v0.3.0/yaml-darwin-amd64"
      sha256 "99526a682491e65abc2d745c7e5da5c706bcfa88493a969f10403515e4547fee"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/yaml.zig/releases/download/v0.3.0/yaml-linux-arm64"
      sha256 "37968c237cfbfea1f69a7440c75fe20d0c7f70686a3b3cc27bea37f6efc3b893"
    else
      url "https://github.com/kmoneil/yaml.zig/releases/download/v0.3.0/yaml-linux-amd64"
      sha256 "1f3a0eae07849d859795902c334e81eb0e5ee366fc9bfd062d732243cceddfb8"
    end
  end

  def install
    # A release asset is a bare binary, and Homebrew keeps the mode curl gave
    # it, 0644. The cleaner then settles each file in bin on 0555 or 0444 by
    # whether it is already executable, so without this it installs as 0444.
    os = OS.mac? ? "darwin" : "linux"
    arch = Hardware::CPU.arm? ? "arm64" : "amd64"
    binary = "yaml-#{os}-#{arch}"
    chmod 0755, binary
    bin.install binary => "yaml"
  end

  test do
    # The version build.zig.zon gave the release, which has to be the version
    # this formula claims to have installed.
    assert_equal "yaml #{version}", shell_output("#{bin}/yaml --version").chomp

    # What the tool is for, and it needs no network: read a value by path,
    # convert a document to JSON, and refuse a file whose mapping has a key
    # twice, saying so. The release workflow in kmoneil/yaml.zig runs the same
    # checks before it publishes, and changes when this does.
    (testpath/"good.yaml").write "name: web\nports: [80, 443]\n"
    assert_equal "web", shell_output("#{bin}/yaml get .name #{testpath}/good.yaml").chomp
    assert_equal '{"name":"web","ports":[80,443]}', shell_output("#{bin}/yaml json #{testpath}/good.yaml").chomp

    (testpath/"dup.yaml").write "a: 1\na: 2\n"
    output = shell_output("#{bin}/yaml check #{testpath}/dup.yaml 2>&1", 1)
    assert_match "a mapping cannot have two equal keys", output
  end
end
