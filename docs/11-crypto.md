# Cryptocurrencies

`Coin::Hnoss` is, at heart, an ISO 4217 library. But real applications
routinely deal with crypto amounts, and the numerical semantics are
identical — an integer amount in the smallest storable unit, plus a code.
So the library ships with a small, explicitly documented set of non-ISO
extensions.

## What is supported out of the box

| Code | Asset | Exponent | Smallest unit | 1 major unit = |
|---|---|---|---|---|
| `BTC` | Bitcoin | 8 | satoshi | 100,000,000 satoshi |
| `TRX` | TRON | 6 | sun | 1,000,000 sun |
| `USDT` | Tether USD (TRC20 / ERC20) | 6 | 10⁻⁶ USDT | 1,000,000 |

These are the only non-ISO codes in the default table. Everything else is
strictly ISO 4217 (or ISO 4217 historical / metatokens).

## Using a crypto code

    use Coin::Hnoss::Money;

    my $sats = Coin::Hnoss::Money->new(500, 'BTC');
    $sats->format;              # "0.00000500 BTC"
    $sats->amount->bstr;        # "500"

    my $trx = Coin::Hnoss::Money->from_string('1.000000', 'TRX');
    $trx->amount->bstr;         # "1000000"

    my $usdt = Coin::Hnoss::Money->from_string('100.000000', 'USDT');
    $usdt->format;              # "100.000000 USDT"

The API is identical to fiat:

- `new($minor, $code)` takes amounts in the smallest unit (satoshi, sun,
  10⁻⁶ USDT).
- `from_string($major, $code)` takes amounts in the major unit (BTC, TRX,
  USDT), strictly parsed at the currency's exponent.

## A note on USDT

USDT is the same logical asset whether it lives on TRON (as a TRC20 token)
or Ethereum (as an ERC20 token). Both versions use 6 decimal places, so a
single `USDT` code with exponent 6 is correct for both.

If your application needs to distinguish "USDT on TRON" from "USDT on
Ethereum" (e.g. for accounting or blockchain-specific operations), do that
at your application layer — a `Money` amount does not carry a chain
identifier, and it shouldn't. The library models value, not networks.

## Adding more cryptocurrencies

The built-in table is deliberately small. If you need ETH, LTC, XRP, DOGE,
USDC, or anything else, you have two options.

### Option 1: custom repository

    use Coin::Hnoss::Currency::Repository;
    use Coin::Hnoss::Money;

    my $repo = Coin::Hnoss::Currency::Repository->new({
        %{ Coin::Hnoss::Currency::Repository->default->as_hashref },
        ETH => 18,
        LTC => 8,
        XRP => 6,
    });

    # But note: `Money` uses the *default* repository when computing
    # exponents. If you want to use a custom repository, you need to pass
    # currency objects that carry the exponent you want, or override
    # `Coin::Hnoss::Currency::Repository->default` (not recommended).

**Practical recommendation**: for one-off amounts, just construct a
`Money` with the exponent already baked in by using `new` with the minor
unit you want. `Money->new($wei, 'ETH')` doesn't need to know that ETH has
exponent 18 — the amount is already in wei. The exponent only matters when
you `format` or `from_string`, and for a custom asset you can bypass both
by pre-computing the minor amount.

### Option 2: request an addition

If a code is broadly used and stable, it's a candidate for inclusion in
the built-in table. Open an issue with:

- The code (ticker).
- The exponent (or the smallest unit name and its relation to the major
  unit).
- A one-line justification.

The bar is intentionally high — the default table should stay predictable,
and every entry is a compatibility commitment.

### Option 3: a fork

If your asset is exotic, a fork of the library with your asset baked in is
a perfectly reasonable solution. The library is small.

## What this library does not do for crypto

- **No chain awareness.** A `Money` does not know whether USDT is on TRON
  or Ethereum. Model that at the application layer.
- **No smart contract interaction.** The library is purely numerical.
- **No wallet or address handling.** Out of scope.
- **No gas fees, no block confirmations, no mempool states.** All of that
  belongs to a blockchain library, not a Money library.
- **No "crypto mode".** Amounts behave exactly like fiat amounts: integer
  minor units, exponent-aware formatting. There is no separate code path
  for crypto.

## Precision considerations

Bitcoin and TRON both use 8 or fewer decimal places, which is well within
`Math::BigInt`'s range. Ethereum's `wei` is 18 decimal places; a single
ETH amount in wei is up to 19 digits, still well within `Math::BigInt`'s
range. If you add assets with exotic exponents, `Math::BigInt` will handle
them, but consider the ergonomic cost — an `ETH` amount of `"1"` in the
smallest unit is `1_000_000_000_000_000_000`, which is unwieldy in tests
and logs. For that reason, `from_string` (major units) is often more
readable than `new` (minor units) for such assets.

## See also

- [Currency](04-currency.md) — the `Currency` value object
- [Currency repository](04-currency.md#repository) — the lookup table
- [Formatting](09-formatting.md) and [Parsing](10-parsing.md)
