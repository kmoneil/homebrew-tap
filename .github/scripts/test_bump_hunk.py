#!/usr/bin/env python3
"""Tests for bump-hunk.py, and mostly for the refusals.

The happy path is checked every release by the workflow that runs the script:
brew installs the formula it wrote and runs the binary. What that run cannot
show is a refusal, because a healthy release does not produce one. These do.

Every file is served different bytes, so every digest differs. That is what
lets a test see a digest land beside the wrong URL: with one body for all five,
a rewrite that gave darwin's URL linux's digest would pass.
"""

from __future__ import annotations

import contextlib
import hashlib
import importlib.util
import io
import os
import tempfile
import unittest
import unittest.mock
import urllib.error
from pathlib import Path

HERE = Path(__file__).parent
SPEC = importlib.util.spec_from_file_location("bump_hunk", HERE / "bump-hunk.py")
bump = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(bump)

OLD = "https://github.com/kmoneil/hunk/releases/download/v1.0.0"
ZERO = "0" * 64
BASE = "https://github.com/kmoneil/hunk/releases/download/v2.0.0"

FORMULA = f"""class Hunk < Formula
  on_macos do
    if Hardware::CPU.arm?
      url "{OLD}/hunk-darwin-arm64"
      sha256 "{ZERO}"
    else
      url "{OLD}/hunk-darwin-amd64"
      sha256 "{ZERO}"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "{OLD}/hunk-linux-arm64"
      sha256 "{ZERO}"
    else
      url "{OLD}/hunk-linux-amd64"
      sha256 "{ZERO}"
    end
  end

  resource "skill" do
    url "{OLD}/hunk-skill.tar.gz"
    sha256 "{ZERO}"
  end
end
"""

# What a release publishes, the Windows binaries no formula names included.
PUBLISHED = bump.ASSETS + ["hunk-windows-amd64.exe", "hunk-windows-arm64.exe"]


def body(name: str) -> bytes:
    return f"the bytes of {name}".encode()


def digest(name: str) -> str:
    return hashlib.sha256(body(name)).hexdigest()


def honest() -> dict[str, str]:
    return {n: digest(n) for n in PUBLISHED}


class Stub:
    """Stands in for the network: a manifest, and different bytes per file."""

    def __init__(self, manifest: dict[str, str], bodies: dict[str, bytes] | None = None):
        self.manifest, self.bodies = manifest, bodies or {}
        self.urls: list[str] = []

    def __call__(self, url: str) -> bytes:
        self.urls.append(url)
        name = url.rsplit("/", 1)[1]
        if name == "SHA256SUMS":
            return "".join(f"{d}  {n}\n" for n, d in self.manifest.items()).encode()
        return self.bodies.get(name, body(name))


class PlanTest(unittest.TestCase):
    def setUp(self):
        scratch = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.formula = scratch / "hunk.rb"
        self.formula.write_text(FORMULA)
        self.addCleanup(setattr, bump, "fetch", bump.fetch)

    def use(self, manifest, bodies=None):
        bump.fetch = Stub(manifest, bodies)
        return bump.fetch

    def refusal(self, text=None):
        if text is not None:
            self.assertNotEqual(text, FORMULA, "the test's own edit did not happen")
            self.formula.write_text(text)
        with self.assertRaises(bump.Refused) as caught:
            bump.plan(self.formula, "v2.0.0", "kmoneil/hunk")
        return str(caught.exception)

    def test_a_manifest_the_file_contradicts_is_refused(self):
        """The one that matters: SHA256SUMS says one thing, the bytes another."""
        self.use(honest(), {"hunk-linux-amd64": b"not what the manifest hashed"})
        self.assertIn("hunk-linux-amd64 hashes to", self.refusal())
        self.assertEqual(self.formula.read_text(), FORMULA, "the formula was written anyway")

    def test_a_release_missing_a_platform_is_refused(self):
        manifest = honest()
        del manifest["hunk-linux-arm64"]
        self.use(manifest)
        self.assertIn("v2.0.0 publishes no hunk-linux-arm64", self.refusal())

    def test_a_release_without_the_skill_is_refused(self):
        """Every release before v0.2.8: the binaries are there and the skill is not."""
        manifest = honest()
        del manifest["hunk-skill.tar.gz"]
        self.use(manifest)
        self.assertIn("v2.0.0 publishes no hunk-skill.tar.gz", self.refusal())

    def test_an_empty_manifest_is_refused(self):
        self.use({})
        self.assertIn("SHA256SUMS held no digests", self.refusal())

    def test_a_formula_without_the_skill_is_refused(self):
        """A shape this script does not know is for a person to read first."""
        self.use(honest())
        block = f'  resource "skill" do\n    url "{OLD}/hunk-skill.tar.gz"\n    sha256 "{ZERO}"\n  end\n'
        self.assertIn("names 4 files and this script knows 5", self.refusal(FORMULA.replace(block, "")))

    def test_a_url_with_no_digest_under_it_is_refused(self):
        self.use(honest())
        gap = FORMULA.replace('hunk-darwin-amd64"\n', 'hunk-darwin-amd64"\n\n')
        self.assertIn("names a file with no sha256 under it", self.refusal(gap))

    def test_a_url_in_another_repository_is_refused(self):
        self.use(honest())
        moved = FORMULA.replace("kmoneil/hunk/releases/download/v1.0.0/hunk-linux-amd64", "someone/hunk/releases/download/v1.0.0/hunk-linux-amd64")
        self.assertIn("points at someone/hunk, not kmoneil/hunk", self.refusal(moved))

    def test_a_file_this_script_does_not_know_is_refused(self):
        self.use(honest())
        odd = FORMULA.replace('hunk-linux-amd64"', 'hunk-linux-riscv64"')
        self.assertIn("names hunk-linux-riscv64, which is not a file this script knows", self.refusal(odd))

    def test_a_file_named_twice_is_refused(self):
        self.use(honest())
        twice = FORMULA.replace('hunk-linux-amd64"', 'hunk-linux-arm64"')
        self.assertIn("hunk-linux-arm64 is named twice", self.refusal(twice))

    def test_it_rewrites_all_five_and_nothing_else(self):
        self.use(honest())
        text, changed = bump.plan(self.formula, "v2.0.0", "kmoneil/hunk")
        self.assertEqual([asset for asset, _, _ in changed], bump.ASSETS)
        self.assertNotIn("v1.0.0", text)
        self.assertNotIn(ZERO, text)

        def rest(s):
            return [l for l in s.splitlines() if "url " not in l and "sha256 " not in l]

        self.assertEqual(rest(text), rest(FORMULA))

    def test_every_url_keeps_its_own_digest(self):
        """A rewrite that gave darwin's URL linux's digest would install nothing that runs."""
        self.use(honest())
        lines = bump.plan(self.formula, "v2.0.0", "kmoneil/hunk")[0].splitlines()
        urls = [i for i, l in enumerate(lines) if "url " in l]
        self.assertEqual(len(urls), 5)
        for i in urls:
            name = lines[i].rsplit("/", 1)[1].rstrip('"')
            self.assertEqual(lines[i].strip(), f'url "{BASE}/{name}"')
            self.assertEqual(lines[i + 1].strip(), f'sha256 "{digest(name)}"')

    def test_each_digest_is_hashed_from_the_url_the_formula_will_carry(self):
        stub = self.use(honest())
        bump.plan(self.formula, "v2.0.0", "kmoneil/hunk")
        self.assertEqual(stub.urls, [f"{BASE}/SHA256SUMS"] + [f"{BASE}/{a}" for a in bump.ASSETS])


