class Jr < Formula
  desc "Jira client whose output is a versioned contract, for scripts and agents"
  homepage "https://github.com/kmoneil/jr"
  license "Apache-2.0"

  # No `version` stanza. Homebrew scans it out of the release URL, and `brew
  # audit` refuses a declaration that agrees with what it already scanned:
  # "version 0.10.2 is redundant with version scanned from URL". gcp-cli.rb
  # declares one because its URLs name a bare binary with no version in it.

  livecheck do
    url :stable
    strategy :github_latest
  end

  # This is the full profile. Every release also carries jr-agent, jr-reader and
  # jr-ci, which are the same tool with capabilities compiled out rather than
  # switched off. They are deliberately not in this tap: the machine running
  # `brew install` belongs to a person, and the restricted profiles exist for
  # containers, which fetch the tarball directly.
  # See https://github.com/kmoneil/jr/blob/main/docs/build-profiles.md

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v0.18.0/jr-full_0.18.0_darwin_arm64.tar.gz"
      sha256 "60ec7c35bade28b015b849b2a96dd9a7b69bc006dd3e82157caae1c8a17c6318"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.18.0/jr-full_0.18.0_darwin_amd64.tar.gz"
      sha256 "36382402db7a1fe7ebad97c0a0f08d849118652e940bb3b25dad1b63cd681e90"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v0.18.0/jr-full_0.18.0_linux_arm64.tar.gz"
      sha256 "dcc8e9fa5495dc949854568bfb239d68a8e47ecd03e56147f4ff53a07dd53d15"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.18.0/jr-full_0.18.0_linux_amd64.tar.gz"
      sha256 "70ad78537b969f8a6ca54336b06ac233ecd8e909f9e6e09d518eee68565a78ac"
    end
  end

  def install
    bin.install "jr"

    # Apache 2.0 section 4(d): the NOTICE travels with the distribution.
    prefix.install "LICENSE", "NOTICE"
    doc.install "README.md"

    # `jr completion <shell>` writes the script to stdout and nothing else, with
    # no result envelope, which is exactly the shape this helper expects.
    generate_completions_from_executable(bin/"jr", "completion")

    # The agent skill, written by the binary just installed, so the skill a
    # user links always describes the binary they have. `jr skill --dir` writes
    # SKILL.md and every reference, the bytes `jr skill` prints, so this formula
    # does not need to know which references there are.
    system bin/"jr", "skill", "--dir", pkgshare/"skill"
  end

  def caveats
    <<~EOS
      jr's agent skill is installed at:
        #{opt_pkgshare}/skill
      Homebrew does not write into your home directory, so link it once into
      the cross-agent folder (Codex, Cursor, Gemini CLI and most others read
      it) and into Claude Code's; every upgrade then moves both with the
      binary:
        mkdir -p ~/.agents/skills ~/.claude/skills
        ln -s #{opt_pkgshare}/skill ~/.agents/skills/jr
        ln -s #{opt_pkgshare}/skill ~/.claude/skills/jr
      If either destination is already a directory, remove it first.
    EOS
  end

  test do
    # The same assertion the release workflow makes on every tag: the binary has
    # to report the version this formula claims to have installed. A release
    # whose `jr version` disagrees with the tag is unpinnable, which is the thing
    # the tool's whole output contract exists to prevent.
    assert_match "@release\t#{version}", shell_output("#{bin}/jr version --format tsv")

    # Needs no credential, no configuration and no network, and it asserts the
    # behaviour the tool exists for: the truncation warning goes to stderr,
    # stdout stays parseable, and the exit code says the result was cut short.
    assert_match "auth.login", shell_output("#{bin}/jr schema --limit 3", 3)

    # The installed skill is the one this binary prints, which is the whole
    # reason it is written at install rather than shipped beside the archive.
    assert_equal shell_output("#{bin}/jr skill"), (pkgshare/"skill/SKILL.md").read
    assert_path_exists pkgshare/"skill/references"
  end
end
