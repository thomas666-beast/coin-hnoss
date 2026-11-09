package Coin::Hnoss::Currency;
use strict;
use warnings;

our $VERSION = '0.010';

use Carp qw(croak);

use Coin::Hnoss::Currency::Repository;

# Currency codes are 3 to 8 ASCII letters. The vast majority are the
# 3-letter ISO 4217 codes (USD, EUR, JPY, ...). A handful of documented
# non-ISO extensions are longer (BTC, TRX, USDT, USDC, BUSD, ...).
my $CODE_RE = qr/\A[A-Za-z]{3,8}\z/;

sub new {
    my ($class, $code) = @_;

    croak 'Coin::Hnoss::Currency->new requires a currency code'
        unless defined $code;

    croak 'Coin::Hnoss::Currency code must be a plain scalar'
        if ref $code;

    croak "Invalid currency code '$code': must be 3-8 ASCII letters"
        unless $code =~ $CODE_RE;

    return bless {
        code => uc $code,
    }, $class;
}

sub code      { $_[0]->{code} }
sub as_string { $_[0]->{code} }

sub exponent {
    my ($self) = @_;
    return Coin::Hnoss::Currency::Repository->default->exponent($self->{code});
}

sub subunit { $_[0]->exponent }

sub equals {
    my ($self, $other) = @_;
    return 0 unless defined $other && ref $other eq ref $self;
    return $self->{code} eq $other->{code};
}

use overload
    '""'     => sub { $_[0]->{code} },
    'eq'     => sub { "$_[0]" eq "$_[1]" },
    'ne'     => sub { "$_[0]" ne "$_[1]" },
    fallback => 1;

1;
__END__

=head1 NAME

Coin::Hnoss::Currency - currency value object

=head1 SYNOPSIS

    use Coin::Hnoss::Currency;

    my $usd = Coin::Hnoss::Currency->new('USD');
    my $eur = Coin::Hnoss::Currency->new('eur');   # normalized to 'EUR'

    $usd->code;         # 'USD'
    $usd->as_string;    # 'USD'
    "$usd";             # 'USD'

    $usd->equals($eur); # false
    $usd->equals(Coin::Hnoss::Currency->new('usd')); # true

    $usd->exponent;     # 2  (cents)
    Coin::Hnoss::Currency->new('JPY')->exponent;  # 0
    Coin::Hnoss::Currency->new('BHD')->exponent;  # 3
    Coin::Hnoss::Currency->new('BTC')->exponent;  # 8  (satoshi)
    Coin::Hnoss::Currency->new('USDT')->exponent; # 6

=head1 DESCRIPTION

An immutable value object representing a currency code. Codes are validated
(3 to 8 ASCII letters) and normalized to uppercase on construction.

Almost all codes are ISO 4217 (USD, EUR, JPY, ...), but the object also
accepts documented non-ISO extensions used by crypto assets (BTC, TRX,
USDT, ...). Whether a given code is known to the built-in exponent table is
reported by L<Coin::Hnoss::Currency::Repository/knows>; the value object
itself is permissive so that custom repositories can supply any code they
need.

=head1 METHODS

=head2 new

    my $c = Coin::Hnoss::Currency->new('USD');

Constructs a new currency. Croaks on undefined, non-scalar, or malformed
codes (must match C</\A[A-Za-z]{3,8}\z/>).

=head2 code

=head2 as_string

Returns the normalized (uppercase) code.

=head2 exponent

    my $n = $currency->exponent;

Returns the number of minor-unit digits for this currency, as reported by
L<Coin::Hnoss::Currency::Repository/default>. Returns the fallback (2 for
the default repository) for codes not in the table.

=head2 subunit

Alias for C<exponent>. Both names appear in the wild; ISO calls it "minor
unit", most money libraries call it "subunit" or "exponent".

=head2 equals

    $c1->equals($c2);

Returns true if both are C<Coin::Hnoss::Currency> objects with the same code.

=head1 OPERATORS

String context (C<"$c">) yields the code. C<eq>/C<ne> compare by code.

=head1 LICENSE

Same as Perl 5.

=cut
