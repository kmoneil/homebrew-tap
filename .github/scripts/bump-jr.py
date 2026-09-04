#!/usr/bin/env python3
"""Point jr.rb at a jr release, and refuse to do it on anything unverified.

The formula names four archives, one per platform, each with the digest
Homebrew checks after downloading it. A bump is those eight lines and nothing
else, which is exactly the kind of edit a person gets right four times and
wrong on the fifth.

What this does that a careful person also did by hand, every time, is the
reason it is a script rather than a sed line: each digest is read from the
release's checksums.txt *and* re-derived from the archive downloaded from the
URL the formula will carry. checksums.txt is published by the same workflow
that built the archives, so believing it alone is believing one source twice.
Hashing the download proves the bytes a user will fetch are the bytes the
manifest names.

It writes nothing until every check has passed, so a failure leaves the
formula alone rather than half-edited.
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

# The four platforms the formula carries. Homebrew picks one at install time;
# the tap ships the full profile only, so the product is jr-full.
PLATFORMS = [("darwin", "arm64"), ("darwin", "amd64"), ("linux", "arm64"), ("linux", "amd64")]

URL_LINE = re.compile(
    r'^(?P<indent>\s*)url "https://github\.com/(?P<repo>[^/"]+/[^/"]+)'
    r'/releases/download/(?P<tag>v[^/"]+)/(?P<archive>jr-full_[^"/]+\.tar\.gz)"\s*$'
)
SHA_LINE = re.compile(r'^(?P<indent>\s*)sha256 "(?P<digest>[0-9a-f]{64})"\s*$')
ARCHIVE = re.compile(r"^jr-full_(?P<version>.+)_(?P<os>[a-z0-9]+)_(?P<arch>[a-z0-9]+)\.tar\.gz$")


class Refused(Exception):
    """A check failed. The formula is not written."""


def fetch(url: str, dest: Path | None = None) -> bytes:
    """Read a URL, saving it when asked. A release asset is public: no token."""
    try:
        with urllib.request.urlopen(url) as response:  # noqa: S310 - https, fixed host
            data = response.read()
    except urllib.error.HTTPError as err:
        raise Refused(f"{url} answered {err.code} {err.reason}") from err
    except urllib.error.URLError as err:
        raise Refused(f"{url} could not be reached: {err.reason}") from err
    if dest is not None:
        dest.write_bytes(data)
    return data


def read_checksums(text: str) -> dict[str, str]:
    """Parse `sha256sum` output into archive name -> digest."""
    out: dict[str, str] = {}
    for line in text.splitlines():
        parts = line.split()
        if len(parts) != 2:
            continue
        digest, name = parts[0], parts[1].lstrip("*")
        if re.fullmatch(r"[0-9a-f]{64}", digest):
            out[name] = digest
    if not out:
        raise Refused("checksums.txt held no digests, so nothing could be checked against it")
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
            raise Refused(f"line {i + 1} names an archive with no sha256 under it: {line.strip()}")
        pairs.append((i, url, i + 1))
    return pairs


def plan(formula: Path, tag: str, repo: str) -> tuple[str, list[tuple[str, str, str]]]:
    """Work out the new formula text without writing it."""
    version = tag.removeprefix("v")
    lines = formula.read_text().splitlines(keepends=True)
    pairs = find_pairs(lines)

    if len(pairs) != len(PLATFORMS):
        raise Refused(
            f"{formula} names {len(pairs)} archives and this script knows "
            f"{len(PLATFORMS)}. The formula's shape moved; read it before bumping it"
        )

    seen: set[tuple[str, str]] = set()
    wanted: list[tuple[int, int, str]] = []
    for line_no, url, sha_no in pairs:
        if url["repo"] != repo:
            raise Refused(f"line {line_no + 1} points at {url['repo']}, not {repo}")
        archive = ARCHIVE.match(url["archive"])
        if not archive:
            raise Refused(f"line {line_no + 1} names an archive this script cannot read")
        key = (archive["os"], archive["arch"])
        if key in seen:
            raise Refused(f"{key[0]}/{key[1]} is named twice")
        seen.add(key)
        wanted.append((line_no, sha_no, f"jr-full_{version}_{key[0]}_{key[1]}.tar.gz"))

    missing = set(PLATFORMS) - seen
    if missing:
        raise Refused(f"the formula names no archive for {sorted(missing)}")

    base = f"https://github.com/{repo}/releases/download/{tag}"
    published = read_checksums(fetch(f"{base}/checksums.txt").decode())

    downloads = Path(os.environ.get("JR_DOWNLOAD_DIR", "dist"))
    downloads.mkdir(parents=True, exist_ok=True)

    changed: list[tuple[str, str, str]] = []
    for line_no, sha_no, archive in wanted:
        if archive not in published:
            raise Refused(f"{tag} publishes no {archive}")
        want = published[archive]
        url = f"{base}/{archive}"
        got = hashlib.sha256(fetch(url, downloads / archive)).hexdigest()
        if got != want:
            # The manifest and the bytes behind the URL disagree. Whichever is
            # wrong, the formula must carry neither.
            raise Refused(
                f"{archive} hashes to {got} and checksums.txt says {want}. "
                "The archive and the manifest disagree; nothing is written"
            )
        indent = URL_LINE.match(lines[line_no])["indent"]
        lines[line_no] = f'{indent}url "{url}"\n'
        lines[sha_no] = f'{SHA_LINE.match(lines[sha_no])["indent"]}sha256 "{want}"\n'
        changed.append((archive, want, url))

    return "".join(lines), changed


def emit(name: str, value: str) -> None:
    """Report to the workflow, when there is one to report to."""
    path = os.environ.get("GITHUB_OUTPUT")
    if path:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(f"{name}={value}\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--tag", required=True, help="the jr tag to point at, e.g. v0.13.2")
    ap.add_argument("--formula", default="jr.rb", type=Path)
    ap.add_argument("--repo", default="kmoneil/jr")
    ap.add_argument(
        "--check",
        action="store_true",
        help="say what would change and write nothing",
    )
    args = ap.parse_args()

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

    if text == args.formula.read_text():
        # Idempotent on purpose: a re-run of a release workflow dispatches
        # again, and the second one has nothing to do rather than something to
        # undo.
        print(f"jr.rb already points at {version}; nothing to do")
        emit("changed", "false")
        return 0

    for archive, digest, _ in changed:
        print(f"{archive}  {digest}")
    emit("changed", "true")

    if args.check:
        print("--check: the formula is unchanged on disk")
        return 0

    args.formula.write_text(text)
    print(f"jr.rb now points at {version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
