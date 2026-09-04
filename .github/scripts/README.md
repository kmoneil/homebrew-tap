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

The workflow that calls it is `.github/workflows/bump-jr.yml`.
