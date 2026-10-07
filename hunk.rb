class Hunk < Formula
  desc "Transactional multi-file text editor for coding agents"
  homepage "https://github.com/kmoneil/hunk"
  license "Apache-2.0"

  # No `version` stanza. Homebrew scans it out of the release URL's
  # /releases/download/vX.Y.Z/ segment, and `brew audit` refuses a declaration
  # that agrees with what it already scanned.

  livecheck do
    url :stable
    strategy :github_latest
  end

  # Homebrew core has an unrelated formula named hunk, a diff viewer, and a
  # short name finds core first. This one is only ever kmoneil/tap/hunk, and
  # the two cannot be installed at once.

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.5/hunk-darwin-arm64"
      sha256 "09d2da33168eae45e26e04aeaffdb95f34857ee1f41cd92b35aa8252dd724e81"
    else
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.5/hunk-darwin-amd64"
      sha256 "5ac0e842ac09d6855980e5182b763284e8416e8e1e7604d5a8658ae6a067d57e"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.5/hunk-linux-arm64"
      sha256 "328ac7bdd46767d0cd4a5410a5e616c6ad4084ba1e06e4133d4487acfd234509"
    else
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.5/hunk-linux-amd64"
      sha256 "48ad80a3e57aed12b2a88f4591ba1e1ed510c7176d64e7063c49a2874359d35a"
    end
  end

  # The agent skill, from the same release as the binary, so the skill a user
  # has always describes the binary they have.
  resource "skill" do
    url "https://github.com/kmoneil/hunk/releases/download/v0.3.5/hunk-skill.tar.gz"
    sha256 "f8b752735a05540a0387c8544cb22f59ce93d943ff90193a76abbc7151b7431c"
  end

  def install
    # A release asset is a bare binary, and Homebrew keeps the mode curl gave
    # it, 0644. The cleaner then settles each file in bin on 0555 or 0444 by
    # whether it is already executable, so without this it installs as 0444.
    os = OS.mac? ? "darwin" : "linux"
    arch = Hardware::CPU.arm? ? "arm64" : "amd64"
    binary = "hunk-#{os}-#{arch}"
    chmod 0755, binary
    bin.install binary => "hunk"

    resource("skill").stage { (pkgshare/"skill").install "SKILL.md", "references" }
  end

  def caveats
    <<~EOS
      hunk's agent skill is installed at:
        #{opt_pkgshare}/skill
      Homebrew does not write into your home directory, so link it once into
      the cross-agent folder (Codex, Cursor, Gemini CLI and most others read
      it) and into Claude Code's; every upgrade then moves both with the
      binary:
        mkdir -p ~/.agents/skills ~/.claude/skills
        ln -s #{opt_pkgshare}/skill ~/.agents/skills/hunk
        ln -s #{opt_pkgshare}/skill ~/.claude/skills/hunk
      If either destination is already a directory, remove it first.
    EOS
  end

  test do
    # The version the release workflow stamped into the binary, which has to
    # be the version this formula claims to have installed.
    assert_equal "hunk v#{version}", shell_output("#{bin}/hunk --version").chomp

    # What the tool is for, and it needs no network: text that is not there is
    # refused with exit 2 and nothing written, and text that is there once is
    # replaced.
    (testpath/"greeting.txt").write "hello\n"
    refused = pipe_output("#{bin}/hunk 2>&1", "@@ file greeting.txt\n@@ old\nmissing\n@@ new\nx\n", 2)
    assert_match "nothing was written", refused
    assert_equal "hello\n", (testpath/"greeting.txt").read

    pipe_output("#{bin}/hunk", "@@ file greeting.txt\n@@ old\nhello\n@@ new\ngoodbye\n", 0)
    assert_equal "goodbye\n", (testpath/"greeting.txt").read

    assert_path_exists pkgshare/"skill/SKILL.md"
  end
end
