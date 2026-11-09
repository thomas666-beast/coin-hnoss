# Exceptions

Every error in `Coin::Hnoss` dies with a `Coin::Hnoss::Exception` object,
not a raw string.

## Basics

    use Coin::Hnoss::Money;
    use Coin::Hnoss::Exception;

    my $a = Coin::Hnoss::Money->new(500, 'USD');
    my $b = Coin::Hnoss::Money->new(500, 'EUR');

    eval { $a->add($b) };
    if (my $e = $@) {
        if (ref $e && $e->isa('Coin::Hnoss::Exception')) {
            warn "money error: ", $e->message, "\n";
        }
        else {
            die $e;   # not ours, re-throw
        }
    }

## Class

    Coin::Hnoss::Exception

Base class. Has one method:

### `message`

Returns the error message as a plain string.

## Stringification

`Coin::Hnoss::Exception` overloads `""` to return `message`. So all of
these work:

    eval { ... };
    print "$@";             # the message
    like("$@", qr/.../);    # match in tests
    die $@;                 # re-throw preserving type

The last one is important: if you want to preserve the exception's type
through a `try`-like wrapper, `die $e` (not `die $e->message`) keeps the
object.

## When do exceptions happen?

### Currency mismatches

    $a->add($b);      # if $a and $b have different currencies
    $a->subtract($b);
    $a->compare($b);  # and any comparison operator or wrapper
    $a > $b;

Message: `Cannot add money in USD and EUR` (op-specific).

Note: `equals` does **not** throw on currency mismatch; it returns false.
See [Comparison](07-comparison.md).

### Type errors

    $a->add(500);     # not a Money
    $a->add(undef);
    $a->compare([]);

Message: `Cannot add a non-Coin::Hnoss::Money value` (op-specific).

### Arithmetic errors

    $a->multiply(1.5);        # non-integer factor
    $a->divide(0);            # division by zero
    $a->divide_with_remainder(0);

Message: `multiply factor must be an integer, got '1.5'`,
`Division by zero`, etc.

### Allocation errors

    $money->allocate();         # no ratios
    $money->allocate(0, 0);     # all-zero
    $money->allocate(1, -1);    # negative
    $money->allocate(1, 1.5);   # non-integer

Message: `allocate requires at least one ratio`,
`allocate ratios must not all be zero`, etc.

### Format errors

    $money->format(group_size => 0);   # non-positive

Message: `group_size must be a positive integer`.

### Parse errors

    Coin::Hnoss::Money->from_string('abc', 'USD');
    Coin::Hnoss::Money->from_string('5.001', 'USD');   # too many digits

Message: `Cannot parse 'abc' as money: unexpected character`,
`Too many decimal digits for USD: got '001' (exponent is 2)`.

### Construction errors

    Coin::Hnoss::Money->new(undef, 'USD');
    Coin::Hnoss::Currency->new('US');
    Coin::Hnoss::Currency->new('U5D');

Message: `Coin::Hnoss::Money->new requires an amount`,
`Invalid currency code 'US': must be 3-8 ASCII letters`, etc.

## What is **not** an exception

- `equals` on currency mismatch — returns false.
- `is_zero` / `is_positive` / `is_negative` — always return a boolean.
- `format` on any amount — always succeeds (given valid options).
- `amount` / `currency` / `as_string` — always succeed.

## Subclassing

`Coin::Hnoss::Exception` is meant to be subclassed if you want to catch
specific error categories:

    package My::App::Money::CurrencyMismatch;
    use parent 'Coin::Hnoss::Exception';

    # ... and then ...
    die My::App::Money::CurrencyMismatch->new('...');

The library itself uses the base class for all its own exceptions. If you
need to distinguish subclasses, wrap library calls in your own code.

## See also

- [Money](05-money.md)
- [Arithmetic](06-arithmetic.md)
- [Allocation](08-allocation.md)
- [Parsing](10-parsing.md)
