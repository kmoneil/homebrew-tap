# Scripts

## `bump-jr.py`

Points `jr.rb` at a `kmoneil/jr` release: four URLs and four `sha256` lines,
and nothing else in the file.

```console
$ python3 .github/scripts/bump-jr.py --tag v0.13.2
$ python3 .github/scripts/bump-jr.py --tag v0.13.2 --check   # say, write nothing
```

It refuses rather than guesses. The formula must name exactly the four
platforms it knows, each `url` must have its `sha256` on the next line, every
archive must exist in the release, and **every digest is re-derived from the
archive downloaded from the URL the formula will carry** and compared with the
release's `checksums.txt`. Those two come from the same workflow, so agreeing
with the manifest alone is agreeing with one source twice; hashing the download
is what proves the bytes a user fetches are the bytes the manifest names.

Nothing is written until every check has passed, so a refusal leaves the
formula alone rather than half-edited. Re-running it on a formula that already
points at the tag does nothing and says so, which is what makes a re-run of the
release workflow harmless.

`test_bump_jr.py` covers the refusals, because a healthy release never produces
one and a check that cannot be made to fail is not a check. The workflow runs
these before it trusts the script:

```console
$ python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v
```

The workflow that calls it is `.github/workflows/bump-jr.yml`, which runs the
jobs every formula shares, in `.github/workflows/bump-formula.yml`.

## `bump-hunk.py`

Points `hunk.rb` at a `kmoneil/hunk` release: a binary for each of four
platforms and the agent skill, five URLs and five `sha256` lines, and nothing
else in the file.

```console
$ python3 .github/scripts/bump-hunk.py --tag v0.2.8
$ python3 .github/scripts/bump-hunk.py --tag v0.2.8 --check   # say, write nothing
```

It refuses what `bump-jr.py` refuses, against the release's `SHA256SUMS`, and
it keeps nothing it downloads. `test_bump_hunk.py` serves each file different
bytes, so a digest that lands beside the wrong URL fails a test rather than
matching by accident. The workflow that calls it is
`.github/workflows/bump-hunk.yml`.

## `verify-provenance.py`

Checks that every file a formula names was built by the release workflow it
claims, before a bump is committed. The bump scripts prove the bytes behind
each URL are the bytes the release's manifest names, but the manifest comes
from the same workflow as the files, so that proves agreement and not origin.
This asks `gh attestation verify` about each file the bump downloaded and
requires all of: an attestation in the release's repository, signed by the
named workflow, built from the tag, on a runner GitHub hosts.

```console
$ python3 .github/scripts/bump-jr.py --tag v0.17.0 --check   # downloads into dist/
$ python3 .github/scripts/verify-provenance.py --formula jr.rb --repo kmoneil/jr \
    --workflow kmoneil/jr/.github/workflows/release.yml --tag v0.17.0
```

It runs when a formula's bump workflow names `attested-by`, which `bump-jr.yml`
does and `bump-hunk.yml` does not, because hunk's release publishes no
attestations. A formula naming no release file, or naming a file the bump did not
download, is refused rather than passed. `test_verify_provenance.py` holds what
it asks gh and what it refuses. gh's own answers were checked against a real jr
release, where a tampered archive, the wrong tag and the wrong workflow each
fail.
