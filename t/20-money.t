use strict;
use warnings;
use Test::More;

use Math::BigInt;

use_ok('Coin::Hnoss::Money');
use_ok('Coin::Hnoss::Currency');

# --- construction -----------------------------------------------------------

my $usd500 = Coin::Hnoss::Money->new(500, 'USD');
isa_ok($usd500, 'Coin::Hnoss::Money');

isa_ok($usd500->currency, 'Coin::Hnoss::Currency');
is($usd500->currency->code, 'USD', 'currency code is USD');

isa_ok($usd500->amount, 'Math::BigInt');
is($usd500->amount->bstr, '500', 'amount is 500');

is($usd500->as_string, '500 USD', 'as_string');
is("$usd500",          '500 USD', 'string overload');

# Accept a Currency object as well
my $eur = Coin::Hnoss::Currency->new('EUR');
my $eur500 = Coin::Hnoss::Money->new(500, $eur);
is($eur500->currency->code, 'EUR', 'currency object accepted');

# Accept BigInt and integer strings
is(Coin::Hnoss::Money->new('500', 'USD')->amount->bstr, '500',
   'integer string accepted');
is(Coin::Hnoss::Money->new(Math::BigInt->new(500), 'USD')->amount->bstr, '500',
   'Math::BigInt accepted');

# Currency strings are normalized
is(Coin::Hnoss::Money->new(500, 'usd')->currency->code, 'USD',
   'lowercase currency normalized');

# Big values
my $big = Coin::Hnoss::Money->new('123456789012345678901234567890', 'USD');
is($big->amount->bstr, '123456789012345678901234567890',
   'arbitrary-precision amount');

# --- validation -------------------------------------------------------------

ok(!eval { Coin::Hnoss::Money->new(undef, 'USD'); 1 }, 'undef amount rejected');
like($@, qr/requires an amount/, 'undef amount error');

ok(!eval { Coin::Hnoss::Money->new(500, undef); 1 }, 'undef currency rejected');
like($@, qr/requires a currency/, 'undef currency error');

ok(!eval { Coin::Hnoss::Money->new(5.5, 'USD'); 1 }, 'non-integer float rejected');
like($@, qr/integer/, 'non-integer error');

ok(!eval { Coin::Hnoss::Money->new([], 'USD'); 1 }, 'arrayref amount rejected');
like($@, qr/plain integer/, 'arrayref amount error');

ok(!eval { Coin::Hnoss::Money->new(500, []); 1 }, 'arrayref currency rejected');
like($@, qr/Currency must be/, 'arrayref currency error');

ok(!eval { Coin::Hnoss::Money->new(500, 'U5D'); 1 }, 'bad currency rejected');
like($@, qr/Invalid currency code/, 'bad currency error');

# --- equality ---------------------------------------------------------------

ok($usd500->equals(Coin::Hnoss::Money->new(500, 'USD')), 'USD 500 == USD 500');
ok(!$usd500->equals(Coin::Hnoss::Money->new(501, 'USD')), 'USD 500 != USD 501');
ok(!$usd500->equals(Coin::Hnoss::Money->new(500, 'EUR')), 'USD 500 != EUR 500');
ok(!$usd500->equals(undef), 'equals(undef) is false');
ok(!$usd500->equals('500 USD'), 'equals(raw string) is false');

# --- string eq operator -----------------------------------------------------

ok($usd500 eq '500 USD', 'eq overload works');
ok($usd500 ne '500 EUR', 'ne overload works');

# --- immutability of returned amount ---------------------------------------

my $a = $usd500->amount;
$a->badd(1);
is($usd500->amount->bstr, '500', 'mutating returned amount does not affect original');

done_testing;
