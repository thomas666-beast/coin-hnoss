# Money

`Coin::Hnoss::Money` — an immutable value object representing an amount of
money in a given currency.

## Synopsis

    use Coin::Hnoss::Money;

    my $a = Coin::Hnoss::Money->new(500, 'USD');   # 500 cents = $5.00
    my $b = Coin::Hnoss::Money->from_string('5.00', 'USD');   # same thing

    $a->amount;      # Math::BigInt(500)
    $a->currency;    # Coin::Hnoss::Currency(USD)
    $a->as_string;   # "500 USD"
    $a->format;      # "5.00 USD"

## Two constructors

### `new($minor, $currency)`

    Coin::Hnoss::Money->new(500, 'USD');

`$minor` is the amount in the currency's **smallest unit**. For USD, this
means cents. For JPY, this means yen (JPY has no subunit). For BHD, this
means fils. For BTC, this means satoshi.

`$currency` may be a `Coin::Hnoss::Currency` object or a 3-to-8-letter
string (which will be wrapped into a Currency automatically).

`$minor` may be:

- an integer,
- an integer string,
- a `Math::BigInt`.

It may **not** be a float, an arrayref, or a hashref.

### `from_string($major, $currency, %options)`

    Coin::Hnoss::Money->from_string('5.00', 'USD');

`$major` is the amount in the currency's **major unit**, as a string. For
USD, this means dollars. For JPY, this means yen. For BHD, this means
dinars. For BTC, this means bitcoin.

The string is parsed according to the currency's exponent. If the decimal
part has more digits than the currency allows, `from_string` **dies** —
it never silently rounds.

Options:

- `decimal_mark` — default `'.'`
- `thousands_separator` — default `','`. Pass `''` to disable grouping on
  input.
- `group_size` — default `3`. Validated, but not used to check grouping
  position.

See [Parsing](10-parsing.md) for the full grammar.

## Accessors

### `amount`

    my $n = $money->amount;

Returns a **copy** of the internal `Math::BigInt`. Mutating the return value
does not affect the `Money`:

    my $m = Coin::Hnoss::Money->new(500, 'USD');
    my $n = $m->amount;
    $n->badd(1000);
    $m->as_string;   # still "500 USD"

### `currency`

    my $c = $money->currency;

Returns the `Coin::Hnoss::Currency` object.

### `as_string`

    $money->as_string;   # "500 USD"

The canonical, unambiguous, round-trippable form: integer amount, a space,
the code. For a human-facing format use `format` instead.

## Comparison

See [Comparison](07-comparison.md).

## Arithmetic

See [Arithmetic](06-arithmetic.md).

## Allocation

See [Allocation](08-allocation.md).

## Formatting

See [Formatting](09-formatting.md).

## Parsing

See [Parsing](10-parsing.md).

## Equality

    $m1->equals($m2);

True only if both are Money objects, with the same currency and the same
amount. Currency mismatch returns false (not an exception). Use `compare`
if you want a mismatch to be an error.

## Operators

- `"$m"` — stringification, yields `as_string` (`"500 USD"`, **not**
  `format`'s `"5.00 USD"`).
- `$m eq '500 USD'`, `$m ne '5.00 USD'` — string comparison of the
  stringified form.
- `<`, `>`, `<=`, `>=`, `==`, `!=`, `<=>` — numeric comparison, requiring
  the same currency. Dies on mismatch.
