# Comparison

Two different kinds of comparison: **equality** (`equals`), which is total
and never dies, and **ordering** (`compare`), which requires the same
currency and dies on mismatch.

## `equals`

    $m1->equals($m2);

Returns true if both are `Coin::Hnoss::Money` with the same currency and the
same amount. Returns false for anything else, including currency mismatch,
`undef`, or raw strings.

    $a = Coin::Hnoss::Money->new(500, 'USD');
    $b = Coin::Hnoss::Money->new(500, 'USD');
    $c = Coin::Hnoss::Money->new(500, 'EUR');

    $a->equals($b);    # true
    $a->equals($c);    # false (different currency)
    $a->equals(undef); # false
    $a->equals('500 USD'); # false (not a Money object)

Use `equals` when you have two `Money` values and want a boolean. Use
`compare` when you need `-1/0/1` or when a currency mismatch should be a
programming error.

## `compare`

    my $cmp = $a->compare($b);   # -1, 0, or 1

Dies with `Coin::Hnoss::Exception` on:

- Non-Money operand.
- Currency mismatch.

    $a->compare($b);          # 0
    $a->compare($c);          # dies: Cannot compare money in USD and EUR
    $a->compare(500);         # dies: Cannot compare a non-Money value

## Predicates

    $m->is_zero;      # true if amount == 0
    $m->is_positive;  # true if amount > 0
    $m->is_negative;  # true if amount < 0

Note that `is_positive` is **false for zero** — a zero amount is neither
positive nor negative. If you need "non-negative", that's
`!$m->is_negative`.

## Convenience comparisons

    $a->greater_than($b);      # $a > $b
    $a->greater_or_equal($b);  # $a >= $b
    $a->less_than($b);         # $a < $b
    $a->less_or_equal($b);     # $a <= $b

Each is a thin wrapper over `compare`, so each dies on currency mismatch
(just like `compare`). These are primarily for readability:

    # These are equivalent:
    if ($a->compare($b) > 0) { ... }
    if ($a->greater_than($b)) { ... }

The second is preferred at call sites.

## Operators

Perl's numeric comparison operators are overloaded to use `compare`:

    $a > $b;      # same as $a->compare($b) > 0
    $a < $b;
    $a >= $b;
    $a <= $b;
    $a == $b;     # same as $a->compare($b) == 0
    $a != $b;
    $a <=> $b;    # returns -1/0/1

All of these **require the same currency** and die on mismatch. This is
deliberate: without overloading, `$a == $b` would compare the memory
addresses of the two objects, which is silently meaningless. Dying on
mismatch is safer than silently giving the wrong answer.

    $a = Coin::Hnoss::Money->new(500, 'USD');
    $c = Coin::Hnoss::Money->new(500, 'EUR');

    $a >  Coin::Hnoss::Money->new(250, 'USD');   # true
    $a == Coin::Hnoss::Money->new(500, 'USD');   # true
    $a == $c;                                    # dies

## String comparison

For string comparison, the `eq` / `ne` operators compare the stringified
form (`as_string`):

    $a eq '500 USD';    # true
    $a eq '5.00 USD';   # false (as_string, not format)
    $a ne '500 EUR';    # true

Note that `eq` is **not** the same as `equals`:

- `eq` compares strings. `'500 USD' eq '500 USD'` is true.
- `equals` compares Money objects. `$a->equals('500 USD')` is false.

Use `equals` for Money-to-Money, `eq` only when you have a string.
