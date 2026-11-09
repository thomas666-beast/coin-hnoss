# Quickstart

The five-minute tour of `Coin::Hnoss`.

## Your first Money object

    use Coin::Hnoss::Money;

    my $price = Coin::Hnoss::Money->new(500, 'USD');

`new(500, 'USD')` means **500 cents**, i.e. **$5.00**. The amount is always
stored in the currency's smallest unit — never as a float.

    $price->amount;      # Math::BigInt(500)
    $price->currency;    # Coin::Hnoss::Currency(USD)
    $price->as_string;   # "500 USD"
    $price->format;      # "5.00 USD"

## Arithmetic

    my $tax   = Coin::Hnoss::Money->new( 50, 'USD');
    my $total = $price->add($tax);

    $total->format;      # "5.50 USD"

All operations return **new** Money objects; the originals are untouched:

    $price->format;      # still "5.00 USD"
    $total->format;      # "5.50 USD"

## Parsing

If you have amounts in **major units** (dollars, not cents), use
`from_string` instead of `new`:

    my $m = Coin::Hnoss::Money->from_string('5.00', 'USD');
    $m->format;              # "5.00 USD"
    $m->amount->bstr;        # "500"

The exponent comes from the currency table, so it "just works":

    Coin::Hnoss::Money->from_string('500', 'JPY')->format;   # "500 JPY"
    Coin::Hnoss::Money->from_string('0.500', 'BHD')->format; # "0.500 BHD"

## Allocation

Split money between N people without losing a cent:

    my $hundred = Coin::Hnoss::Money->new(100, 'USD');
    my @parts   = $hundred->allocate(1, 1, 1);

    print $_->format, "\n" for @parts;
    # 0.34 USD
    # 0.33 USD
    # 0.33 USD

The sum of the parts is always exactly the original amount.

## Comparison

    my $a = Coin::Hnoss::Money->new(500, 'USD');
    my $b = Coin::Hnoss::Money->new(250, 'USD');

    $a->equals($b);           # false
    $a->compare($b);          #  1  (a > b)
    $a->greater_than($b);     # true
    $a->is_positive;          # true

    $a > $b;                  # true  (operators work on same-currency)
    $a == $b;                 # false

## Where to go next

- [Core concepts](03-concepts.md) — the philosophy behind the design
- [Currency](04-currency.md) and [Money](05-money.md) — full API
- [Cookbook](13-cookbook.md) — ready-made recipes for common tasks
