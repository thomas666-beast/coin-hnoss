# Coin::Hnoss

Exact monetary values for Perl. A value-object library for handling money
without floating-point errors.

The name is Old Norse: **Hnoss** is a goddess of treasure and precious
things, and the plural *hnossir* was used for all beautiful, valuable
objects.

Inspired by the Money pattern (Martin Fowler) and the PHP
[`moneyphp/money`](https://github.com/moneyphp/money) library. Part of the
planned `Coin::*` family, alongside a sibling Python package and a Rust
crate.

## Status

Early development. The core value objects, arithmetic, comparison,
allocation, formatting, and parsing are all implemented and tested on Perl
5.26 through 5.40. See `Changes` for the release history.

## Requirements

- Perl 5.26 or newer
- No non-core dependencies. Everything (`Math::BigInt`, `Carp`,
  `Scalar::Util`, `Test::More`) ships with Perl itself.

## Installation

    cpanm Coin::Hnoss

Or, from a checkout:

    cpanm --installdeps .
    perl Makefile.PL
    make test
    make install

## Quick start

    use Coin::Hnoss::Money;

    my $price = Coin::Hnoss::Money->new(500, 'USD');   # 500 cents = $5.00
    my $tax   = Coin::Hnoss::Money->new( 50, 'USD');   #  50 cents = $0.50

    my $total = $price->add($tax);

    print $total->format;                # "5.50 USD"
    print $total->as_string, "\n";       # "550 USD"   (raw canonical form)

    my $parsed = Coin::Hnoss::Money->from_string('1,234.56', 'USD');
    print $parsed->format;               # "1,234.56 USD"

## Core concepts

- **Amounts are integers in the currency's smallest unit.** `new(500, 'USD')`
  means 500 cents. No floating-point arithmetic anywhere.
- **Currency-aware.** Exponent comes from an ISO 4217 table
  (USD has 2, JPY has 0, BHD has 3, UYW has 4), plus a small set of
  documented non-ISO extensions: **BTC** (Bitcoin, 8 = satoshi),
  **TRX** (TRON, 6 = sun), and **USDT** (Tether USD, 6 decimals on both
  TRC20/TRON and ERC20/Ethereum).
- **Immutable.** All arithmetic returns new objects; originals are untouched.
- **Exact.** `Math::BigInt` internally, so huge values are safe on 32-bit
  perls too.

## Common operations

### Construction

    # from minor units (cents, pence, yen, fils, ...)
    Coin::Hnoss::Money->new(500, 'USD');

    # from major units (dollars, pounds, yen, dinars, ...)
    Coin::Hnoss::Money->from_string('5.00', 'USD');
    Coin::Hnoss::Money->from_string('5',    'USD');
    Coin::Hnoss::Money->from_string('0.500','BHD');
    Coin::Hnoss::Money->from_string('1.234,56', 'EUR',
        decimal_mark        => ',',
        thousands_separator => '.',
    );

### Arithmetic

    $a->add($b);                # same currency required
    $a->subtract($b);
    $a->multiply(3);            # integer factor
    $a->divide(2);              # floor division
    $a->divide_with_remainder(3);  # ($q, $r) such that q*3 + r == original
    $a->negate;
    $a->abs;

### Comparison

    $a->equals($b);             # bool (false on currency mismatch, no die)
    $a->compare($b);            # -1 | 0 | 1 (dies on mismatch)
    $a->is_zero; $a->is_positive; $a->is_negative;
    $a->greater_than($b);       # and greater_or_equal, less_than, less_or_equal
    $a > $b; $a == $b; $a <=> $b;   # operators work, same-currency only

### Allocation

Splitting money without losing a cent:

    my $hundred = Coin::Hnoss::Money->new(100, 'USD');
    my @parts = $hundred->allocate(1, 1, 1);
    # (34 USD, 33 USD, 33 USD)  — sums to 100 USD exactly

    my @by_pct = $hundred->allocate(70, 20, 10);
    # (70 USD, 20 USD, 10 USD)

Negative amounts are mirrored: `allocate(-x)` is element-wise the negation
of `allocate(x)`.

### Formatting

    Coin::Hnoss::Money->new(123456, 'USD')->format;   # "1,234.56 USD"
    Coin::Hnoss::Money->new(    500, 'JPY')->format;  # "500 JPY"
    Coin::Hnoss::Money->new(    500, 'BHD')->format;  # "0.500 BHD"

    # options
    $m->format(with_currency => 0);
    $m->format(thousands_separator => '');          # no grouping
    $m->format(decimal_mark => ',', thousands_separator => '.');  # European
    $m->format(currency_separator => '');           # "1234.56USD"
    $m->format(group_size => 2);                    # Indian grouping

## What is *not* here

- **Currency symbols and locales.** `format` emits `"5.00 USD"`, not `"$5.00"`
  or `"5,00 €"`. Locale-aware formatting is a planned `Coin::Hnoss::Formatter`
  class, not part of the core.
- **Rounding.** Parsing is strict; there is no `round()` method. If you need
  rounding, do it explicitly at the boundary (e.g. `multiply(5)->divide(100)`
  for a 5% tax) — this is by design, to prevent silent precision loss.
- **Exchange rates / conversion.** Out of scope; the library is about
  individual values, not valuation.
- **Cryptocurrencies beyond BTC, TRX, and USDT.** The built-in table includes
  these three as documented non-ISO extensions. For ETH, LTC, XRP, DOGE,
  and other assets, pass a custom repository
  (`Coin::Hnoss::Currency::Repository->new({...})`) or a custom `Currency`
  object with the exponent you want.

## See also

- [Martin Fowler, *Money* pattern](https://martinfowler.com/eaaCatalog/money.html)
- [ISO 4217 currency codes](https://www.iso.org/iso-4217-currency-codes.html)
- PHP: [`moneyphp/money`](https://github.com/moneyphp/money)

## License

Same terms as Perl 5 itself. See `LICENSE`.

## Contributing

See `CONTRIBUTING.md`.
