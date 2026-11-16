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
      url "https://github.com/kmoneil/zigvet/releases/download/v0.28.0/zigvet-darwin-arm64"
      sha256 "dbae3146eebcaa180089cdefc72cc26447b30655d8638509b3f8fa856cabb3de"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.28.0/zigvet-darwin-amd64"
      sha256 "d38e7d645c091344f2c2ee05560220a2d334d26d4cd3c6391e6241f0f8aad3af"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/zigvet/releases/download/v0.28.0/zigvet-linux-arm64"
      sha256 "5d9aaacaf02dd151dd1f0319f3de0443d0381b87581406e9980360e0ca47ca14"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.28.0/zigvet-linux-amd64"
      sha256 "9bda33ab6a081407e68149f62dd1878f05a077a791898788c5f29ab88c072fbc"
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
