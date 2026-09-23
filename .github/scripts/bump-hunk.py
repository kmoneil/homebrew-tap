#!/usr/bin/env python3
"""Point hunk.rb at a hunk release, and refuse to do it on anything unverified.

The formula names five files from one release: a bare binary for each of four
platforms, and the agent skill as a tarball. Each has the digest Homebrew checks
after downloading it. A bump is those ten lines and nothing else.

Each digest is read from the release's SHA256SUMS *and* re-derived from the file
downloaded from the URL the formula will carry. SHA256SUMS is published by the
same workflow that built the files, so believing it alone is believing one
source twice; hashing the download proves the bytes a user will fetch are the
bytes the manifest names.

It writes nothing until every check has passed, so a failure leaves the formula
alone rather than half-edited.

bump-jr.py does the same for jr. They are two scripts because the two releases
name their files differently, and one script that worked out which naming it was
looking at would be guessing, which is the thing both exist to stop.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

# Homebrew picks one binary at install time. The release also publishes Windows
# binaries, which no formula names.
PLATFORMS = [("darwin", "arm64"), ("darwin", "amd64"), ("linux", "arm64"), ("linux", "amd64")]
SKILL = "hunk-skill.tar.gz"
ASSETS = [f"hunk-{os}-{arch}" for os, arch in PLATFORMS] + [SKILL]

URL_LINE = re.compile(
    r'^(?P<indent>\s*)url "https://github\.com/(?P<repo>[^/"]+/[^/"]+)'
    r'/releases/download/(?P<tag>v[^/"]+)/(?P<asset>[^"/]+)"\s*$'
)
SHA_LINE = re.compile(r'^(?P<indent>\s*)sha256 "(?P<digest>[0-9a-f]{64})"\s*$')


class Refused(Exception):
    """A check failed. The formula is not written."""


def fetch(url: str) -> bytes:
    """Read a URL. A release asset is public: no token."""
    try:
        with urllib.request.urlopen(url) as response:  # noqa: S310 - https, fixed host
            return response.read()
    except urllib.error.HTTPError as err:
        raise Refused(f"{url} answered {err.code} {err.reason}") from err
    except urllib.error.URLError as err:
        raise Refused(f"{url} could not be reached: {err.reason}") from err


def read_checksums(text: str) -> dict[str, str]:
    """Parse `sha256sum` output into file name -> digest."""
    out: dict[str, str] = {}
    for line in text.splitlines():
        parts = line.split()
        if len(parts) != 2:
            continue
        digest, name = parts[0], parts[1].lstrip("*")
        if re.fullmatch(r"[0-9a-f]{64}", digest):
            out[name] = digest
    if not out:
        raise Refused("SHA256SUMS held no digests, so nothing could be checked against it")
    return out


def find_pairs(lines: list[str]) -> list[tuple[int, re.Match[str], int]]:
    """Locate every url line and the sha256 line under it.

    The sha256 must be the very next line. Homebrew writes them that way and so
    does this script; anything else is a formula whose shape has moved, and
    rewriting a shape nobody has looked at is how a bump silently pairs a URL
    with somebody else's digest.
    """
    pairs = []
    for i, line in enumerate(lines):
        url = URL_LINE.match(line)
        if not url:
            continue
        if i + 1 >= len(lines) or not SHA_LINE.match(lines[i + 1]):
            raise Refused(f"line {i + 1} names a file with no sha256 under it: {line.strip()}")
        pairs.append((i, url, i + 1))
    return pairs


def plan(formula: Path, tag: str, repo: str) -> tuple[str, list[tuple[str, str, str]]]:
    """Work out the new formula text without writing it."""
    lines = formula.read_text().splitlines(keepends=True)
    pairs = find_pairs(lines)

    if len(pairs) != len(ASSETS):
        raise Refused(
            f"{formula} names {len(pairs)} files and this script knows "
            f"{len(ASSETS)}. The formula's shape moved; read it before bumping it"
        )

    # Five known names, none twice, in five pairs: so each is there exactly once.
    seen: set[str] = set()
    for line_no, url, _ in pairs:
        if url["repo"] != repo:
            raise Refused(f"line {line_no + 1} points at {url['repo']}, not {repo}")
        if url["asset"] not in ASSETS:
            raise Refused(
                f"line {line_no + 1} names {url['asset']}, which is not a file this script knows"
            )
        if url["asset"] in seen:
            raise Refused(f"{url['asset']} is named twice")
        seen.add(url["asset"])

    base = f"https://github.com/{repo}/releases/download/{tag}"
    published = read_checksums(fetch(f"{base}/SHA256SUMS").decode())

    changed: list[tuple[str, str, str]] = []
    for line_no, url, sha_no in pairs:
        asset = url["asset"]
        if asset not in published:
            raise Refused(f"{tag} publishes no {asset}")
        want = published[asset]
        new_url = f"{base}/{asset}"
        got = hashlib.sha256(fetch(new_url)).hexdigest()
        if got != want:
            # The manifest and the bytes behind the URL disagree. Whichever is
            # wrong, the formula must carry neither.
            raise Refused(
                f"{asset} hashes to {got} and SHA256SUMS says {want}. "
                "The file and the manifest disagree; nothing is written"
            )
        lines[line_no] = f'{url["indent"]}url "{new_url}"\n'
        lines[sha_no] = f'{SHA_LINE.match(lines[sha_no])["indent"]}sha256 "{want}"\n'
        changed.append((asset, want, new_url))

    return "".join(lines), changed


def emit(name: str, value: str) -> None:
    """Report to the workflow, when there is one to report to."""
    path = os.environ.get("GITHUB_OUTPUT")
    if path:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(f"{name}={value}\n")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--tag", required=True, help="the hunk tag to point at, e.g. v0.2.8")
    ap.add_argument("--formula", default="hunk.rb", type=Path)
    ap.add_argument("--repo", default="kmoneil/hunk")
    ap.add_argument(
        "--check",
        action="store_true",
        help="say what would change and write nothing",
    )
    args = ap.parse_args(argv)

    # vX.Y.Z and nothing else: a prerelease is not something to install.
    if not re.fullmatch(r"v\d+\.\d+\.\d+", args.tag):
        print(f"refused: {args.tag} is not a release tag", file=sys.stderr)
        return 2

    try:
        text, changed = plan(args.formula, args.tag, args.repo)
    except Refused as err:
        print(f"refused: {err}", file=sys.stderr)
        return 1

    version = args.tag.removeprefix("v")
    emit("version", version)
    name = args.formula.name

    if text == args.formula.read_text():
        # Idempotent on purpose: a re-run of a release dispatches again, and the
        # second one has nothing to do rather than something to undo.
        print(f"{name} already points at {version}; nothing to do")
        emit("changed", "false")
        return 0

    for asset, digest, _ in changed:
        print(f"{asset}  {digest}")
    emit("changed", "true")

    if args.check:
        print("--check: the formula is unchanged on disk")
        return 0

    args.formula.write_text(text)
    print(f"{name} now points at {version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
