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
      url "https://github.com/kmoneil/hunk/releases/download/v0.2.8/hunk-darwin-arm64"
      sha256 "7f03c06150581de89c1e1352646e3b9eb7a3f877a87ed295ead3d07ccbc40d8f"
    else
      url "https://github.com/kmoneil/hunk/releases/download/v0.2.8/hunk-darwin-amd64"
      sha256 "0df5c901bd2f32eb2cb136ebe2edff7fa7f7f7de9b79913e8b65fd92e9a9c037"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/hunk/releases/download/v0.2.8/hunk-linux-arm64"
      sha256 "63f4ccd74a9f011a6630b03e9507fad8b058fe997229033146f363c4a0d32f6d"
    else
      url "https://github.com/kmoneil/hunk/releases/download/v0.2.8/hunk-linux-amd64"
      sha256 "c014c8e36249903b989d61e3da90da378a45613ad999e179ee061a8c6420a149"
    end
  end

  # The agent skill, from the same release as the binary, so the skill a user
  # has always describes the binary they have.
  resource "skill" do
    url "https://github.com/kmoneil/hunk/releases/download/v0.2.8/hunk-skill.tar.gz"
    sha256 "cace63b86b1f6b3ff8bd4937a9df408175a057414dbbf3034bff14f06679446e"
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
      Homebrew does not write into your home directory, so link it into
      Claude Code's skills once, and every upgrade moves it with the binary:
        mkdir -p ~/.claude/skills
        ln -s #{opt_pkgshare}/skill ~/.claude/skills/hunk
      If ~/.claude/skills/hunk is already a directory, remove it first.
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
