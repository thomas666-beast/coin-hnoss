package Coin::Hnoss::Money;
use strict;
use warnings;

our $VERSION = '0.004';

use Carp qw(croak);
use Math::BigInt;
use Scalar::Util qw(blessed);

use Coin::Hnoss::Currency;
use Coin::Hnoss::Exception;

sub new {
    my ($class, $amount, $currency) = @_;

    croak 'Coin::Hnoss::Money->new requires an amount'
        unless defined $amount;

    croak 'Coin::Hnoss::Money->new requires a currency'
        unless defined $currency;

    croak 'Amount must be a plain integer'
        if ref $amount && !ref($amount)->isa('Math::BigInt');

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

sub amount { $_[0]->{amount}->copy }
sub currency { $_[0]->{currency} }
sub as_string { $_[0]->{amount}->bstr . ' ' . $_[0]->{currency}->code }

sub equals {
    my ($self, $other) = @_;
    return 0 unless blessed($other) && $other->isa('Coin::Hnoss::Money');
    return 0 unless $self->{currency}->equals($other->{currency});
    return $self->{amount}->bcmp($other->{amount}) == 0;
}

# --- arithmetic -------------------------------------------------------------

sub add {
    my ($self, $other) = @_;
    _assert_same_currency($self, $other, 'add');
    return ref($self)->new(
        $self->{amount}->copy->badd($other->{amount}),
        $self->{currency},
    );
}

sub subtract {
    my ($self, $other) = @_;
    _assert_same_currency($self, $other, 'subtract');
    return ref($self)->new(
        $self->{amount}->copy->bsub($other->{amount}),
        $self->{currency},
    );
}

sub multiply {
    my ($self, $factor) = @_;

    my $f = _as_integer($factor, 'multiply factor');

    return ref($self)->new(
        $self->{amount}->copy->bmul($f),
        $self->{currency},
    );
}

sub divide {
    my ($self, $divisor) = @_;
    my ($q, $r) = $self->divide_with_remainder($divisor);
    return $q;
}

sub divide_with_remainder {
    my ($self, $divisor) = @_;

    my $d = _as_integer($divisor, 'divide divisor');

    if ($d->is_zero) {
        die Coin::Hnoss::Exception->new('Division by zero');
    }

    my $amount = $self->{amount};
    # bdiv returns ($quotient, $remainder) in list context.
    my ($q, $r) = $amount->copy->bdiv($d->copy);

    return (
        ref($self)->new($q, $self->{currency}),
        ref($self)->new($r, $self->{currency}),
    );
}

sub negate {
    my ($self) = @_;
    return ref($self)->new(
        $self->{amount}->copy->bneg,
        $self->{currency},
    );
}

sub abs {
    my ($self) = @_;
    return ref($self)->new(
        $self->{amount}->copy->babs,
        $self->{currency},
    );
}

# --- helpers ----------------------------------------------------------------

sub _assert_same_currency {
    my ($self, $other, $op) = @_;

    unless (blessed($other) && $other->isa('Coin::Hnoss::Money')) {
        die Coin::Hnoss::Exception->new(
            "Cannot $op a non-Coin::Hnoss::Money value"
        );
    }

    unless ($self->{currency}->equals($other->{currency})) {
        die Coin::Hnoss::Exception->new(
            "Cannot $op money in "
            . $self->{currency}->code
            . " and "
            . $other->{currency}->code
        );
    }

    return 1;
}

sub _as_integer {
    my ($value, $label) = @_;

    die Coin::Hnoss::Exception->new("$label is required")
        unless defined $value;

    die Coin::Hnoss::Exception->new("$label must be a plain integer")
        if ref $value && !ref($value)->isa('Math::BigInt');

    my $n = Math::BigInt->new($value);

    die Coin::Hnoss::Exception->new("$label must be an integer, got '$value'")
        unless $n->is_int;

    return $n;
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

    my $a = Coin::Hnoss::Money->new(500, 'USD');
    my $b = Coin::Hnoss::Money->new(250, 'USD');

    my $sum = $a->add($b);            # 750 USD
    my $dif = $a->subtract($b);       # 250 USD
    my $twice = $a->multiply(2);      # 1000 USD
    my $half = $a->divide(2);         # 250 USD
    my ($q, $r) = $a->divide_with_remainder(3);  # 166 USD, 2 USD

    my $neg = $a->negate;             # -500 USD
    my $pos = $neg->abs;              # 500 USD

=head1 DESCRIPTION

An immutable value object representing an amount of money in a given
currency. The amount is stored as an integer in the currency's smallest
unit (e.g. cents for USD). No floating-point arithmetic is used.

=head1 METHODS

=head2 new

    Coin::Hnoss::Money->new($amount, $currency)

=head2 amount

=head2 currency

=head2 as_string

=head2 equals

See L<Coin::Hnoss::Money/"new"> for the base object; these are unchanged.

=head2 add

    my $sum = $a->add($b);

Requires C<$b> to be a C<Coin::Hnoss::Money> in the same currency. Returns a
new C<Coin::Hnoss::Money>.

=head2 subtract

    my $diff = $a->subtract($b);

Same currency required. Returns a new C<Coin::Hnoss::Money>.

=head2 multiply

    my $twice = $a->multiply(2);

C<$factor> must be an integer (or integer string, or C<Math::BigInt>).
Returns a new C<Coin::Hnoss::Money>.

=head2 divide

    my $half = $a->divide(2);

Integer (truncating toward zero) division. Returns a new
C<Coin::Hnoss::Money>. For access to the remainder, use
C<divide_with_remainder>.

=head2 divide_with_remainder

    my ($q, $r) = $a->divide_with_remainder(3);

Returns a two-element list: quotient and remainder, both C<Coin::Hnoss::Money>
in the same currency.

=head2 negate

    my $neg = $a->negate;

Returns a new C<Coin::Hnoss::Money> with the sign flipped.

=head2 abs

    my $pos = $a->abs;

Returns a new C<Coin::Hnoss::Money> with the absolute amount.

=head1 ERRORS

Arithmetic errors (currency mismatch, division by zero, non-integer
factors) die with a L<Coin::Hnoss::Exception>.

=head1 LICENSE

Same as Perl 5.

=cut
