use strict;
use warnings;
use Test::More;

use Coin::Hnoss::Money;
use Coin::Hnoss::Exception;

# --- basics: exponent-2 ------------------------------------------------------

is(Coin::Hnoss::Money->from_string('5.00',   'USD')->as_string, '500 USD',
   '5.00 USD -> 500');
is(Coin::Hnoss::Money->from_string('5',      'USD')->as_string, '500 USD',
   '5 USD -> 500');
is(Coin::Hnoss::Money->from_string('5.5',    'USD')->as_string, '550 USD',
   '5.5 USD -> 550');
is(Coin::Hnoss::Money->from_string('5.50',   'USD')->as_string, '550 USD',
   '5.50 USD -> 550');
is(Coin::Hnoss::Money->from_string('0.05',   'USD')->as_string, '5 USD',
   '0.05 USD -> 5');
is(Coin::Hnoss::Money->from_string('0.5',    'USD')->as_string, '50 USD',
   '0.5 USD -> 50');
is(Coin::Hnoss::Money->from_string('-0.05',  'USD')->as_string, '-5 USD',
   '-0.05 USD -> -5');
is(Coin::Hnoss::Money->from_string('+0.05',  'USD')->as_string, '5 USD',
   '+0.05 USD -> 5');
is(Coin::Hnoss::Money->from_string('-5',     'USD')->as_string, '-500 USD',
   '-5 USD -> -500');
is(Coin::Hnoss::Money->from_string('0',      'USD')->as_string, '0 USD',
   '0 USD -> 0');
is(Coin::Hnoss::Money->from_string('0.00',   'USD')->as_string, '0 USD',
   '0.00 USD -> 0');

# --- thousands separators ----------------------------------------------------

is(Coin::Hnoss::Money->from_string('1234.56',    'USD')->as_string, '123456 USD',
   '1234.56 USD -> 123456');
is(Coin::Hnoss::Money->from_string('1,234.56',   'USD')->as_string, '123456 USD',
   '1,234.56 USD -> 123456');
is(Coin::Hnoss::Money->from_string('12,345.67',  'USD')->as_string, '1234567 USD',
   '12,345.67 USD -> 1234567');
is(Coin::Hnoss::Money->from_string('1,234,567.89', 'USD')->as_string, '123456789 USD',
   '1,234,567.89 USD -> 123456789');

is(Coin::Hnoss::Money->from_string('1234.56', 'USD',
        thousands_separator => '')->as_string, '123456 USD',
   '1234.56 USD with grouping disabled -> 123456');

# --- custom separators -------------------------------------------------------

is(Coin::Hnoss::Money->from_string(
        '1.234,56', 'EUR',
        decimal_mark        => ',',
        thousands_separator => '.',
    )->as_string, '123456 EUR',
   '1.234,56 EUR with EU separators -> 123456');

is(Coin::Hnoss::Money->from_string(
        '1234,56', 'EUR',
        decimal_mark        => ',',
        thousands_separator => '.',
    )->as_string, '123456 EUR',
   '1234,56 EUR with EU decimal mark -> 123456');

# --- exponent-0 currencies ---------------------------------------------------

is(Coin::Hnoss::Money->from_string('500',   'JPY')->as_string, '500 JPY',
   '500 JPY -> 500');
is(Coin::Hnoss::Money->from_string('-500',  'JPY')->as_string, '-500 JPY',
   '-500 JPY -> -500');
is(Coin::Hnoss::Money->from_string('123456','JPY')->as_string, '123456 JPY',
   '123456 JPY -> 123456');
is(Coin::Hnoss::Money->from_string('123,456','JPY')->as_string, '123456 JPY',
   '123,456 JPY -> 123456');

# --- exponent-3 currencies ---------------------------------------------------

is(Coin::Hnoss::Money->from_string('0.500',  'BHD')->as_string, '500 BHD',
   '0.500 BHD -> 500');
is(Coin::Hnoss::Money->from_string('1.000',  'BHD')->as_string, '1000 BHD',
   '1.000 BHD -> 1000');
is(Coin::Hnoss::Money->from_string('1.234',  'BHD')->as_string, '1234 BHD',
   '1.234 BHD -> 1234');
is(Coin::Hnoss::Money->from_string('0.001',  'BHD')->as_string, '1 BHD',
   '0.001 BHD -> 1');
is(Coin::Hnoss::Money->from_string('1.2',    'BHD')->as_string, '1200 BHD',
   '1.2 BHD -> 1200 (padded to 1.200)');

# --- exponent-4 --------------------------------------------------------------

is(Coin::Hnoss::Money->from_string('0.0500', 'UYW')->as_string, '500 UYW',
   '0.0500 UYW -> 500');

# --- crypto: BTC / TRX / USDT ------------------------------------------------

