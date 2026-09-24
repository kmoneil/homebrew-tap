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

It installs three things: the **full** profile's `jr`, its shell completions
for bash, zsh and fish, and its agent skill. The next step is `jr auth login`,
which [getting started](https://github.com/kmoneil/jr/blob/main/docs/getting-started.md)
walks through, token and all.

**The skill** is written at install by the binary the formula installs, with
`jr skill --dir`, so it always describes the binary you have. Homebrew does not
write into your home directory, so link it once, into the cross-agent folder
(`~/.agents/skills`, read by Codex, Cursor, Gemini CLI and most other loaders)
and into Claude Code's:

```console
$ mkdir -p ~/.agents/skills ~/.claude/skills
$ ln -s "$(brew --prefix)/opt/jr/share/jr/skill" ~/.agents/skills/jr
$ ln -s "$(brew --prefix)/opt/jr/share/jr/skill" ~/.claude/skills/jr
```

From then on every `brew upgrade` moves the skill with the binary. If either
destination is already a directory, remove it first.

**The other profiles.** Every release also carries `jr-agent`, `jr-reader` and
`jr-ci`, which are the same tool with capabilities compiled out rather than
switched off, and those are fetched as archives from
[the releases page](https://github.com/kmoneil/jr/releases) rather than through
this tap. `jr-reader` is the one to hand an agent: it cannot change anything in
Jira, because it does not contain the code that could.

**On Windows**, jr is in [kmoneil/scoop-bucket](https://github.com/kmoneil/scoop-bucket)
rather than here: `scoop install kmoneil/jr`, with the skill written into
`~\.agents\skills\jr` and `~\.claude\skills\jr` for you.

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

## How it stays current

Each jr and hunk release tells this repository that it exists, with a
`jr-released` or `hunk-released` dispatch, and `bump-jr.yml` or `bump-hunk.yml`
runs the jobs every formula shares, in `bump-formula.yml`:

1. rewrite the formula's URLs and digests, reading each digest from the
   release's own manifest and re-deriving it from the file downloaded from the
   URL the formula will carry;
2. for jr, verify that every archive carries build provenance from jr's release
   workflow, built from the tag, on a runner GitHub hosts;
3. commit that to a branch, and audit, install and test the branch on a macOS
   runner, where the installed binary has to report the version asked for;
4. only then fast-forward `main`.

A failed bump keeps its branch as the evidence, and `main` keeps the previous
release. `brew.yml` audits, installs and tests every formula on every change.

## A note on layout

The formulae sit at the repository root rather than in a `Formula/` directory.
That is deliberate and it matters: Homebrew resolves a tap's formula directory
as the first of `Formula/`, `HomebrewFormula/`, or the repository root that
exists. Creating `Formula/` while any formula is still at the root would make
the root ones invisible, so moving them is one change that moves all of them.
