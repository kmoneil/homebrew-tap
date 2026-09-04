#!/usr/bin/env python3
"""Tests for bump-jr.py, and mostly for the refusals.

The happy path is checked every release by the workflow that runs the script:
brew installs the formula it wrote and runs the binary. What that run cannot
show is a refusal, because a healthy release does not produce one. These do.

The digest test is the reason this file exists. Re-deriving each digest from
the archive is the script's one claim to being safer than a sed line, and a
check that has never failed and cannot be made to fail is not a check.
"""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

HERE = Path(__file__).parent
SPEC = importlib.util.spec_from_file_location("bump_jr", HERE / "bump-jr.py")
bump = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(bump)

FORMULA = """class Jr < Formula
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v1.0.0/jr-full_1.0.0_darwin_arm64.tar.gz"
      sha256 "{d}"
    else
      url "https://github.com/kmoneil/jr/releases/download/v1.0.0/jr-full_1.0.0_darwin_amd64.tar.gz"
      sha256 "{d}"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/kmoneil/jr/releases/download/v1.0.0/jr-full_1.0.0_linux_arm64.tar.gz"
      sha256 "{d}"
    else
      url "https://github.com/kmoneil/jr/releases/download/v1.0.0/jr-full_1.0.0_linux_amd64.tar.gz"
      sha256 "{d}"
    end
  end
end
""".format(d="0" * 64)

class Stub:
    """Stands in for the network. Serves a manifest and four archives."""

    def __init__(self, manifest: dict[str, str], body: bytes = b"archive"):
        self.manifest, self.body = manifest, body

    def __call__(self, url: str, dest: Path | None = None) -> bytes:
        if url.endswith("checksums.txt"):
            return "\n".join(f"{d}  {n}" for n, d in self.manifest.items()).encode()
        if dest is not None:
            dest.write_bytes(self.body)
        return self.body


def names(version: str) -> list[str]:
    return [
        f"jr-full_{version}_{os}_{arch}.tar.gz" for os, arch in bump.PLATFORMS
    ]


class BumpTest(unittest.TestCase):
    def setUp(self):
        self.formula = Path(self.enterContext(__import__("tempfile").TemporaryDirectory()))
        self.formula = self.formula / "jr.rb"
        self.formula.write_text(FORMULA)
        self.real = bump.hashlib.sha256(b"archive").hexdigest()
        self.addCleanup(setattr, bump, "fetch", bump.fetch)

    def use(self, manifest, body=b"archive"):
        bump.fetch = Stub(manifest, body)

    def test_a_manifest_the_archive_contradicts_is_refused(self):
        """The one that matters: checksums.txt says one thing, the bytes another."""
        self.use({n: "f" * 64 for n in names("2.0.0")})
        with self.assertRaises(bump.Refused) as caught:
            bump.plan(self.formula, "v2.0.0", "kmoneil/jr")
        self.assertIn("disagree", str(caught.exception))
        self.assertEqual(self.formula.read_text(), FORMULA, "the formula was written anyway")

    def test_a_release_missing_a_platform_is_refused(self):
        manifest = {n: self.real for n in names("2.0.0")}
        del manifest["jr-full_2.0.0_linux_arm64.tar.gz"]
        self.use(manifest)
        with self.assertRaises(bump.Refused) as caught:
            bump.plan(self.formula, "v2.0.0", "kmoneil/jr")
        self.assertIn("publishes no", str(caught.exception))

    def test_an_empty_manifest_is_refused(self):
        self.use({})
        with self.assertRaises(bump.Refused) as caught:
            bump.plan(self.formula, "v2.0.0", "kmoneil/jr")
        self.assertIn("no digests", str(caught.exception))

    def test_it_rewrites_all_four_and_nothing_else(self):
        self.use({n: self.real for n in names("2.0.0")})
        text, changed = bump.plan(self.formula, "v2.0.0", "kmoneil/jr")
        self.assertEqual(len(changed), 4)
        self.assertNotIn("1.0.0", text)
        self.assertEqual(text.count(self.real), 4)
        # Everything that is not a url or a sha256 line survives untouched.
        self.assertEqual(
            [l for l in text.splitlines() if "url " not in l and "sha256 " not in l],
            [l for l in FORMULA.splitlines() if "url " not in l and "sha256 " not in l],
        )

    def test_the_platform_a_url_named_is_the_platform_it_keeps(self):
        """A rewrite that reordered arches would hand darwin the linux digest."""
        digests = {n: self.real for n in names("2.0.0")}
        self.use(digests)
        text, _ = bump.plan(self.formula, "v2.0.0", "kmoneil/jr")
        for line, want in zip(
            [l for l in text.splitlines() if "url " in l],
            ["darwin_arm64", "darwin_amd64", "linux_arm64", "linux_amd64"],
        ):
            self.assertIn(want, line)


if __name__ == "__main__":
    unittest.main()
