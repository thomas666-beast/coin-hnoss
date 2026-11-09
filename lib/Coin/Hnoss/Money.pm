package Coin::Hnoss::Money;
use strict;
use warnings;

our $VERSION = '0.003';

use Carp qw(croak);
use Math::BigInt;
use Scalar::Util qw(blessed);

use Coin::Hnoss::Currency;

# Coin::Hnoss::Money->new(500, 'USD')
# Coin::Hnoss::Money->new('500', Coin::Hnoss::Currency->new('USD'))
# Coin::Hnoss::Money->new(Math::BigInt->new('500'), 'EUR')
sub new {
    my ($class, $amount, $currency) = @_;

    croak 'Coin::Hnoss::Money->new requires an amount'
        unless defined $amount;

    croak 'Coin::Hnoss::Money->new requires a currency'
        unless defined $currency;

    croak 'Amount must be a plain integer'
        if ref $amount && !ref($amount)->isa('Math::BigInt');

    # Normalize currency: accept a Currency object or a 3-letter code string.
    my $cur;
    if (blessed($currency) && $currency->isa('Coin::Hnoss::Currency')) {
        $cur = $currency;
    }
    elsif (!ref $currency) {
        $cur = Coin::Hnoss::Currency->new($currency);
    }
    else {
        croak 'Currency must be a Coin::Hnoss::Currency or a 3-letter code';
    }

    my $n = Math::BigInt->new($amount);

    croak "Amount must be an integer, got '$amount'"
        unless $n->is_int;

    return bless {
        amount   => $n,
        currency => $cur,
    }, $class;
}

sub amount {
    my ($self) = @_;
    # Return a fresh Math::BigInt so callers can't mutate our internal state.
    return $self->{amount}->copy;
}

sub currency { $_[0]->{currency} }

sub as_string { $_[0]->{amount}->bstr . ' ' . $_[0]->{currency}->code }

sub equals {
    my ($self, $other) = @_;
    return 0 unless blessed($other) && $other->isa('Coin::Hnoss::Money');
    return 0 unless $self->{currency}->equals($other->{currency});
    return $self->{amount}->bcmp($other->{amount}) == 0;
}

use overload
    '""'     => sub { $_[0]->as_string },
    'eq'     => sub { $_[0]->as_string eq "$_[1]" },
    'ne'     => sub { $_[0]->as_string ne "$_[1]" },
    fallback => 1;

1;
__END__

=head1 NAME

Coin::Hnoss::Money - Immutable monetary value object

=head1 SYNOPSIS

    use Coin::Hnoss::Money;
    use Coin::Hnoss::Currency;

    my $five = Coin::Hnoss::Money->new(500, 'USD');
    # or
    my $eur = Coin::Hnoss::Money->new(500, Coin::Hnoss::Currency->new('EUR'));

    $five->amount;      # Math::BigInt(500)
    $five->currency;    # Coin::Hnoss::Currency(USD)
    "$five";            # "500 USD"
    $five->equals($eur); # false

=head1 DESCRIPTION

An immutable value object representing an amount of money in a given
currency. The amount is stored as an integer in the currency's smallest
unit (e.g. cents for USD). No floating-point arithmetic is used.

Internally the amount is kept as a C<Math::BigInt>, so large values are
safe even on 32-bit perls.

=head1 METHODS

=head2 new

    Coin::Hnoss::Money->new($amount, $currency)

C<$amount> must be an integer (or integer string, or C<Math::BigInt>).
C<$currency> may be a C<Coin::Hnoss::Currency> object or a 3-letter string
that will be wrapped into one.

=head2 amount

Returns a fresh C<Math::BigInt> with the amount. The caller may mutate this
copy freely; it does not affect the original.

=head2 currency

Returns the C<Coin::Hnoss::Currency> object.

=head2 as_string

Returns C<< "<amount> <code>" >>, e.g. C<"500 USD">.

=head2 equals

    $m1->equals($m2);

True only if both are C<Coin::Hnoss::Money> with the same currency and the
same amount.

=head1 OPERATORS

String context yields C<as_string()>. C<eq>/C<ne> compare string forms.

=head1 LICENSE

Same as Perl 5.

=cut
