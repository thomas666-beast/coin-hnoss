package Coin::Hnoss::Money;
use strict;
use warnings;

our $VERSION = '0.009';

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

sub from_string {
    my ($class, $string, $currency, %opts) = @_;

    die Coin::Hnoss::Exception->new('from_string requires a string')
        unless defined $string;

    die Coin::Hnoss::Exception->new('from_string string must be a plain scalar')
        if ref $string;

    die Coin::Hnoss::Exception->new('from_string requires a currency')
        unless defined $currency;

    my $cur;
    if (blessed($currency) && $currency->isa('Coin::Hnoss::Currency')) {
        $cur = $currency;
    }
    elsif (!ref $currency) {
        $cur = Coin::Hnoss::Currency->new($currency);
    }
    else {
        die Coin::Hnoss::Exception->new(
            'Currency must be a Coin::Hnoss::Currency or a 3-letter code'
        );
    }

    my $decimal_mark        = exists $opts{decimal_mark}
                                ? $opts{decimal_mark} : '.';
    my $thousands_separator = exists $opts{thousands_separator}
                                ? $opts{thousands_separator} : ',';
    my $group_size          = exists $opts{group_size}
                                ? $opts{group_size} : 3;

    die Coin::Hnoss::Exception->new('decimal_mark must be a single character')
        unless defined $decimal_mark
            && !ref $decimal_mark
            && length $decimal_mark == 1;

    die Coin::Hnoss::Exception->new(
        'thousands_separator must be a string (empty to disable grouping)'
    ) unless defined $thousands_separator && !ref $thousands_separator;

    die Coin::Hnoss::Exception->new('group_size must be a positive integer')
        unless defined $group_size
            && !ref $group_size
            && $group_size =~ /\A[1-9]\d*\z/;

    die Coin::Hnoss::Exception->new(
        'decimal_mark and thousands_separator must differ'
    ) if length $thousands_separator
        && $decimal_mark eq $thousands_separator;

    # Strip thousands separators. We don't validate grouping position, only
    # that the remaining string parses. This is more forgiving than strict
    # and matches what most money libraries do.
    my $working = $string;
    if (length $thousands_separator) {
        my $sep = quotemeta $thousands_separator;
        $working =~ s/$sep//g;
    }

    my $dec = quotemeta $decimal_mark;
    die Coin::Hnoss::Exception->new(
        "Cannot parse '$string' as money: unexpected character"
    ) unless $working =~ /\A[+-]?\d+(?:$dec\d+)?\z/;

    my ($sign, $int_part, $frac_part);
    if ($working =~ /\A([+-]?)(\d+)(?:$dec(\d+))?\z/) {
        ($sign, $int_part, $frac_part) = ($1, $2, $3);
        $frac_part = '' unless defined $frac_part;
    }
    else {
        # Unreachable given the guard above, but keep a clear error if the
        # regex is ever relaxed.
        die Coin::Hnoss::Exception->new(
            "Cannot parse '$string' as money"
        );
    }

    my $exponent = $cur->exponent;
    my $digits   = length $frac_part;

    if ($digits > $exponent) {
        die Coin::Hnoss::Exception->new(
            "Too many decimal digits for " . $cur->code
            . ": got '$frac_part' (exponent is $exponent)"
        );
    }

    # Right-pad fractional part to the currency's exponent.
    $frac_part .= ('0' x ($exponent - $digits)) if $digits < $exponent;

    my $minor = Math::BigInt->new($int_part);
    if ($exponent > 0) {
        my $scale = Math::BigInt->new(10)->bpow($exponent);
        $minor->bmul($scale);
        $minor->badd(Math::BigInt->new($frac_part)) if length $frac_part;
    }

    $minor->bneg if $sign eq '-';

    return $class->new($minor, $cur);
}

sub amount { $_[0]->{amount}->copy }
sub currency { $_[0]->{currency} }
sub as_string { $_[0]->{amount}->bstr . ' ' . $_[0]->{currency}->code }

