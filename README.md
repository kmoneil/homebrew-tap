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
