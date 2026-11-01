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
      url "https://github.com/kmoneil/gnarl/releases/download/v0.4.0/gnarl-darwin-arm64"
      sha256 "1bae2c228f4a61df02789eaf06dd927d91be2f0f4004e3aa4ac98aabbfb047ef"
    else
      url "https://github.com/kmoneil/gnarl/releases/download/v0.4.0/gnarl-darwin-amd64"
      sha256 "0981ed7d15e0abe4bbc6f589332721fbb4ab04a031037fabdb8550315c29fe7c"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gnarl/releases/download/v0.4.0/gnarl-linux-arm64"
      sha256 "b78212d80def589cef42249902d98a1389409c811b8a681a93c3da4bebe18dee"
    else
      url "https://github.com/kmoneil/gnarl/releases/download/v0.4.0/gnarl-linux-amd64"
      sha256 "e18abdd2c6bbeb7ab386c07c201e060c462b41d88f741e29a01b2c922a13139f"
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
    output = shell_output("#{bin}/gnarl --all --format tsv #{testpath}/pick.zig")
    assert_match(/\tpick\tfn\tnormal\t3\t2\t3\t1\t2\t2\t$/, output)

    # And the gate: sixteen ifs are cyclomatic 17, over the critical limit of
    # 15, so --check fails and says so.
    branches = (1..16).map { |i| "    if (x == #{i}) n += 1;\n" }.join
    (testpath/"many.zig").write "fn many(x: u8) u8 {\n    var n: u8 = 0;\n#{branches}    return n;\n}\n"
    output = shell_output("#{bin}/gnarl --check #{testpath}/many.zig 2>&1", 1)
    assert_match "--check: 1 function over a critical threshold", output
  end
end