sub format {
    my ($self, %opts) = @_;

    my $with_currency       = exists $opts{with_currency}
                                ? $opts{with_currency} : 1;
    my $currency_separator  = exists $opts{currency_separator}
                                ? $opts{currency_separator} : ' ';
    my $decimal_mark        = exists $opts{decimal_mark}
                                ? $opts{decimal_mark} : '.';
    my $thousands_separator = exists $opts{thousands_separator}
                                ? $opts{thousands_separator} : ',';
    my $group_size          = exists $opts{group_size}
                                ? $opts{group_size} : 3;

    die Coin::Hnoss::Exception->new('group_size must be a positive integer')
        unless defined $group_size
            && !ref $group_size
            && $group_size =~ /\A[1-9]\d*\z/;

    my $exponent = $self->{currency}->exponent;

    my $amount = $self->{amount};
    my $sign   = $amount->is_neg ? '-' : '';
    my $abs    = $amount->copy->babs;

    my ($int_part, $frac_part);

    if ($exponent == 0) {
        $int_part  = $abs->bstr;
        $frac_part = '';
    }
    else {
        my $divisor = Math::BigInt->new(10)->bpow($exponent);
        ($int_part) = $abs->copy->bdiv($divisor->copy);
        my $rem = $abs->copy->bmod($divisor->copy);
        $frac_part = $rem->bstr;
        $frac_part = ('0' x ($exponent - length $frac_part)) . $frac_part
            if length $frac_part < $exponent;
    }

    if (length $thousands_separator && length $int_part > $group_size) {
        my @groups;
        while (length $int_part > $group_size) {
            unshift @groups, substr($int_part, -$group_size);
            $int_part = substr($int_part, 0, length($int_part) - $group_size);
        }
        unshift @groups, $int_part;
        $int_part = join $thousands_separator, @groups;
    }

    my $result = $sign . $int_part;
    $result .= $decimal_mark . $frac_part if $exponent > 0;
    $result .= $currency_separator . $self->{currency}->code if $with_currency;

    return $result;
}

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

# --- comparison -------------------------------------------------------------

sub compare {
    my ($self, $other) = @_;
    _assert_same_currency($self, $other, 'compare');
    return $self->{amount}->bcmp($other->{amount});
}

sub is_zero     { $_[0]->{amount}->is_zero }
sub is_positive { !$_[0]->{amount}->is_neg && !$_[0]->{amount}->is_zero }
sub is_negative { $_[0]->{amount}->is_neg ? 1 : 0 }

sub greater_than     { $_[0]->compare($_[1]) >  0 }
sub greater_or_equal { $_[0]->compare($_[1]) >= 0 }
sub less_than        { $_[0]->compare($_[1]) <  0 }
sub less_or_equal    { $_[0]->compare($_[1]) <= 0 }

# --- allocation -------------------------------------------------------------

sub allocate {
    my ($self, @ratios) = @_;

    @ratios = @{ $ratios[0] }
        if @ratios == 1 && ref $ratios[0] eq 'ARRAY';

    die Coin::Hnoss::Exception->new('allocate requires at least one ratio')
        unless @ratios;

    my @r = map { _as_integer($_, 'allocate ratio') } @ratios;

    my $sum = Math::BigInt->new(0);
    for my $r (@r) {
        die Coin::Hnoss::Exception->new('allocate ratio must not be negative')
            if $r->is_neg;
        $sum->badd($r);
    }

    die Coin::Hnoss::Exception->new('allocate ratios must not all be zero')
        if $sum->is_zero;

    my $sign       = $self->{amount}->is_neg ? -1 : 1;
    my $abs_amount = $self->{amount}->copy->babs;

    my @shares;
    my $allocated = Math::BigInt->new(0);
    for my $r (@r) {
        my $numerator = $abs_amount->copy->bmul($r);
        my ($q) = $numerator->bdiv($sum->copy);
        push @shares, $q;
        $allocated->badd($q);
    }

    my $rem = $abs_amount->copy->bsub($allocated);
    my $n   = scalar @shares;
    my $i   = 0;
    while (!$rem->is_zero) {
        $shares[$i]->binc;
        $rem->bdec;
        $i = ($i + 1) % $n;
    }

    if ($sign < 0) {
        $_->bneg for @shares;
    }

    return map { ref($self)->new($_, $self->{currency}) } @shares;
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
    '<=>'    => sub { $_[0]->compare($_[1]) },
    '=='     => sub { $_[0]->compare($_[1]) == 0 },
    '!='     => sub { $_[0]->compare($_[1]) != 0 },
    '<'      => sub { $_[0]->compare($_[1]) <  0 },
    '>'      => sub { $_[0]->compare($_[1]) >  0 },
    '<='     => sub { $_[0]->compare($_[1]) <= 0 },
    '>='     => sub { $_[0]->compare($_[1]) >= 0 },
    fallback => 1;

1;
__END__

=head1 NAME

Coin::Hnoss::Money - Immutable monetary value object

=head1 SYNOPSIS

    use Coin::Hnoss::Money;

    # Construct from minor units
    my $a = Coin::Hnoss::Money->new(500, 'USD');   # 500 cents = $5.00

    # Construct from a major-unit string
    my $b = Coin::Hnoss::Money->from_string('5.00', 'USD');   # 500 USD
    my $c = Coin::Hnoss::Money->from_string('5',    'USD');   # 500 USD
    my $d = Coin::Hnoss::Money->from_string('0.500', 'BHD');  # 500 BHD
    my $e = Coin::Hnoss::Money->from_string('500',   'JPY');  # 500 JPY

    # Custom separators
    my $f = Coin::Hnoss::Money->from_string(
        '1.234,56', 'EUR',
        decimal_mark        => ',',
        thousands_separator => '.',
    );  # 123456 EUR

=head1 DESCRIPTION

An immutable value object representing an amount of money in a given
currency. The amount is stored as an integer in the currency's smallest
unit (e.g. cents for USD). No floating-point arithmetic is used.

=head1 METHODS

=head2 new

    Coin::Hnoss::Money->new($amount, $currency)

C<$amount> is in the currency's smallest unit. Must be an integer (or
integer string, or C<Math::BigInt>). C<$currency> may be a
C<Coin::Hnoss::Currency> object or a 3-letter string.

