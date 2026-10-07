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
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.4/hunk-darwin-arm64"
      sha256 "14691b3bf0433d0a026469260c51941ab31da64c40789190dbfc1c6d0e6cfe0d"
    else
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.4/hunk-darwin-amd64"
      sha256 "ea2eb94ed7dadcc68130f1c5c62bec8a253f606b1539bf741adcd27f976b11ee"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.4/hunk-linux-arm64"
      sha256 "276dc9d53d37f2660904bf10d129d0081ebb971300c09dcfc283ab0e9cc9391f"
    else
      url "https://github.com/kmoneil/hunk/releases/download/v0.3.4/hunk-linux-amd64"
      sha256 "500cde602dc2cad49691d6589acf145457bcf6b4d89d4769082da1bff0599c7e"
    end
  end

  # The agent skill, from the same release as the binary, so the skill a user
  # has always describes the binary they have.
  resource "skill" do
    url "https://github.com/kmoneil/hunk/releases/download/v0.3.4/hunk-skill.tar.gz"
    sha256 "8aefe3167846742cdef77415622d422ccbadc031e92ce27cc261deb3c14950dc"
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
