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
      url "https://github.com/kmoneil/jr/releases/download/v0.13.2/jr-full_0.13.2_darwin_arm64.tar.gz"
      sha256 "a62b07dd84ab40865d39b103b55448f620186b48fb9ee22d0c90697c829ceccf"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.13.2/jr-full_0.13.2_darwin_amd64.tar.gz"
      sha256 "b5da1e5352502f8dfa5c59f778009bd56de039be7f158e2823ab4c2e97a52076"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v0.13.2/jr-full_0.13.2_linux_arm64.tar.gz"
      sha256 "2b3c235c552512e7d54a95862148720fb8c57a19aa8d9fc2ae6ea2f4ae2ffe32"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.13.2/jr-full_0.13.2_linux_amd64.tar.gz"
      sha256 "fd1fa9cf686ad80dfeda66fa7e3f1ae6e833901950e504fc0f38321a5bb4684e"
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
