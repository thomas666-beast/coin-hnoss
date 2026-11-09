use strict;
use warnings;
use Test::More;

use_ok('Coin::Hnoss::Currency::Repository');
use_ok('Coin::Hnoss::Currency');
use_ok('Coin::Hnoss::Money');

# --- default singleton -------------------------------------------------------

my $repo = Coin::Hnoss::Currency::Repository->default;
isa_ok($repo, 'Coin::Hnoss::Currency::Repository');

is(Coin::Hnoss::Currency::Repository->default, $repo,
   'default is a singleton');

# --- well-known exponents ----------------------------------------------------

is($repo->exponent('USD'), 2, 'USD exponent 2');
is($repo->exponent('EUR'), 2, 'EUR exponent 2');
is($repo->exponent('GBP'), 2, 'GBP exponent 2');
is($repo->exponent('JPY'), 0, 'JPY exponent 0');
is($repo->exponent('KRW'), 0, 'KRW exponent 0');
is($repo->exponent('BHD'), 3, 'BHD exponent 3');
is($repo->exponent('KWD'), 3, 'KWD exponent 3');
is($repo->exponent('UYW'), 4, 'UYW exponent 4');

# Non-ISO extension
is($repo->exponent('BTC'), 8, 'BTC exponent 8 (non-ISO, documented extension)');

# Case insensitive on input
is($repo->exponent('usd'), 2, 'exponent is case-insensitive');
is($repo->exponent('Jpy'), 0, 'exponent is case-insensitive');
is($repo->exponent('btc'), 8, 'BTC lookup is case-insensitive');

# --- fallback ----------------------------------------------------------------

is($repo->fallback, 2, 'default fallback is 2');
is($repo->exponent('ZZZ'), 2, 'unknown code falls back');
is($repo->exponent(undef),  2, 'undef falls back');
is($repo->exponent([]),     2, 'arrayref falls back');

# set_fallback is per-instance
my $custom_fallback = Coin::Hnoss::Currency::Repository->default;
my $saved = $custom_fallback->fallback;
$custom_fallback->set_fallback(0);
is($custom_fallback->exponent('ZZZ'), 0, 'fallback can be changed');
$custom_fallback->set_fallback($saved);  # restore singleton

ok(!eval { $repo->set_fallback(-1); 1 }, 'negative fallback dies');
ok(!eval { $repo->set_fallback('x'); 1 }, 'non-numeric fallback dies');
ok(!eval { $repo->set_fallback(undef); 1 }, 'undef fallback dies');

# --- knows -------------------------------------------------------------------

ok( $repo->knows('USD'),  'knows USD');
ok( $repo->knows('usd'),  'knows usd (case-insensitive)');
ok( $repo->knows('JPY'),  'knows JPY');
ok( $repo->knows('BHD'),  'knows BHD');
ok( $repo->knows('BTC'),  'knows BTC (non-ISO extension)');
ok( $repo->knows('btc'),  'knows btc (case-insensitive)');
ok(!$repo->knows('ZZZ'),  'does not know ZZZ');
ok(!$repo->knows(undef),  'does not know undef');
ok(!$repo->knows([]),     'does not know arrayref');

# --- custom table ------------------------------------------------------------

my $custom = Coin::Hnoss::Currency::Repository->new({
    USD => 4,
    XYZ => 7,
});
is($custom->exponent('USD'), 4, 'custom USD is 4');
is($custom->exponent('XYZ'), 7, 'custom XYZ is 7');
is($custom->exponent('EUR'), 2, 'unknown code uses fallback (2)');
ok($custom->knows('USD'),  'custom knows USD');
ok($custom->knows('XYZ'),  'custom knows XYZ');
ok(!$custom->knows('EUR'), 'custom does not know EUR');

# --- validation of new() -----------------------------------------------------

ok(!eval { Coin::Hnoss::Currency::Repository->new([]); 1 },
   'new() with arrayref dies');
like("$@", qr/hashref/, 'arrayref error');

ok(!eval { Coin::Hnoss::Currency::Repository->new({ usd => 2 }); 1 },
   'new() with lowercase code dies');
like("$@", qr/3 uppercase ASCII letters/, 'lowercase code error');

ok(!eval { Coin::Hnoss::Currency::Repository->new({ USD => 'x' }); 1 },
   'new() with non-numeric exponent dies');
like("$@", qr/non-negative integer/, 'non-numeric exponent error');

ok(!eval { Coin::Hnoss::Currency::Repository->new({ USD => -1 }); 1 },
   'new() with negative exponent dies');

ok(!eval { Coin::Hnoss::Currency::Repository->new({ USD => undef }); 1 },
   'new() with undef exponent dies');

# --- all_codes ---------------------------------------------------------------

my @codes = $repo->all_codes;
ok(scalar(@codes) > 100, 'all_codes returns > 100 codes');
is_deeply([@codes], [sort @codes], 'all_codes is sorted');
ok((grep { $_ eq 'USD' } @codes), 'all_codes includes USD');
ok((grep { $_ eq 'JPY' } @codes), 'all_codes includes JPY');
ok((grep { $_ eq 'BTC' } @codes), 'all_codes includes BTC');

# --- Currency->exponent delegates to default repository ----------------------

is(Coin::Hnoss::Currency->new('USD')->exponent, 2, 'Currency->exponent USD');
is(Coin::Hnoss::Currency->new('JPY')->exponent, 0, 'Currency->exponent JPY');
is(Coin::Hnoss::Currency->new('BHD')->exponent, 3, 'Currency->exponent BHD');
is(Coin::Hnoss::Currency->new('UYW')->exponent, 4, 'Currency->exponent UYW');
is(Coin::Hnoss::Currency->new('BTC')->exponent, 8, 'Currency->exponent BTC');
is(Coin::Hnoss::Currency->new('ZZZ')->exponent, 2,
   'Currency->exponent unknown falls back to 2');

# subunit is an alias
is(Coin::Hnoss::Currency->new('USD')->subunit, 2, 'Currency->subunit USD');
is(Coin::Hnoss::Currency->new('JPY')->subunit, 0, 'Currency->subunit JPY');
is(Coin::Hnoss::Currency->new('BTC')->subunit, 8, 'Currency->subunit BTC');

# --- BTC integrates cleanly with Money format/from_string --------------------
# 1 BTC = 100_000_000 satoshi.
# 500 satoshi = 0.00000500 BTC (exponent 8).

my $sats = Coin::Hnoss::Money->new(500, 'BTC');
is($sats->format, '0.00000500 BTC', '500 satoshi formats as 0.00000500 BTC');

my $back = Coin::Hnoss::Money->from_string('0.00000500', 'BTC');
is($back->as_string, '500 BTC', '0.00000500 BTC round-trips to 500 satoshi');

is(Coin::Hnoss::Money->new(100_000_000, 'BTC')->format,
   '1.00000000 BTC', '1 BTC formats as 1.00000000 BTC');

done_testing;
