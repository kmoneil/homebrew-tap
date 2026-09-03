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
      url "https://github.com/kmoneil/jr/releases/download/v0.12.0/jr-full_0.12.0_darwin_arm64.tar.gz"
      sha256 "bdb3ebf7acebc5e580524fb1dbc4d2ffa706ea0a9c773f400cf6b6c1d47db626"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.12.0/jr-full_0.12.0_darwin_amd64.tar.gz"
      sha256 "1195711c0755f4b956e3d20fc22501571d801ca1bcaf3877c43115aa617b1ec0"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v0.12.0/jr-full_0.12.0_linux_arm64.tar.gz"
      sha256 "21680fa8227f83516257d8889d103f47774c81b5ae5e2f769e99f5ffdb031745"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.12.0/jr-full_0.12.0_linux_amd64.tar.gz"
      sha256 "948c5b401cf2bf0e6af7dd3a575e1b69186e92f61b56f13d9fdc79308794b38d"
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
  end
end
