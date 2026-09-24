# kmoneil/homebrew-tap

A Homebrew tap for the tools in this account.

```console
$ brew tap kmoneil/tap
```

## Formulae

### `jr`

A Jira client whose output is a versioned contract, built for scripts and agents
first and humans second. [kmoneil/jr](https://github.com/kmoneil/jr).

```console
$ brew install kmoneil/tap/jr
$ jr version
```

The formula also installs jr's agent skill, written by the binary it installs.
Homebrew does not write into your home directory, so link it into Claude Code's
skills once:

```console
$ mkdir -p ~/.claude/skills
$ ln -s "$(brew --prefix)/opt/jr/share/jr/skill" ~/.claude/skills/jr
```

From then on every `brew upgrade` moves the skill with the binary. If
`~/.claude/skills/jr` is already a directory, remove it first.

This installs the **full** profile. Every release also carries `jr-agent`,
`jr-reader` and `jr-ci`, which are the same tool with capabilities compiled out
rather than switched off, and those are fetched as tarballs from
[the releases page](https://github.com/kmoneil/jr/releases) rather than through
this tap. `jr-reader` is the one to hand an agent: it cannot change anything in
Jira, because it does not contain the code that could.

Installing through Homebrew also sidesteps macOS Gatekeeper. `brew` fetches with
`curl`, which never attaches `com.apple.quarantine`, so the released binaries do
not need an Apple Developer ID signature to run. Downloading the same tarball
through a browser does attach it, and
[the troubleshooting guide](https://github.com/kmoneil/jr/blob/main/docs/troubleshooting.md#it-will-not-start)
covers that case.

### `hunk`

A transactional multi-file text editor for coding agents: every edit must match
exactly as many times as it claims, or nothing is written.
[kmoneil/hunk](https://github.com/kmoneil/hunk).

```console
$ brew install kmoneil/tap/hunk
$ hunk --version
```

The full name is not optional here. Homebrew core has an unrelated formula
called `hunk`, a diff viewer, and `brew install hunk` installs that one. The two
cannot be installed at once.

The formula also installs hunk's agent skill, from the same release as the
binary. Homebrew does not write into your home directory, so link it into
Claude Code's skills once:

```console
$ mkdir -p ~/.claude/skills
$ ln -s "$(brew --prefix)/opt/hunk/share/hunk/skill" ~/.claude/skills/hunk
```

From then on every `brew upgrade` moves the skill with the binary. If
`~/.claude/skills/hunk` is already a directory, from `make install` in a clone,
remove it first.

### `gcp-cli`

An LLM-native Google Cloud CLI. [kmoneil/gcp-cli](https://github.com/kmoneil/gcp-cli).

```console
$ brew install kmoneil/tap/gcp-cli
```

## A note on layout

The formulae sit at the repository root rather than in a `Formula/` directory.
That is deliberate and it matters: Homebrew resolves a tap's formula directory
as the first of `Formula/`, `HomebrewFormula/`, or the repository root that
exists. Creating `Formula/` while any formula is still at the root would make
the root ones invisible, so moving them is one change that moves all of them.
