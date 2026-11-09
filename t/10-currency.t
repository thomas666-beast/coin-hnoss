use strict;
use warnings;
use Test::More;

use_ok('Coin::Hnoss::Currency');

# --- construction -----------------------------------------------------------

my $usd = Coin::Hnoss::Currency->new('USD');
isa_ok($usd, 'Coin::Hnoss::Currency');

is($usd->code,      'USD', 'code() returns the code');
is($usd->as_string, 'USD', 'as_string() returns the code');
is("$usd",          'USD', 'string overload returns the code');

# --- normalization ----------------------------------------------------------

is(Coin::Hnoss::Currency->new('usd')->code, 'USD', 'lowercase normalized to upper');
is(Coin::Hnoss::Currency->new('Eur')->code, 'EUR', 'mixed case normalized to upper');

# --- validation: rejected inputs --------------------------------------------

ok(!eval { Coin::Hnoss::Currency->new(undef); 1 }, 'undef rejected');
like($@, qr/requires a currency code/, 'undef error message');

ok(!eval { Coin::Hnoss::Currency->new([]); 1 }, 'arrayref rejected');
like($@, qr/plain scalar/, 'arrayref error message');

ok(!eval { Coin::Hnoss::Currency->new({}); 1 }, 'hashref rejected');

# Too short, non-letter characters, spaces, mixed-digit — all rejected.
for my $bad ('', 'U', 'US', 'U5D', 'U D', 'US D', 'US1') {
    ok(!eval { Coin::Hnoss::Currency->new($bad); 1 }, "rejects '$bad'");
    like($@, qr/Invalid currency code/,
        "correct error message for '$bad'");
}

# Over the 8-character limit — still rejected.
ok(!eval { Coin::Hnoss::Currency->new('TOOLONGXX'); 1 },
   '10-letter code rejected');
like($@, qr/Invalid currency code/, 'too-long code error message');

# --- validation: accepted longer codes (3-8 letters) ------------------------

for my $good ('USDD', 'USDX', 'USDT', 'WBTC', 'SHIB', 'AVAX') {
    my $c = eval { Coin::Hnoss::Currency->new($good) };
    isa_ok($c, 'Coin::Hnoss::Currency', "accepted '$good'");
    is($c->code, uc $good, "code normalized for '$good'");
}

# --- equality ---------------------------------------------------------------

ok($usd->equals(Coin::Hnoss::Currency->new('USD')), 'USD equals USD');
ok($usd->equals(Coin::Hnoss::Currency->new('usd')), 'USD equals usd (normalized)');
ok(!$usd->equals(Coin::Hnoss::Currency->new('EUR')), 'USD does not equal EUR');
ok(!$usd->equals(undef), 'equals(undef) is false');
ok(!$usd->equals('USD'), 'equals(raw string) is false');

# --- string eq operator -----------------------------------------------------

ok($usd eq 'USD', 'eq overload works');
ok($usd ne 'EUR', 'ne overload works');

done_testing;
