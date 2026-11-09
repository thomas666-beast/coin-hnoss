package Coin::Hnoss::Currency;
use strict;
use warnings;

our $VERSION = '0.002';

use Carp qw(croak);

# ISO 4217 codes are exactly 3 ASCII letters.
my $CODE_RE = qr/\A[A-Za-z]{3}\z/;

sub new {
    my ($class, $code) = @_;

    croak 'Coin::Hnoss::Currency->new requires a currency code'
        unless defined $code;

    croak 'Coin::Hnoss::Currency code must be a plain scalar'
        if ref $code;

    croak "Invalid ISO 4217 currency code '$code'"
        unless $code =~ $CODE_RE;

    my $self = bless {
        code => uc $code,
    }, $class;

    return $self;
}

sub code { $_[0]->{code} }

sub as_string { $_[0]->{code} }

sub equals {
    my ($self, $other) = @_;
    return 0 unless defined $other && ref $other eq ref $self;
    return $self->{code} eq $other->{code};
}

# Allow string overload so "$currency" yields "USD" etc.
use overload
    '""'     => sub { $_[0]->{code} },
    'eq'     => sub { "$_[0]" eq "$_[1]" },
    'ne'     => sub { "$_[0]" ne "$_[1]" },
    fallback => 1;

1;
__END__

=head1 NAME

Coin::Hnoss::Currency - ISO 4217 currency value object

=head1 SYNOPSIS

    use Coin::Hnoss::Currency;

    my $usd = Coin::Hnoss::Currency->new('USD');
    my $eur = Coin::Hnoss::Currency->new('eur');   # normalized to 'EUR'

    $usd->code;         # 'USD'
    $usd->as_string;    # 'USD'
    "$usd";             # 'USD'

    $usd->equals($eur); # false
    $usd->equals(Coin::Hnoss::Currency->new('usd')); # true

=head1 DESCRIPTION

An immutable value object representing an ISO 4217 currency code. Codes are
validated (exactly three ASCII letters) and normalized to uppercase on
construction.

=head1 METHODS

=head2 new

    my $c = Coin::Hnoss::Currency->new('USD');

Constructs a new currency. Croaks on undefined, non-scalar, or malformed
codes.

=head2 code

=head2 as_string

Returns the normalized (uppercase) 3-letter code.

=head2 equals

    $c1->equals($c2);

Returns true if both are C<Coin::Hnoss::Currency> objects with the same code.

=head1 OPERATORS

String context (C<"$c">) yields the code. C<eq>/C<ne> compare by code.

=head1 LICENSE

Same as Perl 5.

=cut
