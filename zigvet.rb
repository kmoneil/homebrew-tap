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
      url "https://github.com/kmoneil/zigvet/releases/download/v0.20.0/zigvet-darwin-arm64"
      sha256 "e7be3e403531739e69f9e75bf59d77338320fa0dd496603dbce900bf9b745f33"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.20.0/zigvet-darwin-amd64"
      sha256 "7f9fbf74d16ed712ef4b8745883152c8034b83e597378c8629187b5443b75848"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/zigvet/releases/download/v0.20.0/zigvet-linux-arm64"
      sha256 "db8d16b1fbef6653a6ec834939c47d763a4656aa39771775f74029a4dc9648b1"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.20.0/zigvet-linux-amd64"
      sha256 "feab088680cb7cca1ad518e272ea45417b6a63dc5c444087186775ca93c46e04"
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
