
# Formatting

`format` renders a `Money` as a human-readable string, using the
currency's exponent to decide how many decimal places to show.

## Synopsis

    Coin::Hnoss::Money->new(500, 'USD')->format;   # "5.00 USD"
    Coin::Hnoss::Money->new(500, 'JPY')->format;   # "500 JPY"
    Coin::Hnoss::Money->new(500, 'BHD')->format;   # "0.500 BHD"

    Coin::Hnoss::Money->new(123456, 'USD')->format;   # "1,234.56 USD"

## The default format

    sign  integer_part  decimal_mark  fractional_part  currency_separator  code
    ----  ------------  ------------  ---------------  ------------------  ----
    -     1,234         .             56               (space)             USD

The amount is rendered using the currency's exponent:

- Exponent 0 (JPY, KRW, …): no decimal point, no fractional part.
- Exponent 2 (USD, EUR, GBP, …): two digits after the decimal point.
- Exponent 3 (BHD, KWD, …): three digits.
- Exponent 8 (BTC): eight digits.

Fractional parts are **zero-padded** on the right to the exponent. `101`
cents renders as `"1.01"`, not `"1.1"`; `100` cents renders as `"1.00"`.

Integer parts are grouped by `thousands_separator` (default `,`) every
`group_size` (default 3) digits, from the right. `1234567890` cents renders
as `"12,345,678.90"`.

## Options

All options are optional, and all have sensible defaults.

### `with_currency`

Boolean. Include the currency code at the end of the string. Default:
**true**.

    Coin::Hnoss::Money->new(500, 'USD')->format(with_currency => 0);
    # "5.00"

### `currency_separator`

String between the amount and the currency code. Default: `' '` (space).

    Coin::Hnoss::Money->new(500, 'USD')->format(currency_separator => '');
    # "5.00USD"

    Coin::Hnoss::Money->new(500, 'USD')->format(currency_separator => "\x{00A0}");
    # "5.00 USD" with a non-breaking space

### `decimal_mark`

Single character. Default: `'.'`.

    Coin::Hnoss::Money->new(500, 'USD')->format(decimal_mark => ',');
    # "5,00 USD"

### `thousands_separator`

String. Default: `','`. Pass `''` to disable grouping.

    Coin::Hnoss::Money->new(123456, 'USD')->format(thousands_separator => '');
    # "1234.56 USD"

### `group_size`

Positive integer. Default: `3`. Digits per group in the integer part.

    Coin::Hnoss::Money->new(123456789, 'USD')->format(group_size => 2);
    # "1,23,45,67.89 USD"  (Indian grouping)

    Coin::Hnoss::Money->new(123456789, 'USD')->format(group_size => 3);
    # "1,234,567.89 USD"

## Regional examples

    # US English (the defaults)
    Coin::Hnoss::Money->new(123456, 'USD')->format;
    # "1,234.56 USD"

    # German
    Coin::Hnoss::Money->new(123456, 'EUR')->format(
        decimal_mark        => ',',
        thousands_separator => '.',
    );
    # "1.234,56 EUR"

    # French (narrow no-break space as thousands separator)
    Coin::Hnoss::Money->new(123456, 'EUR')->format(
        decimal_mark        => ',',
        thousands_separator => "\x{202F}",
    );
    # "1 234,56 EUR" (with U+202F)

    # Indian
    Coin::Hnoss::Money->new(123456789, 'INR')->format(group_size => 2);
    # "12,34,567.89 INR"

## What `format` does not do

- **No currency symbols.** `format` emits `"5.00 USD"`, not `"$5.00"`. For
  symbols and locale-aware placement, use a future `Coin::Hnoss::Formatter`
  or a wrapper of your own.
- **No locale inference.** The `decimal_mark` / `thousands_separator` /
  `group_size` options let you express any locale you want, but the library
  does not look up locale settings. You pass the separators explicitly.
- **No rounding.** `format` never rounds. If you need to display a
  truncated amount, do the truncation explicitly with `divide` first.

## Errors

`format` dies with `Coin::Hnoss::Exception` on:

- `group_size => 0` or any non-positive integer.
- `group_size` not a plain integer (float, string, reference).

All other option values are accepted as-is.

## See also

- [Parsing](10-parsing.md) — the inverse operation
