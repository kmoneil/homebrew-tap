class Jr < Formula
  desc "Jira client whose output is a versioned contract, for scripts and agents"
  homepage "https://github.com/kmoneil/jr"
  version "0.10.1"
  license "Apache-2.0"

  # This is the full profile. Every release also carries jr-agent, jr-reader and
  # jr-ci, which are the same tool with capabilities compiled out rather than
  # switched off. They are deliberately not in this tap: the machine running
  # `brew install` belongs to a person, and the restricted profiles exist for
  # containers, which fetch the tarball directly.
  # See https://github.com/kmoneil/jr/blob/main/docs/build-profiles.md

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v0.10.1/jr-full_0.10.1_darwin_arm64.tar.gz"
      sha256 "dc7b0b48c7357fb9b4fb2f0d036acbc7a8ca01382354f725526c1b76bd686fc0"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.10.1/jr-full_0.10.1_darwin_amd64.tar.gz"
      sha256 "7877f75e071b8ebaaca3a5418e2eb5290bb9c1887b39943253856bffe290c5bf"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v0.10.1/jr-full_0.10.1_linux_arm64.tar.gz"
      sha256 "55fccba04dd25b2f5435c416484d7c01bb8b825ce211f4452c6fd01825ab8846"
    else
      url "https://github.com/kmoneil/jr/releases/download/v0.10.1/jr-full_0.10.1_linux_amd64.tar.gz"
      sha256 "fd87edc40b98ce03fbb0bdd4d6f7461f43d0edc358035159ffd013ef3d2a7e41"
    end
  end

  livecheck do
    url :stable
    strategy :github_latest
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