is(Coin::Hnoss::Money->from_string('0.00000500', 'BTC')->as_string, '500 BTC',
   '0.00000500 BTC -> 500 satoshi');
is(Coin::Hnoss::Money->from_string('1.00000000', 'BTC')->as_string,
   '100000000 BTC', '1.00000000 BTC -> 100,000,000 satoshi');

is(Coin::Hnoss::Money->from_string('1.000000', 'TRX')->as_string,
   '1000000 TRX', '1.000000 TRX -> 1,000,000 sun');

is(Coin::Hnoss::Money->from_string('1.000000', 'USDT')->as_string,
   '1000000 USDT', '1.000000 USDT -> 1,000,000 units');

# --- round-trip with format --------------------------------------------------

for my $case (
    [ 'USD',  500,        '5.00 USD' ],
    [ 'USD',  -5,         '-0.05 USD' ],
    [ 'USD',  123456,     '1,234.56 USD' ],
    [ 'JPY',  500,        '500 JPY' ],
    [ 'JPY',  123456,     '123,456 JPY' ],
    [ 'BHD',  500,        '0.500 BHD' ],
    [ 'BHD',  1234,       '1.234 BHD' ],
    [ 'BTC',  500,        '0.00000500 BTC' ],
    [ 'TRX',  1_000_000,  '1.000000 TRX' ],
    [ 'USDT', 1_000_000,  '1.000000 USDT' ],
) {
    my ($code, $minor, $formatted) = @$case;
    my $m = Coin::Hnoss::Money->new($minor, $code);
    is($m->format, $formatted, "format for $minor $code");

    my $parsed = Coin::Hnoss::Money->from_string(
        $m->format(with_currency => 0), $code
    );
    is($parsed->as_string, "$minor $code",
       "round-trip from format for $minor $code");
}

# --- errors: too many decimal digits -----------------------------------------

ok(!eval { Coin::Hnoss::Money->from_string('5.001', 'USD'); 1 },
   '5.001 USD dies (USD exponent 2)');
like("$@", qr/Too many decimal digits for USD/,
   'too-many-decimals message mentions currency');

ok(!eval { Coin::Hnoss::Money->from_string('5.5', 'JPY'); 1 },
   '5.5 JPY dies (JPY exponent 0)');

ok(!eval { Coin::Hnoss::Money->from_string('0.0001', 'BHD'); 1 },
   '0.0001 BHD dies (BHD exponent 3)');

# --- errors: malformed input -------------------------------------------------

for my $bad ('', 'abc', '5.', '.5', '5e3', '5 5', '-', '+', '--5', '5..5') {
    ok(!eval { Coin::Hnoss::Money->from_string($bad, 'USD'); 1 },
       "malformed input '$bad' dies");
    like("$@", qr/Cannot parse/,
       "malformed input '$bad' error message");
}

ok(!eval { Coin::Hnoss::Money->from_string(undef, 'USD'); 1 },
   'undef string dies');
like("$@", qr/requires a string/, 'undef string message');

ok(!eval { Coin::Hnoss::Money->from_string([], 'USD'); 1 },
   'arrayref string dies');
like("$@", qr/plain scalar/, 'arrayref string message');

ok(!eval { Coin::Hnoss::Money->from_string('5', undef); 1 },
   'undef currency dies');
like("$@", qr/requires a currency/, 'undef currency message');

ok(!eval { Coin::Hnoss::Money->from_string('5', []); 1 },
   'arrayref currency dies');
like("$@", qr/Currency must be/, 'arrayref currency message');

ok(!eval { Coin::Hnoss::Money->from_string('5', 'U5D'); 1 },
   'bad currency code dies');
like("$@", qr/Invalid currency code/, 'bad currency code message');

# --- errors: option validation -----------------------------------------------

ok(!eval {
    Coin::Hnoss::Money->from_string('5', 'USD', decimal_mark => '..');
    1;
}, 'multi-char decimal_mark dies');
like("$@", qr/decimal_mark must be a single character/,
   'multi-char decimal_mark message');

ok(!eval {
    Coin::Hnoss::Money->from_string('5', 'USD', group_size => 0);
    1;
}, 'group_size=0 dies');

ok(!eval {
    Coin::Hnoss::Money->from_string('5', 'USD',
        decimal_mark        => ',',
        thousands_separator => ',',
    );
    1;
}, 'identical separators die');
like("$@", qr/must differ/, 'identical separators message');

# --- exceptions are objects --------------------------------------------------

eval { Coin::Hnoss::Money->from_string('5.001', 'USD') };
ok(ref $@ && $@->isa('Coin::Hnoss::Exception'),
   'from_string exception is a Coin::Hnoss::Exception object');

done_testing;
