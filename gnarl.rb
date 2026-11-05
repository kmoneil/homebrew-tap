class Gnarl < Formula
  desc "Per-function complexity for Zig that says why and where to cut"
  homepage "https://github.com/kmoneil/gnarl"
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
      url "https://github.com/kmoneil/gnarl/releases/download/v0.7.0/gnarl-darwin-arm64"
      sha256 "82ccdb87a5ef91ea2eff5b1e9cdc58f26e6a9563622bbadf457fb37f6f3311e8"
    else
      url "https://github.com/kmoneil/gnarl/releases/download/v0.7.0/gnarl-darwin-amd64"
      sha256 "64a94697c2abbc7f4fe9500ba68ce70e1e2954726f32939f665c9f3083b84b68"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gnarl/releases/download/v0.7.0/gnarl-linux-arm64"
      sha256 "c1579a8db3519d80b3f31735484182c5124098bffda50f493578ed30227428d7"
    else
      url "https://github.com/kmoneil/gnarl/releases/download/v0.7.0/gnarl-linux-amd64"
      sha256 "3b98843a610e74862a2e62edf3dbb2d35be3e74485718e703429c84f2b8e57f3"
    end
  end

  def install
    # A release asset is a bare binary, and Homebrew keeps the mode curl gave
    # it, 0644. The cleaner then settles each file in bin on 0555 or 0444 by
    # whether it is already executable, so without this it installs as 0444.
    os = OS.mac? ? "darwin" : "linux"
    arch = Hardware::CPU.arm? ? "arm64" : "amd64"
    binary = "gnarl-#{os}-#{arch}"
    chmod 0755, binary
    bin.install binary => "gnarl"
  end

  test do
    # The version build.zig.zon gave the release, which has to be the version
    # this formula claims to have installed.
    assert_equal "gnarl #{version}", shell_output("#{bin}/gnarl --version").chomp

    # What the tool is for, and it needs no network: an if and an `and` make
    # cyclomatic 3 and cognitive 2, in a function 3 lines long, nested 1
    # deep, with 2 parameters.
    (testpath/"pick.zig").write <<~ZIG
      fn pick(a: bool, b: bool) u8 {
          if (a and b) return 1;
          return 0;
      }
    ZIG
    # Its `over` column is empty, for it is within every limit; gnarl may
    # add columns after it, so the row is not matched to its end.
    output = shell_output("#{bin}/gnarl --all --format tsv #{testpath}/pick.zig")
    assert_match(/\tpick\tfn\tnormal\t3\t2\t3\t1\t2\t2\t(\t|$)/, output)

    # And the gate: sixteen ifs are cyclomatic 17, over the critical limit of
    # 15, so --check fails and says so.
    branches = (1..16).map { |i| "    if (x == #{i}) n += 1;\n" }.join
    (testpath/"many.zig").write "fn many(x: u8) u8 {\n    var n: u8 = 0;\n#{branches}    return n;\n}\n"
    output = shell_output("#{bin}/gnarl --check #{testpath}/many.zig 2>&1", 1)
    assert_match "--check: 1 function over a critical threshold", output
  end
end
