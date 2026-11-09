package Coin::Hnoss;
use strict;
use warnings;

our $VERSION = '0.003';

1;
__END__

=head1 NAME

Coin::Hnoss - Exact monetary values for Perl

=head1 SYNOPSIS

    use Coin::Hnoss;

    # (filled in as the library grows)

=head1 DESCRIPTION

C<Coin::Hnoss> is a value-object library for working with monetary amounts
without floating-point rounding errors. Amounts are stored as integers in
the currency's smallest unit (e.g. cents for USD), and arithmetic is exact.

The name comes from Old Norse: B<Hnoss> is a goddess of treasure and
precious things, and the plural I<hnossir> was used for all beautiful,
valuable objects.

Inspired by the Money pattern (Martin Fowler) and the PHP
C<moneyphp/money> library.

=head1 LICENSE

Same as Perl 5.

=cut
