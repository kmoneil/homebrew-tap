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
      url "https://github.com/kmoneil/gnarl/releases/download/v0.8.0/gnarl-darwin-arm64"
      sha256 "38bb3cf678922473e1677e69dfd8a7373f373ccfb6e1ec50bb7dfebae380c799"
    else
      url "https://github.com/kmoneil/gnarl/releases/download/v0.8.0/gnarl-darwin-amd64"
      sha256 "d168480138e10b3cbb7662592666d7c158cd5e027e70c3523b5bb0d3c81b71ce"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/gnarl/releases/download/v0.8.0/gnarl-linux-arm64"
      sha256 "d4d1677447104f45e9d969fd16e2d60d8f82f5d37de2c275980cc7cdc35a5ceb"
    else
      url "https://github.com/kmoneil/gnarl/releases/download/v0.8.0/gnarl-linux-amd64"
      sha256 "9575569ffc6b31a4a271c936fa206e68142e3cbd6419c6f3c90f2325c21553e1"
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
