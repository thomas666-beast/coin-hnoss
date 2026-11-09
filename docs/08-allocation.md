# Allocation

`allocate` is the operation that justifies this whole library. Splitting
an amount across N recipients while keeping the sum exactly equal to the
original — down to the last cent — is surprisingly easy to get wrong.

## Synopsis

    my $hundred = Coin::Hnoss::Money->new(100, 'USD');

    my @parts = $hundred->allocate(1, 1, 1);
    # 34 USD, 33 USD, 33 USD

    my @by_pct = $hundred->allocate(70, 20, 10);
    # 70 USD, 20 USD, 10 USD

    # Also accepts an arrayref
    my @same = $hundred->allocate([1, 1, 1]);

## The rules

Given an amount and ratios `r1, r2, ..., rN`:

1. Ratios must be **non-negative integers**. Negative ratios die.
2. Not all ratios may be zero. All-zero dies.
3. Each share is `floor(|amount| * r_i / sum_of_ratios)`.
4. The leftover units are handed out one at a time, starting at index 0.
5. The sum of the parts equals the original amount, **always**.
6. For negative amounts, the result is the element-wise negation of what
   you'd get for the positive amount. That is:

        Money->new(-x)->allocate(@r) ≡ -1 * Money->new(x)->allocate(@r)

## Examples

### Even split

    my $ten = Coin::Hnoss::Money->new(10, 'USD');
    $ten->allocate(1, 1, 1);   # 4, 3, 3

    my $eleven = Coin::Hnoss::Money->new(11, 'USD');
    $eleven->allocate(1, 1, 1); # 4, 4, 3

### Percentage split

    my $hundred = Coin::Hnoss::Money->new(100, 'USD');
    $hundred->allocate(70, 20, 10);   # 70, 20, 10

### Zero ratios

A zero ratio gets nothing (which is sometimes exactly what you want —
think "one active recipient, two empty slots"):

    $hundred->allocate(0, 1, 0);   # 0, 100, 0

    $hundred->allocate(1, 0, 1);   # 50, 0, 50

### Negative amounts

    my $neg = Coin::Hnoss::Money->new(-100, 'USD');
    $neg->allocate(1, 1, 1);   # -34, -33, -33

    my $negOdd = Coin::Hnoss::Money->new(-101, 'USD');
    $negOdd->allocate(1, 1, 1);  # -34, -34, -33

## Real-world example: splitting a bill

    use Coin::Hnoss::Money;

    my $total = Coin::Hnoss::Money->from_string('100.00', 'USD');
    my @people = qw(alice bob carol dave);

    my @shares = $total->allocate((1) x @people);

    for my $i (0 .. $#people) {
        printf "%s pays %s\n", $people[$i], $shares[$i]->format;
    }

    # alice pays 25.00 USD
    # bob pays 25.00 USD
    # carol pays 25.00 USD
    # dave pays 25.00 USD

For an uneven total:

    my $total = Coin::Hnoss::Money->from_string('100.01', 'USD');
    my @shares = $total->allocate(1, 1, 1, 1);

    # alice pays 25.01 USD  (gets the extra cent)
    # bob pays 25.00 USD
    # carol pays 25.00 USD
    # dave pays 25.00 USD

## Errors

`allocate` dies with `Coin::Hnoss::Exception` on:

- Empty ratio list.
- All-zero ratios.
- Any negative ratio.
- Any non-integer ratio (floats, non-numeric strings, references, `undef`).

See [Exceptions](12-exceptions.md).

## Why this is harder than it looks

Naive allocation:

    my $share = int($total / $n);   # 100 / 3 = 33
    my $sum   = $share * $n;         # 99
    # We've lost 1 cent.

You could tack the remainder onto the last share (34, 33, 33) or the first
(34, 33, 33) — but then it matters which index you pick. `allocate` fixes
this by defining a deterministic rule (leftmost first, one at a time) and
documenting it. The result depends on the order of ratios, but only up to
which share gets the extra unit, not on whether the sum is correct.

The sum is *always* correct. That's the only invariant that actually
matters.