class MainTest(unittest.TestCase):
    """The command line: what it refuses, what it writes, and what a re-run does."""

    def setUp(self):
        scratch = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.formula = scratch / "hunk.rb"
        self.formula.write_text(FORMULA)
        self.outputs = scratch / "outputs"
        self.addCleanup(setattr, bump, "fetch", bump.fetch)
        bump.fetch = Stub(honest())
        self.enterContext(unittest.mock.patch.dict(os.environ, {"GITHUB_OUTPUT": str(self.outputs)}))

    def run_main(self, *args):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = bump.main(["--formula", str(self.formula), *args])
        return code, out.getvalue(), err.getvalue()

    def emitted(self):
        return dict(l.split("=", 1) for l in self.outputs.read_text().splitlines())

    def test_a_prerelease_is_refused(self):
        code, _, err = self.run_main("--tag", "v2.0.0-rc.1")
        self.assertEqual(code, 2)
        self.assertIn("v2.0.0-rc.1 is not a release tag", err)
        self.assertEqual(self.formula.read_text(), FORMULA)

    def test_a_refusal_exits_1_and_writes_nothing(self):
        bump.fetch = Stub({})
        code, _, err = self.run_main("--tag", "v2.0.0")
        self.assertEqual(code, 1)
        self.assertIn("refused: SHA256SUMS held no digests", err)
        self.assertEqual(self.formula.read_text(), FORMULA)

    def test_it_writes_the_formula_and_says_so(self):
        code, out, _ = self.run_main("--tag", "v2.0.0")
        self.assertEqual(code, 0)
        self.assertIn("hunk.rb now points at 2.0.0", out)
        self.assertIn(f'url "{BASE}/hunk-skill.tar.gz"', self.formula.read_text())
        self.assertEqual(self.emitted(), {"version": "2.0.0", "changed": "true"})

    def test_check_says_and_writes_nothing(self):
        code, out, _ = self.run_main("--tag", "v2.0.0", "--check")
        self.assertEqual(code, 0)
        self.assertIn("--check: the formula is unchanged on disk", out)
        self.assertEqual(self.formula.read_text(), FORMULA)
        self.assertEqual(self.emitted()["changed"], "true")

    def test_a_second_run_has_nothing_to_do(self):
        self.run_main("--tag", "v2.0.0")
        written = self.formula.read_text()
        self.outputs.unlink()
        code, out, _ = self.run_main("--tag", "v2.0.0")
        self.assertEqual(code, 0)
        self.assertIn("hunk.rb already points at 2.0.0; nothing to do", out)
        self.assertEqual(self.formula.read_text(), written)
        self.assertEqual(self.emitted(), {"version": "2.0.0", "changed": "false"})


class FetchTest(unittest.TestCase):
    """A network failure is a refusal that names the URL, not a traceback."""

    def refusal(self, error):
        with unittest.mock.patch.object(bump.urllib.request, "urlopen", side_effect=error):
            with self.assertRaises(bump.Refused) as caught:
                bump.fetch(f"{BASE}/SHA256SUMS")
        return str(caught.exception)

    def test_a_missing_file_is_refused(self):
        error = urllib.error.HTTPError(f"{BASE}/SHA256SUMS", 404, "Not Found", None, None)
        self.assertIn("SHA256SUMS answered 404 Not Found", self.refusal(error))

    def test_an_unreachable_host_is_refused(self):
        self.assertIn("could not be reached: no route", self.refusal(urllib.error.URLError("no route")))


if __name__ == "__main__":
    unittest.main()
