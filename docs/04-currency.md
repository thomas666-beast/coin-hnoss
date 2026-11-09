# Currency

`Coin::Hnoss::Currency` — an immutable value object wrapping a currency
code.

## Synopsis

    use Coin::Hnoss::Currency;

    my $usd = Coin::Hnoss::Currency->new('USD');
    my $eur = Coin::Hnoss::Currency->new('eur');   # normalized to 'EUR'

    $usd->code;         # 'USD'
    $usd->as_string;    # 'USD'
    "$usd";             # 'USD'

    $usd->equals($eur);                             # false
    $usd->equals(Coin::Hnoss::Currency->new('usd')); # true

    $usd->exponent;                                 # 2 (cents)
    Coin::Hnoss::Currency->new('JPY')->exponent;    # 0 (yen has no subunit)
    Coin::Hnoss::Currency->new('BHD')->exponent;    # 3 (fils)

## Constructor

    Coin::Hnoss::Currency->new($code)

- `$code` must be a plain scalar of 3 to 8 ASCII letters.
- Case is normalized to uppercase.
- Dies with `Coin::Hnoss::Exception` on `undef`, a reference, or a code of
  the wrong shape.

Valid:

    'USD'  'EUR'  'JPY'  'BHD'  'BTC'  'USDT'  'usd'  'Usd'

Invalid:

    undef  ''  'US'  'U'  'U5D'  'U D'  'TOOLONGXX'  []  {}

## Methods

### `code`, `as_string`

    $currency->code;       # 'USD'
    $currency->as_string;  # 'USD'

The normalized (uppercase) code. Both methods are identical; `as_string` is
provided so that the object stringifies naturally in templating contexts.

### `exponent`, `subunit`

    $currency->exponent;   # 2 for USD, 0 for JPY, 3 for BHD, 8 for BTC
    $currency->subunit;    # alias

The number of decimal places between the major unit and the smallest
storable unit. USD = 2 (dollars → cents), JPY = 0 (no subunit), BHD = 3
(dinars → fils), BTC = 8 (bitcoin → satoshi).

For unknown codes, returns the fallback exponent (2 by default). See
[Currency repository](04-currency.md#repository) below.

### `equals`

    $c1->equals($c2);

Returns true if both objects are `Coin::Hnoss::Currency` and their codes are
equal. Returns false (not an exception) on type or code mismatch.

## Operators

- `"$c"` — stringification, yields the code (`'USD'`).
- `$c eq 'USD'`, `$c ne 'EUR'` — comparison by code.

## Repository

`Coin::Hnoss::Currency::Repository` is the lookup table used by
`$currency->exponent`.

    use Coin::Hnoss::Currency::Repository;

    my $repo = Coin::Hnoss::Currency::Repository->default;

    $repo->exponent('USD');   # 2
    $repo->exponent('BTC');   # 8
    $repo->exponent('ZZZ');   # 2 (fallback)
    $repo->knows('USD');      # 1
    $repo->knows('ZZZ');      # '' (false)

See [Cryptocurrencies](11-crypto.md) for the list of supported codes, and
[Currency repository internals](11-crypto.md#custom-repositories) for how to
add your own.

## Equality semantics

Two `Currency` objects are equal if their codes are equal:

    my $a = Coin::Hnoss::Currency->new('USD');
    my $b = Coin::Hnoss::Currency->new('usd');
    $a->equals($b);   # true

This is why `Money` arithmetic can compare currencies cheaply — it's a
string comparison under the hood, once both are normalized.

## See also

- [Money](05-money.md) — how currencies are used in amounts
- [Cryptocurrencies](11-crypto.md) — BTC, TRX, USDT
