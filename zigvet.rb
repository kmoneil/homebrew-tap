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
      url "https://github.com/kmoneil/zigvet/releases/download/v0.17.0/zigvet-darwin-arm64"
      sha256 "298ae195b4d94df61319adac7f543550b00feeeaff5bfd50b946e7d9793e3253"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.17.0/zigvet-darwin-amd64"
      sha256 "c49a6f12ebc95b4d8115eaf185575c0826a58a4d89684e70a670652af4c32090"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/zigvet/releases/download/v0.17.0/zigvet-linux-arm64"
      sha256 "1392fce40760a97913dd76bc951856cc2849fc28d849bdca9fdf873b5b5de541"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.17.0/zigvet-linux-amd64"
      sha256 "1a1750ca58f35800a7a7d07c8a072ae6c402f3457a4d2763c0bcc0a8ff672ed8"
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
