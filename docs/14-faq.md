# FAQ

## Why is the amount stored in cents, not dollars?

Because floating-point arithmetic can't represent most decimal fractions
exactly. `0.1 + 0.2` is `0.30000000000000004` in IEEE 754, and adding
those up across a billing run introduces visible drift. Storing the
smallest unit as an integer eliminates the problem entirely. See
[Core concepts](03-concepts.md#the-problem-money-should-not-be-a-float).

## Why does `new(500, 'USD')` mean $5.00, not $500?

Because `new` takes the amount in the currency's **smallest unit**, which
for USD is the cent. If you have dollars, use `from_string('5.00', 'USD')`
or multiply by 100 explicitly.

## Why does `format` say `"5.00 USD"` and not `"$5.00"`?

Because symbols and currency placement are locale-specific (`$5.00` in the
US, `5,00 €` in Germany, `¥500` in Japan). Baking one style into the core
would be wrong for everyone else. `format` gives you a neutral, parseable
representation with sensible separators; symbols belong to a wrapper or a
future `Coin::Hnoss::Formatter`.

## Why does `format` die on `group_size => 0` but accept other weird options?

`group_size` is a "must be positive integer" contract; a zero means you
asked for grouping every 0 digits, which is meaningless. Other options are
passed through verbatim — `currency_separator` can be any string, including
the empty string.

## Why do comparison operators require the same currency?

Because comparing $5 to €5 is meaningless. Without overloading, Perl's
`==` would compare the memory addresses of the two objects, which is
silently wrong. We chose "die with a clear error" over "silently give the
wrong answer".

## Why is `equals` non-fatal on currency mismatch but `compare` fatal?

`equals` is a question: "are these the same?" The answer is legitimately
"no" for two different currencies. `compare` is an operation: "order these
two values". Different currencies have no ordering, so it's an error, not
a false answer. This is the same distinction `moneyphp/money` makes.

## Why does `divide` use floor, not truncation?

Floor division gives the invariant `q * d + r == original` with
`0 <= r < d` for positive divisors, which allocation depends on. Truncation
toward zero gives negative remainders for negative dividends, which breaks
the invariant. See [Arithmetic](06-arithmetic.md#why-floor-not-truncate).

## Can I add two different currencies?

No. `add` and `subtract` require matching currencies. The library doesn't
do exchange rates; if you need conversion, do it in your application with
an explicit rate, then `add`.

## Can I multiply by a float?

No. `multiply` requires an integer factor. For percentages, use
`multiply(n)->divide(d)`. For decimal factors, convert to an integer
fraction first:

    # 1.5x = 3/2
    $money->multiply(3)->divide(2);

    # 0.075 (7.5%) = 75/1000
    $money->multiply(75)->divide(1000);

## Can I round?

Not directly. `format` never rounds; `from_string` dies on too many
decimals; arithmetic is exact. If you need rounding, do it explicitly:

    # Round to nearest cent, half-up (for the special case where you have
    # a fractional-cent amount stored somehow — e.g. you did
    # multiply(5)->divide(100) and want to round the final result)
    my ($q, $r) = $money->divide_with_remainder(1);

    # (in practice, amounts are always integers, so this is rarely needed)

The design intent is that **rounding is a business decision** and should
be made visibly at the boundary, not silently in the middle of a
computation.

## Is `BTC` supported?

Yes, as a documented non-ISO extension. See
[Cryptocurrencies](11-crypto.md). Currently: `BTC`, `TRX`, `USDT`. Anything
else — ETH, LTC, XRP — should be added via a custom repository or by
requesting it in an issue.

## Why 8 decimal places for BTC, but 6 for TRX and USDT?

Because those are the real-world subunit values: 1 BTC = 100,000,000
satoshi; 1 TRX = 1,000,000 sun; 1 USDT (both TRC20 and ERC20) = 1,000,000
of the smallest USDT unit. The library uses the actual exponents of the
assets in question. See [Cryptocurrencies](11-crypto.md).

## Why can't I use `USDT` with the built-in validation?

You can. `Coin::Hnoss::Currency` accepts 3 to 8 ASCII letters. `USDT`
(4 letters), `WBTC` (4), `SHIB` (4), and `AVAX` (4) are all valid. Only
codes longer than 8 characters, or containing non-letters, are rejected.

## Why is `Coin::Hnoss::Exception` a class, not just a string?

So that callers can catch our exceptions without catching unrelated ones:

    eval { $m->add($other) };
    if (my $e = $@) {
        if (ref $e && $e->isa('Coin::Hnoss::Exception')) {
            # handle money error
        }
        else {
            die $e;   # not ours
        }
    }

String exceptions force `$@` string matching, which is fragile.

## Can I use this in a web app / async framework / anything?

Yes. There's no I/O, no global state (apart from the cached default
repository, which is read-only unless you deliberately call
`set_fallback`), no dependencies. `Money` and `Currency` are plain Perl
objects. Nothing in the library blocks.

## What's the performance like?

For normal amounts (up to ~64-bit), `Math::BigInt` is fast enough that
you'll never notice — a few microseconds per operation. For huge amounts,
it's slower, but still predictable. If you have a hot loop doing millions
of `Money` operations, consider caching or batching; otherwise, don't
worry about it.

## See also

- [Core concepts](03-concepts.md)
- [Exceptions](12-exceptions.md)
- [Cryptocurrencies](11-crypto.md)
