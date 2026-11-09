# Cookbook

Task-oriented recipes for common things people do with money.

## Format an amount with a currency symbol

`format` doesn't emit symbols. Wrap it:

    sub format_usd {
        my ($m) = @_;
        return '$' . $m->format(with_currency => 0);
    }

    format_usd(Coin::Hnoss::Money->new(500, 'USD'));   # "$5.00"

Or with negative-amount sign placement:

    sub format_usd {
        my ($m) = @_;
        my $s = $m->format(with_currency => 0);
        # format already emits "-5.00", so "$-5.00" is wrong. Move the sign.
        $s =~ s/^-// ? "-$" . $s : "\$$s";
        return $s;
    }

For a proper locale-aware solution, a `Coin::Hnoss::Formatter` is planned
but not yet available.

## Add a percentage

Multiplication by a percentage is a two-step operation to stay exact:

    my $price = Coin::Hnoss::Money->new(10000, 'USD');   # $100.00
    my $tax   = $price->multiply(5)->divide(100);         # 5% = $5.00

    my $total = $price->add($tax);
    $total->format;   # "105.00 USD"

For 12.5%:

    my $tax = $price->multiply(125)->divide(1000);   # 12.5%

## Split a bill

    my $total = Coin::Hnoss::Money->from_string('100.00', 'USD');
    my @people = qw(alice bob carol);

    my @shares = $total->allocate((1) x @people);

    for my $i (0 .. $#people) {
        printf "%s owes %s\n", $people[$i], $shares[$i]->format;
    }

    # alice owes 33.34 USD
    # bob owes 33.33 USD
    # carol owes 33.33 USD

## Split proportionally

    my $total = Coin::Hnoss::Money->from_string('100.00', 'USD');

    # 70/20/10 split
    my ($a, $b, $c) = $total->allocate(70, 20, 10);

    # 1/2 and 1/3 to Alice and Bob, remainder to Carol
    my ($alice, $bob, $carol) = $total->allocate(3, 2, 1);

## Sum a list of amounts

    use List::Util qw(reduce);

    my @amounts = map { Coin::Hnoss::Money->new($_, 'USD') } (100, 250, 500);
    my $total = reduce {
        $a->add($b)
    } Coin::Hnoss::Money->new(0, 'USD'), @amounts;

    $total->format;   # "8.50 USD"

The seed `Coin::Hnoss::Money->new(0, 'USD')` matters: `reduce` without a
seed uses the first element as the initial accumulator, which is fine, but
seeding makes the currency explicit.

## Compare amounts from different sources

    my $from_db     = Coin::Hnoss::Money->new(500, 'USD');
    my $from_config = Coin::Hnoss::Money->from_string('5.00', 'USD');

    if ($from_db->equals($from_config)) {
        say "same amount";
    }

Use `equals` for Money-to-Money. Use `compare` when you want ordering and
are willing to die on currency mismatch.

## Serialize a Money for storage

`Money` doesn't dictate a serialization. The two lossless options are:

    # Option 1: structured (recommended for databases)
    my $row = {
        amount   => $m->amount->bstr,     # "500"
        currency => $m->currency->code,   # "USD"
    };

    # Option 2: the canonical string
    my $s = $m->as_string;   # "500 USD"

    # Deserialize
    my $m = Coin::Hnoss::Money->new($row->{amount}, $row->{currency});

Do **not** store `format`'s output — `"5.00 USD"` is ambiguous (it's
major units) and loses the "amount is always minor units" invariant.

## Guard against currency mismatch at the API boundary

    sub charge {
        my ($self, $amount, $expected_currency) = @_;

        if ($amount->currency->code ne $expected_currency) {
            die "expected $expected_currency, got "
                . $amount->currency->code;
        }

        # ...
    }

Do the check once, at the boundary. Everywhere else, `add`, `subtract`,
and `compare` will die on mismatch anyway, so explicit checks are only
needed where you want a nicer error message.

## Work with negative amounts

Negative amounts are first-class. Signs are preserved everywhere:

    my $refund = Coin::Hnoss::Money->new(-500, 'USD');
    $refund->format;   # "-5.00 USD"
    $refund->is_negative;  # true
    $refund->abs->format;  # "5.00 USD"

`allocate` on a negative amount is the element-wise negation of
`allocate` on the positive amount (see [Allocation](08-allocation.md)).

## Compare amounts from a stream

For a stream of amounts where you want to find the maximum:

    my $max = reduce {
        $a->greater_than($b) ? $a : $b
    } @amounts;

This works because `greater_than` is available on every `Money`. (For a
list of mixed currencies, you'll need to group by currency first — a
`Money` in USD and a `Money` in EUR are not comparable.)

## See also

- [Quickstart](02-quickstart.md)
- [Formatting](09-formatting.md)
- [Parsing](10-parsing.md)
