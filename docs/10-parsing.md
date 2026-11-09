# Parsing

`from_string` turns user-facing text (in major units) into a `Money` (in
minor units).

## Synopsis

    Coin::Hnoss::Money->from_string('5.00', 'USD');   # 500 cents
    Coin::Hnoss::Money->from_string('5',    'USD');   # 500 cents
    Coin::Hnoss::Money->from_string('5.5',  'USD');   # 550 cents
    Coin::Hnoss::Money->from_string('-0.05','USD');   # -5 cents

    Coin::Hnoss::Money->from_string('500', 'JPY');    # 500 yen (JPY has exponent 0)
    Coin::Hnoss::Money->from_string('0.500', 'BHD');  # 500 fils (BHD has exponent 3)

## The grammar

After stripping the thousands separator, the string must match:

    \A[+-]?\d+(?:<decimal_mark>\d+)?\z

In words:

- Optional sign (`+` or `-`).
- One or more digits (the integer part).
- Optional decimal mark followed by one or more digits.
- Nothing else.

Explicitly **not** accepted:

- Empty string.
- Whitespace inside (leading/trailing whitespace is rejected; use a
  `trim()` at the call site if your input is dirty).
- Exponent notation (`"1e5"`).
- Currency symbols or codes (`"$5"`, `"5 USD"`).
- Trailing decimal mark (`"5."`).
- Leading decimal mark (`.5`).
- Repeated decimal marks (`"5..5"`).
- `undef`, arrayrefs, hashrefs.

## Options

### `decimal_mark`

Single character. Default: `'.'`.

    Coin::Hnoss::Money->from_string('1,50', 'EUR', decimal_mark => ',');
    # 150 EUR

### `thousands_separator`

String. Default: `','`. Pass `''` to disable grouping on input. Grouping is
stripped but **not validated** — `"1,2,3"` is accepted as `123`.

    Coin::Hnoss::Money->from_string('1,234.56', 'USD');   # 123456 USD
    Coin::Hnoss::Money->from_string('12,34.56', 'USD');   # 123456 USD (also accepted)

If you want strict grouping validation, do it before calling `from_string`.

### `group_size`

Positive integer. Default: `3`. Validated (must be a positive integer),
but not used to check grouping position. It's there for symmetry with
`format`.

## Strictness about precision

`from_string` **dies** if the string has more decimal digits than the
currency allows:

    Coin::Hnoss::Money->from_string('5.001', 'USD');
    # dies: Too many decimal digits for USD: got '001' (exponent is 2)

    Coin::Hnoss::Money->from_string('5.5', 'JPY');
    # dies: Too many decimal digits for JPY: got '5' (exponent is 0)

This is by design. Silently rounding `"5.001"` to `"5.00"` — losing a
thousandth of a dollar per call — is exactly the class of bug this library
exists to prevent. If you want to round, do it explicitly *before* parsing.

## Padding

If the string has *fewer* decimal digits than the currency allows, the
fractional part is right-padded with zeros:

    Coin::Hnoss::Money->from_string('5.5', 'USD');
    # parsed as "5.50" → 550 cents

    Coin::Hnoss::Money->from_string('1.2', 'BHD');
    # parsed as "1.200" → 1200 fils

    Coin::Hnoss::Money->from_string('5', 'USD');
    # parsed as "5.00" → 500 cents

## Round-trip with format

`format` (with `with_currency => 0`) and `from_string` are inverses for
values inside the currency's exponent:

    my $m = Coin::Hnoss::Money->new(123456, 'USD');
    my $s = $m->format(with_currency => 0);   # "1,234.56"

    my $back = Coin::Hnoss::Money->from_string($s, 'USD');
    $back->equals($m);   # true

This is the basis of the round-trip tests in `t/80-from-string.t`.

## Errors

`from_string` dies with `Coin::Hnoss::Exception` on:

- `$string` is `undef` or a reference.
- `$currency` is `undef` or a reference.
- The string doesn't match the grammar (see above).
- The string has too many decimal digits for the currency's exponent.
- `decimal_mark` is not a single character.
- `thousands_separator` is a reference.
- `group_size` is not a positive integer.
- `decimal_mark` and `thousands_separator` are equal (would be ambiguous).

## See also

- [Formatting](09-formatting.md) — the inverse operation
