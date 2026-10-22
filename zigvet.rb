class Zigvet < Formula
  desc "Things Zig compiles that are wrong"
  homepage "https://github.com/kmoneil/zigvet"
  license "Apache-2.0"

  # No `version` stanza. Homebrew scans it out of the release URL's
  # /releases/download/vX.Y.Z/ segment, and `brew audit` refuses a declaration
  # that agrees with what it already scanned.

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/zigvet/releases/download/v0.5.1/zigvet-darwin-arm64"
      sha256 "6b428ef5d3997191e29f45c2bc39c2b39662c1431f69786a6014a71fc4c842f0"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.5.1/zigvet-darwin-amd64"
      sha256 "0ca707345656e30032d573d1fc5ba484e199366ea5abb7c56807f063cd358e1d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/zigvet/releases/download/v0.5.1/zigvet-linux-arm64"
      sha256 "9ad6579b8831de629661772cb571c1d7d53bcf4145b15041c3d842f682894b57"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.5.1/zigvet-linux-amd64"
      sha256 "734bf9deac0165ae1b95857180d4b1fbe423a984b9de8167ca04d2c963df1074"
    end
  end

  def install
    # A release asset is a bare binary, and Homebrew keeps the mode curl gave
    # it, 0644. The cleaner then settles each file in bin on 0555 or 0444 by
    # whether it is already executable, so without this it installs as 0444.
    os = OS.mac? ? "darwin" : "linux"
    arch = Hardware::CPU.arm? ? "arm64" : "amd64"
    binary = "zigvet-#{os}-#{arch}"
    chmod 0755, binary
    bin.install binary => "zigvet"
  end

  test do
    # The version build.zig.zon gave the release, which has to be the version
    # this formula claims to have installed.
    assert_equal "zigvet #{version}", shell_output("#{bin}/zigvet --version").chomp

    # What the tool is for, and it needs no network: the address of an array
    # built at run time, returned, is reported with exit 1, and the same array
    # of comptime-known bytes is not.
    (testpath/"escape.zig").write <<~ZIG
      fn f(n: u8) []const u8 {
          return &.{n};
      }
    ZIG
    output = shell_output("#{bin}/zigvet #{testpath}/escape.zig", 1)
    assert_match "escape.zig:2:12: escape: anonymous array made here leaves f through return", output

    (testpath/"static.zig").write <<~ZIG
      fn f() []const u8 {
          return &.{ 1, 2 };
      }
    ZIG
    assert_empty shell_output("#{bin}/zigvet #{testpath}/static.zig")
  end
end
