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
      url "https://github.com/kmoneil/yaml.zig/releases/download/v0.1.0/yaml-darwin-arm64"
      sha256 "be9134dd38f4f66098b3615fd37c8914b798887af7994cae0183792601e939dd"
    else
      url "https://github.com/kmoneil/yaml.zig/releases/download/v0.1.0/yaml-darwin-amd64"
      sha256 "d39d7dc9f05e0709df7ea6d4b75e60c35ac424fa95a564bbb79963a195a44b6f"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/yaml.zig/releases/download/v0.1.0/yaml-linux-arm64"
      sha256 "a2d8f8bda9464724b014ad8b57b55e1717b571c57bdadfbaaabe1953149abbbf"
    else
      url "https://github.com/kmoneil/yaml.zig/releases/download/v0.1.0/yaml-linux-amd64"
      sha256 "141cf0879c151e957e3a2197705934550da6c0187d1e6de2a6e5743db80299f0"
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
