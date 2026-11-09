use strict;
use warnings;
use Test::More;

use Coin::Hnoss::Money;
use Coin::Hnoss::Exception;

sub money { Coin::Hnoss::Money->new(@_) }

# --- basics: exponent-2 currencies -------------------------------------------

is(money(500,   'USD')->format, '5.00 USD',   'USD 500 -> 5.00 USD');
is(money(0,     'USD')->format, '0.00 USD',   'USD 0 -> 0.00 USD');
is(money(-5,    'USD')->format, '-0.05 USD',  'USD -5 -> -0.05 USD');
is(money(1,     'USD')->format, '0.01 USD',   'USD 1 -> 0.01 USD');
is(money(99,    'USD')->format, '0.99 USD',   'USD 99 -> 0.99 USD');
is(money(100,   'USD')->format, '1.00 USD',   'USD 100 -> 1.00 USD');
is(money(1234,  'USD')->format, '12.34 USD',  'USD 1234 -> 12.34 USD');
is(money(-1234, 'USD')->format, '-12.34 USD', 'USD -1234 -> -12.34 USD');

# --- basics: exponent-0 currencies -------------------------------------------

is(money(500,  'JPY')->format, '500 JPY',  'JPY 500 -> 500 JPY');
is(money(0,    'JPY')->format, '0 JPY',    'JPY 0 -> 0 JPY');
is(money(-500, 'JPY')->format, '-500 JPY', 'JPY -500 -> -500 JPY');

# --- basics: exponent-3 currencies -------------------------------------------

is(money(500,  'BHD')->format, '0.500 BHD',  'BHD 500 -> 0.500 BHD');
is(money(1,    'BHD')->format, '0.001 BHD',  'BHD 1 -> 0.001 BHD');
is(money(1000, 'BHD')->format, '1.000 BHD',  'BHD 1000 -> 1.000 BHD');
is(money(1234, 'BHD')->format, '1.234 BHD',  'BHD 1234 -> 1.234 BHD');

# --- basics: exponent-4 ------------------------------------------------------

is(money(500, 'UYW')->format, '0.0500 UYW', 'UYW 500 -> 0.0500 UYW');

# --- fractional part zero-padding --------------------------------------------

is(money(101, 'USD')->format, '1.01 USD', 'fractional zero-padding on right');
is(money(110, 'USD')->format, '1.10 USD', 'trailing zero in fraction');

# --- thousands grouping ------------------------------------------------------

is(money(123456,     'USD')->format, '1,234.56 USD',      '123456 USD grouped');
is(money(1234567,    'USD')->format, '12,345.67 USD',     '1234567 USD grouped');
is(money(1234567890, 'USD')->format, '12,345,678.90 USD', 'big number grouped');
is(money(123456,     'JPY')->format, '123,456 JPY',       'JPY 123456 grouped');

# --- grouping disabled -------------------------------------------------------

is(money(123456, 'USD')->format(thousands_separator => ''),
   '1234.56 USD', 'grouping disabled');

is(money(123456, 'USD')->format(thousands_separator => '', with_currency => 0),
   '1234.56', 'grouping disabled, no currency');

# --- custom separators -------------------------------------------------------

is(money(123456, 'USD')->format(decimal_mark => ',', thousands_separator => '.'),
   '1.234,56 USD', 'European-style separators');

is(money(123456, 'USD')->format(decimal_mark => ','),
   '1,234,56 USD', 'only decimal_mark changed');

# --- with_currency option ----------------------------------------------------

is(money(500, 'USD')->format(with_currency => 0),
   '5.00', 'with_currency=0');

is(money(500, 'USD')->format(with_currency => 1),
   '5.00 USD', 'with_currency=1 explicit');

is(money(500, 'USD')->format(with_currency => undef),
   '5.00', 'with_currency=undef treated as false');

# --- currency_separator ------------------------------------------------------

is(money(500, 'USD')->format(currency_separator => ''),
   '5.00USD', 'empty currency separator');

is(money(500, 'USD')->format(currency_separator => "\x{00A0}"),
   "5.00\x{00A0}USD", 'non-breaking-space separator');

# --- group_size --------------------------------------------------------------
# 123456789 minor units in USD = 1,234,567.89 major units.

is(money(123456789, 'USD')->format(group_size => 2),
   '1,23,45,67.89 USD', 'group_size=2 (Indian grouping)');

is(money(123456789, 'USD')->format(group_size => 3),
   '1,234,567.89 USD', 'group_size=3 explicit');

# --- group_size validation ---------------------------------------------------

ok(!eval { money(500, 'USD')->format(group_size => 0); 1 },
   'group_size=0 dies');
like("$@", qr/group_size must be a positive integer/,
   'group_size=0 error message');

ok(!eval { money(500, 'USD')->format(group_size => -1); 1 },
   'group_size=-1 dies');

ok(!eval { money(500, 'USD')->format(group_size => 'x'); 1 },
   'group_size non-numeric dies');

ok(!eval { money(500, 'USD')->format(group_size => 1.5); 1 },
   'group_size float dies');

# --- as_string is still the raw form -----------------------------------------

is(money(500, 'USD')->as_string, '500 USD',
   'as_string unchanged (raw canonical form)');

# --- stringification is still as_string, not format --------------------------

is("" . money(500, 'USD'), '500 USD',
   'string overload still yields as_string, not format');

# --- exceptions are objects --------------------------------------------------

eval { money(500, 'USD')->format(group_size => 0) };
ok(ref $@ && $@->isa('Coin::Hnoss::Exception'),
   'format exception is a Coin::Hnoss::Exception object');

done_testing;
