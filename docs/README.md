# Coin::Hnoss Documentation

Exact monetary values for Perl. No floating point, ever.

## Getting started

- [Installation](01-installation.md) — install from CPAN or a checkout
- [Quickstart](02-quickstart.md) — the five-minute tour
- [Core concepts](03-concepts.md) — why integers, why immutability, what the Money pattern is

## The building blocks

- [Currency](04-currency.md) — the `Coin::Hnoss::Currency` value object
- [Money](05-money.md) — the `Coin::Hnoss::Money` value object

## Operations

- [Arithmetic](06-arithmetic.md) — `add`, `subtract`, `multiply`, `divide`, `divide_with_remainder`, `negate`, `abs`
- [Comparison](07-comparison.md) — `compare`, `equals`, predicates, operators
- [Allocation](08-allocation.md) — split money across ratios without losing a cent
- [Formatting](09-formatting.md) — `format`, separators, currency exponent
- [Parsing](10-parsing.md) — `from_string`, strict decimal handling

## Special topics

- [Cryptocurrencies](11-crypto.md) — BTC, TRX, USDT, and how to add more
- [Exceptions](12-exceptions.md) — `Coin::Hnoss::Exception` and error handling
- [Cookbook](13-cookbook.md) — task-oriented recipes (tax, tips, splitting bills, …)
- [FAQ](14-faq.md) — common questions and gotchas

## External references

- [Martin Fowler, *Money* pattern](https://martinfowler.com/eaaCatalog/money.html)
- [ISO 4217 currency codes](https://www.iso.org/iso-4217-currency-codes.html)
- [PHP: `moneyphp/money`](https://github.com/moneyphp/money) — the library that inspired this one
- [Bitcoin units](https://en.bitcoin.it/wiki/Units) — satoshi reference
