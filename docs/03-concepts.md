# Core concepts

## The problem: money should not be a float

The single most important design decision in this library is that **no
monetary value is ever a floating-point number**.

    my $price = 0.1 + 0.2;
    printf "%.20f\n", $price;   # 0.30000000000000004441

Floats can't represent `0.1`, `0.2`, or `0.05` exactly. Add enough of them
in a billing system and pennies appear and disappear at random. Every
serious money library — `moneyphp/money`, Java's `JSR-354`, Rust's
`rust_decimal`, Python's `decimal` module — avoids floats for the same
reason.

`Coin::Hnoss` stores every amount as an **integer** in the currency's
smallest unit:

| Major unit | Smallest unit | `Money->new(...)` |
|---|---|---|
| 5.00 USD | 500 cents | `new(500, 'USD')` |
| 500 JPY | 500 yen (JPY has no subunit) | `new(500, 'JPY')` |
| 0.500 BHD | 500 fils | `new(500, 'BHD')` |
| 0.00000500 BTC | 500 satoshi | `new(500, 'BTC')` |

No rounding. No drift. Ever.

## The Money pattern

`Coin::Hnoss` follows Martin Fowler's
[Money pattern](https://martinfowler.com/eaaCatalog/money.html):

- A **value object** — two Money instances with the same amount and the
  same currency are interchangeable.
- **Immutable** — arithmetic returns a new instance; the receiver is never
  modified.
- **Currency-aware** — an amount without a currency is meaningless. Operations
  between different currencies are a type error.
- **Integer storage** — the internal representation is an integer (or, for
  huge values, a `Math::BigInt`).

## Two kinds of constructor

Because money has two natural representations (major units and minor units),
we provide two constructors:

- **`new($minor, $currency)`** — for when you have the raw integer. `new(500,
  'USD')` is $5.00. This is the "trusted" constructor: no parsing, no
  inference, just wrap the integer.
- **`from_string($major, $currency)`** — for when you have user-facing text.
  `from_string('5.00', 'USD')` is $5.00. Exponent-aware. Strict about
  precision.

The distinction matters. If you always use `new`, you'll eventually type
`new(5.00, 'USD')` and get a `Math::BigInt` error (5.00 isn't an integer).
If you always use `from_string`, you pay the parsing cost even when you
already have the raw integer.

## Why `Math::BigInt`

`Perl`'s native integers are 64-bit on most platforms, but on 32-bit perls
they're only 32-bit — around 2.1 billion, i.e. about $21 million in cents.
That's uncomfortably close to the size of real-world financial values.

`Math::BigInt` (in core since forever) makes every `Money` safe from
overflow. The cost is negligible for normal amounts; the benefit is that a
`Money->new('123456789012345678901234567890', 'USD')` works exactly as you'd
expect.

## Immutability in practice

You can't accidentally mutate a `Money`:

    my $a = Coin::Hnoss::Money->new(500, 'USD');
    my $b = $a->add(Coin::Hnoss::Money->new(250, 'USD'));

    $a->format;   # "5.00 USD"   (unchanged)
    $b->format;   # "7.50 USD"

`$a->amount` returns a **copy** of the internal `Math::BigInt`, so even this
doesn't leak:

    my $raw = $a->amount;
    $raw->badd(1000);
    $a->format;   # still "5.00 USD"

## Currency is a first-class object

`Coin::Hnoss::Currency` is a value object wrapping a currency code (like
`USD`) and a set of known properties (like its exponent). It is created
implicitly when you pass a code string to `Money->new`, but you can also
create it explicitly:

    my $usd = Coin::Hnoss::Currency->new('USD');
    my $m   = Coin::Hnoss::Money->new(500, $usd);

This matters when you have a `Currency` from elsewhere (config, database,
API) and want to avoid re-validating the string on every `Money->new`.

## What this library is not

- **Not a number formatter.** `format` produces `"5.00 USD"`, not `"$5.00"`.
  Locale-aware formatting is a planned `Coin::Hnoss::Formatter`.
- **Not a currency converter.** There are no exchange rates. Two different
  currencies are not comparable and not addable.
- **Not a rounding library.** Parsing is strict; arithmetic is exact. If
  you need to round, do it explicitly at the boundary.
- **Not a database layer.** You'll want to serialize a `Money` to a
  `(amount, currency)` pair for storage; that's up to you. The library
  gives you `->amount->bstr` and `->currency->code` for exactly this.

## Next

- [Currency](04-currency.md)
- [Money](05-money.md)
