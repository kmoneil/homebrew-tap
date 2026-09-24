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
      url "https://github.com/kmoneil/jr/releases/download/v0.17.2/jr-full_0.17.2_darwin_arm64.tar.gz"
      sha256 "9c9ca713d4e8c7c2f1b06a3f4809f9f8cc8991ca72615df36f60d8f4f3806e6a"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.17.2/jr-full_0.17.2_darwin_amd64.tar.gz"
      sha256 "0db66097dc2fa0cc2959676851bcb59dfb0986bebe3ce42b09b326392630b672"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v0.17.2/jr-full_0.17.2_linux_arm64.tar.gz"
      sha256 "63fa01b71c81da373bff1ebe1bd0ffaa2cb7ca2875d246613ca6717bd4de86ac"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.17.2/jr-full_0.17.2_linux_amd64.tar.gz"
      sha256 "16ba807e1264d07b7035f6547b3fad4885129f340bdd57dfcf57969978efc2a7"
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
      Homebrew does not write into your home directory, so link it into
      Claude Code's skills once, and every upgrade moves it with the binary:
        mkdir -p ~/.claude/skills
        ln -s #{opt_pkgshare}/skill ~/.claude/skills/jr
      If ~/.claude/skills/jr is already a directory, remove it first.
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
