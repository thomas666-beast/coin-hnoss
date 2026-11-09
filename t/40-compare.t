use strict;
use warnings;
use Test::More;

use Coin::Hnoss::Money;
use Coin::Hnoss::Exception;

my $usd500 = Coin::Hnoss::Money->new( 500, 'USD');
my $usd250 = Coin::Hnoss::Money->new( 250, 'USD');
my $usd500b= Coin::Hnoss::Money->new( 500, 'USD');
my $usd0   = Coin::Hnoss::Money->new(   0, 'USD');
my $usdNeg = Coin::Hnoss::Money->new(-500, 'USD');
my $eur500 = Coin::Hnoss::Money->new( 500, 'EUR');

# --- compare -----------------------------------------------------------------

is($usd500->compare($usd250),  1, 'compare: greater');
is($usd250->compare($usd500), -1, 'compare: less');
is($usd500->compare($usd500b), 0, 'compare: equal');
is($usdNeg->compare($usd0),   -1, 'compare: negative < zero');
is($usd0->compare($usdNeg),    1, 'compare: zero > negative');

ok(!eval { $usd500->compare($eur500); 1 }, 'compare across currencies dies');
like("$@", qr/Cannot compare money in USD and EUR/, 'compare mismatch message');

ok(!eval { $usd500->compare(500); 1 }, 'compare(500) dies');
like("$@", qr/Cannot compare a non-Coin::Hnoss::Money/, 'compare type error');

ok(!eval { $usd500->compare(undef); 1 }, 'compare(undef) dies');

# --- predicates --------------------------------------------------------------

ok( $usd0->is_zero,     'is_zero on zero');
ok(!$usd500->is_zero,   'is_zero on 500');
ok(!$usdNeg->is_zero,   'is_zero on -500');

ok( $usd500->is_positive, 'is_positive on 500');
ok(!$usdNeg->is_positive, 'is_positive on -500');
ok(!$usd0->is_positive,   'is_positive on zero is false');

ok( $usdNeg->is_negative, 'is_negative on -500');
ok(!$usd500->is_negative, 'is_negative on 500');
ok(!$usd0->is_negative,   'is_negative on zero is false');

# --- convenience wrappers ----------------------------------------------------

ok( $usd500->greater_than($usd250),      'greater_than: true');
ok(!$usd250->greater_than($usd500),      'greater_than: false');
ok(!$usd500->greater_than($usd500b),     'greater_than equal: false');

ok( $usd500->greater_or_equal($usd500b), 'greater_or_equal equal: true');
ok( $usd500->greater_or_equal($usd250),  'greater_or_equal greater: true');
ok(!$usd250->greater_or_equal($usd500),  'greater_or_equal less: false');

ok( $usd250->less_than($usd500),         'less_than: true');
ok(!$usd500->less_than($usd250),         'less_than: false');
ok(!$usd500->less_than($usd500b),        'less_than equal: false');

ok( $usd500->less_or_equal($usd500b),    'less_or_equal equal: true');
ok( $usd250->less_or_equal($usd500),     'less_or_equal less: true');
ok(!$usd500->less_or_equal($usd250),     'less_or_equal greater: false');

# wrappers croak on currency mismatch
ok(!eval { $usd500->greater_than($eur500); 1 }, 'greater_than cross-currency dies');
ok(!eval { $usd500->less_than($eur500); 1 },    'less_than cross-currency dies');

# --- operator overloading ----------------------------------------------------

ok( $usd500 >  $usd250,  'operator > works');
ok(!($usd250 > $usd500), 'operator > false');
ok( $usd250 <  $usd500,  'operator < works');
ok( $usd500 >= $usd500b, 'operator >= works');
ok( $usd500 <= $usd500b, 'operator <= works');
ok( $usd500 == $usd500b, 'operator == works (same amount)');
ok(!($usd500 == $usd250), 'operator == false');
ok( $usd500 != $usd250,  'operator != works');
ok(!($usd500 != $usd500b), 'operator != false for equal');
is($usd500 <=> $usd250,  1, 'operator <=> greater');
is($usd250 <=> $usd500, -1, 'operator <=> less');
is($usd500 <=> $usd500b, 0, 'operator <=> equal');

# Operators croak on currency mismatch. Assign the comparison to a lexical
# so Perl doesn't warn about "useless use in void context".
ok(!eval { my $r = $usd500 >   $eur500; 1 }, 'operator > cross-currency dies');
like("$@", qr/Cannot compare money in USD and EUR/,
   'operator > mismatch message');

ok(!eval { my $r = $usd500 ==  $eur500; 1 }, 'operator == cross-currency dies');
ok(!eval { my $r = $usd500 <=> $eur500; 1 }, 'operator <=> cross-currency dies');

# --- regressions: previous operators still work ------------------------------

ok($usd500 eq '500 USD', 'eq overload still works');
ok($usd500 ne '500 EUR', 'ne overload still works');
is("$usd500", '500 USD', 'string overload still works');

# --- exceptions are objects --------------------------------------------------

eval { $usd500->compare($eur500) };
ok(ref $@ && $@->isa('Coin::Hnoss::Exception'),
   'compare exception is a Coin::Hnoss::Exception object');

done_testing;
