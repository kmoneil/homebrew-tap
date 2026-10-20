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
      url "https://github.com/kmoneil/zigvet/releases/download/v0.1.1/zigvet-darwin-arm64"
      sha256 "ff421318b7bf1adebc4fc461c50654fa03e2aed9b5e63dfb47925aff6d180030"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.1.1/zigvet-darwin-amd64"
      sha256 "f22d6ce2461a32a00177ddaac51fd445df3b7ab876b874bed7ad2e1350397576"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/zigvet/releases/download/v0.1.1/zigvet-linux-arm64"
      sha256 "ab344d09f54f02e571d4a0dd46af1544be9199e3bbf2273d36e9f036026badd1"
    else
      url "https://github.com/kmoneil/zigvet/releases/download/v0.1.1/zigvet-linux-amd64"
      sha256 "f369324165e57175a60b7a47c21d4c2abe711b6ad8e33a532ad35e9fe31c0932"
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
