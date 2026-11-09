use strict;
use warnings;
use Test::More;

use Coin::Hnoss::Money;
use Coin::Hnoss::Exception;

sub str { join ', ', map { $_->as_string } @_ }

my $hundred = Coin::Hnoss::Money->new(100, 'USD');

# --- basic splits ------------------------------------------------------------

my @parts = $hundred->allocate(1, 1, 1);
is(scalar @parts, 3, 'three parts returned');
is(str(@parts), '34 USD, 33 USD, 33 USD', '100 / (1,1,1)');
isa_ok($parts[0], 'Coin::Hnoss::Money');

my @by_pct = $hundred->allocate(70, 20, 10);
is(str(@by_pct), '70 USD, 20 USD, 10 USD', '70/20/10 is exact');

# Arrayref form
my @arr = $hundred->allocate([1, 1, 1]);
is(str(@arr), '34 USD, 33 USD, 33 USD', 'arrayref form matches list form');

# Two-way split
my @halves = $hundred->allocate(1, 1);
is(str(@halves), '50 USD, 50 USD', 'even 2-way split');

# Odd amount, two-way
my $odd = Coin::Hnoss::Money->new(101, 'USD');
is(str($odd->allocate(1, 1)), '51 USD, 50 USD', 'odd split (first gets extra)');

# Three-way odd
is(str($hundred->allocate(1, 1, 1)),
   '34 USD, 33 USD, 33 USD',
   'extra unit goes to first');

# N units, extra goes to first N
my $ten = Coin::Hnoss::Money->new(10, 'USD');
is(str($ten->allocate(1, 1, 1, 1)),
   '3 USD, 3 USD, 2 USD, 2 USD',
   'first two get the extra units');

# --- invariants --------------------------------------------------------------

for my $case (
    [ 100, [1, 1, 1] ],
    [ 100, [70, 20, 10] ],
    [ 101, [1, 1, 1] ],
    [ 999, [33, 33, 34] ],
    [   1, [1, 1, 1] ],
    [   2, [1, 1, 1] ],
    [ -100, [1, 1, 1] ],
    [ -101, [1, 1, 1] ],
    [ 12345, [7, 11, 13, 17] ],
) {
    my ($amt, $ratios) = @$case;
    my $m = Coin::Hnoss::Money->new($amt, 'USD');
    my @p = $m->allocate(@$ratios);
    my $sum = Coin::Hnoss::Money->new(0, 'USD');
    $sum = $sum->add($_) for @p;
    is($sum->as_string, "$amt USD",
       "sum invariant for amount=$amt ratios=@$ratios");
    is(scalar @p, scalar @$ratios,
       "count matches ratio count for amount=$amt ratios=@$ratios");
}

# --- zero ratios -------------------------------------------------------------

is(str($hundred->allocate(0, 1)),
   '0 USD, 100 USD',
   'zero ratio gets nothing');

is(str($hundred->allocate(1, 0, 1)),
   '50 USD, 0 USD, 50 USD',
   'middle zero ratio');

is(str($hundred->allocate(0, 0, 1, 0)),
   '0 USD, 0 USD, 100 USD, 0 USD',
   'leading/trailing zeros');

# --- negative amounts --------------------------------------------------------

my $neg = Coin::Hnoss::Money->new(-100, 'USD');
is(str($neg->allocate(1, 1, 1)),
   '-34 USD, -33 USD, -33 USD',
   'negative amount mirror-split');

my $negOdd = Coin::Hnoss::Money->new(-101, 'USD');
is(str($negOdd->allocate(1, 1, 1)),
   '-34 USD, -34 USD, -33 USD',
   'negative odd mirror-split');

# --- validation errors -------------------------------------------------------

ok(!eval { $hundred->allocate(); 1 }, 'empty ratio list dies');
like("$@", qr/at least one ratio/, 'empty ratio message');

ok(!eval { $hundred->allocate([]); 1 }, 'empty arrayref dies');

ok(!eval { $hundred->allocate(0, 0, 0); 1 }, 'all-zero ratios die');
like("$@", qr/not all be zero/, 'all-zero message');

ok(!eval { $hundred->allocate(1, -1); 1 }, 'negative ratio dies');
like("$@", qr/must not be negative/, 'negative ratio message');

ok(!eval { $hundred->allocate(1, 1.5); 1 }, 'float ratio dies');
like("$@", qr/must be an integer/, 'float ratio message');

ok(!eval { $hundred->allocate(1, 'abc'); 1 }, 'non-numeric ratio dies');

ok(!eval { $hundred->allocate(1, undef); 1 }, 'undef ratio dies');
like("$@", qr/is required/, 'undef ratio message');

# --- exceptions are objects --------------------------------------------------

eval { $hundred->allocate(0, 0) };
ok(ref $@ && $@->isa('Coin::Hnoss::Exception'),
   'allocation exception is a Coin::Hnoss::Exception object');

done_testing;
