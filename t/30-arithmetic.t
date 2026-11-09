use strict;
use warnings;
use Test::More;

use Coin::Hnoss::Money;
use Coin::Hnoss::Exception;

my $usd500 = Coin::Hnoss::Money->new(500, 'USD');
my $usd250 = Coin::Hnoss::Money->new(250, 'USD');
my $eur500 = Coin::Hnoss::Money->new(500, 'EUR');

# --- add ---------------------------------------------------------------------

my $sum = $usd500->add($usd250);
isa_ok($sum, 'Coin::Hnoss::Money');
is($sum->as_string, '750 USD', 'add returns a new Money');
is($usd500->as_string, '500 USD', 'original unchanged after add');

# --- subtract ----------------------------------------------------------------

my $dif = $usd500->subtract($usd250);
is($dif->as_string, '250 USD', 'subtract');
is($usd500->as_string, '500 USD', 'original unchanged after subtract');

# --- multiply ----------------------------------------------------------------

is($usd250->multiply(2)->as_string, '500 USD', 'multiply by int');
is($usd250->multiply('3')->as_string, '750 USD', 'multiply by int string');
is($usd250->multiply(0)->as_string, '0 USD', 'multiply by zero');
is($usd250->multiply(-1)->as_string, '-250 USD', 'multiply by negative');

# --- divide ------------------------------------------------------------------

is($usd500->divide(2)->as_string, '250 USD', 'divide exact');
is($usd500->divide(3)->as_string, '166 USD', 'divide truncates toward zero');
is($usd250->divide(-2)->as_string, '-125 USD', 'divide by negative');

# --- divide_with_remainder ---------------------------------------------------

my ($q, $r) = $usd500->divide_with_remainder(3);
is($q->as_string, '166 USD', 'quotient');
is($r->as_string, '2 USD',   'remainder');

# Negative dividend: BigInt's bdiv truncates toward zero
my $neg = Coin::Hnoss::Money->new(-500, 'USD');
my ($qn, $rn) = $neg->divide_with_remainder(3);
is($qn->as_string, '-166 USD', 'negative dividend quotient');
is($rn->as_string, '-2 USD',   'negative dividend remainder');

# --- negate / abs ------------------------------------------------------------

is($usd500->negate->as_string, '-500 USD', 'negate');
is($neg->negate->as_string,    '500 USD',  'negate negative');
is($neg->abs->as_string,       '500 USD',  'abs of negative');
is($usd500->abs->as_string,    '500 USD',  'abs of positive');

# --- currency mismatch -------------------------------------------------------

ok(!eval { $usd500->add($eur500); 1 }, 'add across currencies dies');
like("$@", qr/Cannot add money in USD and EUR/, 'add mismatch message');

ok(!eval { $usd500->subtract($eur500); 1 }, 'subtract across currencies dies');
like("$@", qr/Cannot subtract money in USD and EUR/, 'subtract mismatch message');

# --- type errors -------------------------------------------------------------

ok(!eval { $usd500->add(500); 1 }, 'add(500) dies');
like("$@", qr/Cannot add a non-Coin::Hnoss::Money/, 'add type error message');

ok(!eval { $usd500->add(undef); 1 }, 'add(undef) dies');

ok(!eval { $usd500->multiply(1.5); 1 }, 'multiply(1.5) dies');
like("$@", qr/must be an integer/, 'multiply float error');

ok(!eval { $usd500->multiply(undef); 1 }, 'multiply(undef) dies');

ok(!eval { $usd500->divide(0); 1 }, 'divide by zero dies');
like("$@", qr/Division by zero/, 'division by zero message');

ok(!eval { $usd500->divide_with_remainder(0); 1 },
   'divide_with_remainder by zero dies');

# --- exceptions are objects --------------------------------------------------

eval { $usd500->add($eur500) };
ok(ref $@ && $@->isa('Coin::Hnoss::Exception'),
   'exception is a Coin::Hnoss::Exception object');
ok(defined $@->message, 'exception has a message');
like("$@", qr/USD and EUR/, 'exception stringifies to message');

done_testing;
