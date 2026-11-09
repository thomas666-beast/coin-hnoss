# Installation

## Requirements

- **Perl 5.26 or newer.** No non-core dependencies.
- **No `Math::BigInt` configuration needed.** It ships with Perl and is used
  internally for arbitrary-precision arithmetic.

## From CPAN

    cpanm Coin::Hnoss

Or, if you prefer `cpan`:

    cpan Coin::Hnoss

## From a checkout

    git clone https://github.com/YOU/coin-hnoss.git
    cd coin-hnoss
    cpanm --installdeps .
    perl Makefile.PL
    make test
    make install

`cpanm --installdeps .` will do nothing for the core install (we have no
non-core dependencies) but is a good habit for contributors.

## Verifying the installation

    perl -MCoin::Hnoss::Money -E '
        say Coin::Hnoss::Money->new(500, "USD")->format;
    '

Expected output:

    5.00 USD

## What gets installed

    Coin::Hnoss
    Coin::Hnoss::Currency
    Coin::Hnoss::Currency::Repository
    Coin::Hnoss::Exception
    Coin::Hnoss::Money

Plus POD documentation accessible via `perldoc`, e.g.:

    perldoc Coin::Hnoss::Money

## Development

    cpanm --installdeps .
    perl Makefile.PL
    make test          # full test suite
    make dist          # build a tarball
