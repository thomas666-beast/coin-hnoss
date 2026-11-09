
---

## Full file: `CONTRIBUTING.md`

```markdown
# Contributing to Coin::Hnoss

Thanks for your interest. This is a small, focused library — issues and
pull requests are welcome.

## Bug reports

Please include:

- Perl version (`perl -v`)
- Operating system
- The exact code that misbehaves, including the constructor arguments
- The expected output
- The actual output (including the full error message if there is one)
- The output of `perl -c` on any test file if the issue is a compile error

## Pull requests

1. Fork, branch, and make your change.
2. Add or update tests in `t/` covering the change.
3. Run `make test` locally and make sure everything passes.
4. Update `Changes` with a short description of your change.
5. If you touched a public method, update its POD in the module.
6. Commit with a clear message; open a PR against `main`.

### Style guide

- `use strict; use warnings;` in every file.
- No non-core dependencies. If you need one, open an issue first.
- Two-space indent; keep lines under 80 columns where reasonable.
- POD is documentation — no `#` comments describing public API.
- Version bumps: `0.011`, `0.012`, … for releases; `0.011_01` for dev.

### Testing locally

    cpanm --installdeps .
    perl Makefile.PL
    make test

### What gets merged

- Bug fixes with tests: yes.
- New public methods: discuss in an issue first.
- Refactors that don't change behavior: probably, if small.
- Dependency additions: unlikely, unless there's no way around it.

## Code of conduct

Be kind. Assume good faith. No harassment, no dismissiveness. That's it.
