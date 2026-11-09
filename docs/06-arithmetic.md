# Arithmetic

All arithmetic methods return **new** `Coin::Hnoss::Money` objects and never
modify the receiver.

## `add`

    my $sum = $a->add($b);

Requires `$b` to be a `Coin::Hnoss::Money` in the **same currency**. Dies
otherwise.

    my $a = Coin::Hnoss::Money->new(500, 'USD');
    my $b = Coin::Hnoss::Money->new(250, 'USD');
    $a->add($b)->format;   # "7.50 USD"

    my $eur = Coin::Hnoss::Money->new(500, 'EUR');
    $a->add($eur);         # dies: cannot add money in USD and EUR

## `subtract`

    my $diff = $a->subtract($b);

Same currency required. Result may be negative:

    $a->subtract($b)->format;   # "2.50 USD"
    $b->subtract($a)->format;   # "-2.50 USD"

## `multiply`

    my $twice = $a->multiply(2);

`$factor` must be an **integer** (or integer string, or `Math::BigInt`).
Multiplication by an integer is exact; there is no rounding.

    $a->multiply(3)->format;    # "15.00 USD"
    $a->multiply(0)->format;    # "0.00 USD"
    $a->multiply(-1)->format;   # "-5.00 USD"

### Why no float factor

Money × float is the classic source of cent drift. If you need to multiply
by a percentage, do it as `multiply(n)->divide(d)`:

    # 5% tax: exact, no float
    my $tax = $a->multiply(5)->divide(100);

    # 12.5% tax
    my $tax = $a->multiply(125)->divide(1000);

This keeps every intermediate value an exact integer.

## `divide`

    my $half = $a->divide(2);

Integer division using **floor** semantics (like Python's `//`):

- `500 / 3 = 166` (remainder 2, discarded)
- `-500 / 3 = -167` (floor, not truncation toward zero)

For the remainder, use `divide_with_remainder`.

    $a->divide(2)->format;   # "2.50 USD"
    $a->divide(3)->format;   # "1.66 USD" (2 cents discarded)

### Why floor, not truncate

Floor division (matching `Math::BigInt::bdiv` and Python's `divmod`) gives
the invariant `q * d + r == original` with `0 <= r < d` for positive `d`.
That invariant is what allocation relies on. Truncation toward zero would
break it for negative dividends.

## `divide_with_remainder`

    my ($q, $r) = $a->divide_with_remainder(3);

Returns a two-element list: quotient and remainder, both Money objects in
the same currency. The invariant `q * divisor + r == original` holds
exactly.

    my ($q, $r) = Coin::Hnoss::Money->new(500, 'USD')->divide_with_remainder(3);
    # $q = 166 USD, $r = 2 USD

For negative dividends, both the quotient and the remainder follow floor
semantics:

    my ($q, $r) = Coin::Hnoss::Money->new(-500, 'USD')->divide_with_remainder(3);
    # $q = -167 USD, $r = 1 USD
    # because -167*3 + 1 == -500

## `negate`

    my $neg = $a->negate;

Sign flip:

    Coin::Hnoss::Money->new(500, 'USD')->negate->format;   # "-5.00 USD"
    Coin::Hnoss::Money->new(-500, 'USD')->negate->format;  # "5.00 USD"

## `abs`

    my $pos = $a->abs;

Absolute value:

    Coin::Hnoss::Money->new(-500, 'USD')->abs->format;   # "5.00 USD"
    Coin::Hnoss::Money->new(500, 'USD')->abs->format;    # "5.00 USD"

## Errors

All arithmetic dies with `Coin::Hnoss::Exception` on:

- Currency mismatch (add/subtract only).
- Non-Money operand (add/subtract only).
- Non-integer factor (multiply only).
- Non-integer divisor, or division by zero (divide / divide_with_remainder).

See [Exceptions](12-exceptions.md).