=head2 from_string

    Coin::Hnoss::Money->from_string($string, $currency, %options)

Parses C<$string> as an amount in B<major> units (i.e. C<"5.00"> for USD is
5 dollars, stored internally as 500 minor units) and returns a
C<Coin::Hnoss::Money>.

Options (all optional, mirror C<format>):

=over

=item C<decimal_mark> - single character, default C<'.'>.

=item C<thousands_separator> - string, default C<','>. Pass C<''> to
disable grouping on input (which is only used to strip separators).

=item C<group_size> - positive integer, default 3. Validated, but not
used to check grouping position.

=back

Strict about precision: if the decimal part has more digits than the
currency's exponent, C<from_string> dies. It never silently rounds.

Examples:

    Money->from_string('5.00',   'USD');   # 500 USD
    Money->from_string('5',      'USD');   # 500 USD
    Money->from_string('5.5',    'USD');   # 550 USD
    Money->from_string('-0.05',  'USD');   # -5 USD
    Money->from_string('1,234.56', 'USD'); # 123456 USD
    Money->from_string('500',    'JPY');   # 500 JPY
    Money->from_string('0.500',  'BHD');   # 500 BHD

    Money->from_string('5.001', 'USD');   # dies: too many decimals
    Money->from_string('5.5',   'JPY');   # dies: too many decimals

=head2 amount

=head2 currency

=head2 as_string

Returns C<< "<amount> <code>" >>, e.g. C<"500 USD">. This is the raw
canonical form (integer amount, then code). For human-facing output use
C<format>.

=head2 format

    my $s = $money->format(%options);

Returns a formatted string. The amount is rendered using the currency's
minor-unit exponent with no floating point arithmetic.

Options: C<with_currency> (default true), C<currency_separator>
(default C<' '>), C<decimal_mark> (default C<'.'>),
C<thousands_separator> (default C<','>), C<group_size> (default 3).

Examples:

    Money->new(   500, 'USD')->format;   # "5.00 USD"
    Money->new(   500, 'JPY')->format;   # "500 JPY"
    Money->new(   500, 'BHD')->format;   # "0.500 BHD"
    Money->new(123456, 'USD')->format;   # "1,234.56 USD"

=head2 equals

=head2 add

=head2 subtract

=head2 multiply

=head2 divide

=head2 divide_with_remainder

=head2 negate

=head2 abs

=head2 compare

=head2 is_zero

=head2 is_positive

=head2 is_negative

=head2 greater_than

=head2 greater_or_equal

=head2 less_than

=head2 less_or_equal

=head2 allocate

See L<Coin::Hnoss::Money/"from_string"> for parsing,
L<Coin::Hnoss::Money/"format"> for display, and the arithmetic /
comparison / allocation methods for everything else.

=head1 OPERATORS

=over

=item * String context (C<"$m">) yields C<as_string()>, not C<format()>.

=item * C<eq> / C<ne> compare string forms (i.e. C<as_string>).

=item * C<< <=> >>, C<==>, C<!=>, C<< < >>, C<< > >>, C<< <= >>, C<< >= >>
compare amounts and B<require the same currency>.

=back

=head1 ERRORS

Arithmetic, comparison, allocation, formatting, and parsing errors die
with a L<Coin::Hnoss::Exception>.

=head1 LICENSE

Same as Perl 5.

=cut
