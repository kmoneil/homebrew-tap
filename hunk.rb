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
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.53/hunk-darwin-arm64"
      sha256 "2cc1112851fc73f72137d9f12edf12a51a1475418104a3b2b516d8237b833690"
    else
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.53/hunk-darwin-amd64"
      sha256 "fcad579cb7e5b8293c6bc0a5fdb800402975b310bb8862300024f206591457b1"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.53/hunk-linux-arm64"
      sha256 "ad194b36595486e4a1e1c39b958c7e1c511782756f1e6275404f6ad2c56fa1b6"
    else
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.53/hunk-linux-amd64"
      sha256 "172db62dcd5cc2075d529f32290a601af0a97da0838b4dc97191b52d41dc7e2f"
    end
  end

  # The agent skill, from the same release as the binary, so the skill a user
  # has always describes the binary they have.
  resource "skill" do
    url "https://github.com/kmoneil/hunk/releases/download/v0.3.53/hunk-skill.tar.gz"
    sha256 "91d97663703b04e476f2e1901f4eba101ed13917822eebd85e507e5c75c6fd36"
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
      binary. The rm clears what an earlier install left there, since ln -s
      onto a folder puts the link inside it and says nothing:
        mkdir -p ~/.agents/skills ~/.claude/skills
        rm -rf ~/.agents/skills/hunk ~/.claude/skills/hunk
        ln -s #{opt_pkgshare}/skill ~/.agents/skills/hunk
        ln -s #{opt_pkgshare}/skill ~/.claude/skills/hunk
      Then readlink ~/.claude/skills/hunk prints the path above; if it prints
      nothing, the link is not there.
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
