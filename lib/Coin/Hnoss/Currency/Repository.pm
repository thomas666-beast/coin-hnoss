package Coin::Hnoss::Currency::Repository;
use strict;
use warnings;

our $VERSION = '0.007_01';

use Carp qw(croak);

# ISO 4217 active currencies and their minor-unit exponents.
# Source: ISO 4217 list (as of 2024/2025).
# Names are here only for documentation purposes; exponent is what matters.
my %ISO_4217 = (
    # --- exponent 0: no minor unit ---
    BIF => 0, CLP => 0, DJF => 0, GNF => 0, ISK => 0, JPY => 0,
    KMF => 0, KRW => 0, PYG => 0, RWF => 0, UGX => 0, UYI => 0,
    VND => 0, VUV => 0, XAF => 0, XOF => 0, XPF => 0,

    # --- exponent 2: two minor units (the vast majority) ---
    AED => 2, AFN => 2, ALL => 2, AMD => 2, ANG => 2, AOA => 2,
    ARS => 2, AUD => 2, AWG => 2, AZN => 2, BAM => 2, BBD => 2,
    BDT => 2, BGN => 2, BMD => 2, BND => 2, BOB => 2, BOV => 2,
    BRL => 2, BSD => 2, BTN => 2, BWP => 2, BYN => 2, BZD => 2,
    CAD => 2, CDF => 2, CHE => 2, CHF => 2, CHW => 2, CNY => 2,
    COP => 2, COU => 2, CRC => 2, CUC => 2, CUP => 2, CVE => 2,
    CZK => 2, DKK => 2, DOP => 2, DZD => 2, EGP => 2, ERN => 2,
    ETB => 2, EUR => 2, FJD => 2, FKP => 2, GBP => 2, GEL => 2,
    GHS => 2, GIP => 2, GMD => 2, GTQ => 2, GYD => 2, HKD => 2,
    HNL => 2, HRK => 2, HTG => 2, HUF => 2, IDR => 2, ILS => 2,
    INR => 2, IRR => 2, JMD => 2, KES => 2, KGS => 2, KHR => 2,
    KPW => 2, KYD => 2, KZT => 2, LAK => 2, LBP => 2, LKR => 2,
    LRD => 2, LSL => 2, MAD => 2, MDL => 2, MGA => 2, MKD => 2,
    MMK => 2, MNT => 2, MOP => 2, MRU => 2, MUR => 2, MVR => 2,
    MWK => 2, MXN => 2, MXV => 2, MYR => 2, MZN => 2, NAD => 2,
    NGN => 2, NIO => 2, NOK => 2, NPR => 2, NZD => 2, PAB => 2,
    PEN => 2, PGK => 2, PHP => 2, PKR => 2, PLN => 2, QAR => 2,
    RON => 2, RSD => 2, RUB => 2, SAR => 2, SBD => 2, SCR => 2,
    SDG => 2, SEK => 2, SGD => 2, SHP => 2, SLE => 2, SLL => 2,
    SOS => 2, SRD => 2, SSP => 2, STN => 2, SVC => 2, SYP => 2,
    SZL => 2, THB => 2, TJS => 2, TMT => 2, TOP => 2, TRY => 2,
    TTD => 2, TWD => 2, TZS => 2, UAH => 2, USD => 2, USN => 2,
    UYU => 2, UYW => 4, UZS => 2, VED => 2, VES => 2, WST => 2,
    XCD => 2, YER => 2, ZAR => 2, ZMW => 2, ZWG => 2,

    # --- exponent 3: three minor units ---
    BHD => 3, IQD => 3, JOD => 3, KWD => 3, LYD => 3, OMR => 3, TND => 3,

    # --- exponent 4: four minor units ---
    CLF => 4,

    # --- metatokens / "no currency" ---
    XAG => 0, XAU => 0, XBA => 0, XBB => 0, XBC => 0, XBD => 0,
    XDR => 0, XPD => 0, XPT => 0, XSU => 0, XTS => 0, XUA => 0,
    XXX => 0,
);

# Historical / deprecated codes that still show up in legacy data.
my %HISTORICAL = (
    BYR => 0,  # Belarusian ruble (old), before BYN
    MRO => 1,  # Mauritanian ouguiya, before MRU; had 5 khoums
    STD => 2,  # São Tomé and Príncipe dobra, before STN
    VEF => 2,  # Venezuelan bolívar, before VES
    VEB => 2,  # older Venezuelan bolívar
    ZWL => 2,  # Zimbabwe dollar, before ZWG
    ZWD => 2,  # older Zimbabwe dollar
);

my %DEFAULT_TABLE = (%ISO_4217, %HISTORICAL);

# File-scoped singleton for ->default. Plain `my`, not `state`, so we don't
# depend on any feature pragma.
my $DEFAULT_REPOSITORY;

sub new {
    my ($class, $table) = @_;

    $table = {} unless defined $table;
    croak 'Repository->new requires a hashref'
        unless ref $table eq 'HASH';

    my %copy;
    for my $code (keys %$table) {
        croak "Currency code '$code' must be 3 uppercase ASCII letters"
            unless $code =~ /\A[A-Z]{3}\z/;
        my $exp = $table->{$code};
        croak "Exponent for '$code' must be a non-negative integer"
            unless defined $exp && !ref $exp && $exp =~ /\A\d+\z/;
        $copy{$code} = 0 + $exp;
    }

    return bless {
        table    => \%copy,
        fallback => 2,
    }, $class;
}

sub default {
    my ($class) = @_;
    $DEFAULT_REPOSITORY ||= $class->new({%DEFAULT_TABLE});
    return $DEFAULT_REPOSITORY;
}

sub knows {
    my ($self, $code) = @_;
    return 0 unless defined $code && !ref $code;
    return exists $self->{table}->{uc $code} ? 1 : 0;
}

sub exponent {
    my ($self, $code) = @_;
    if (defined $code && !ref $code) {
        my $c = uc $code;
        return $self->{table}->{$c} if exists $self->{table}->{$c};
    }
    return $self->{fallback};
}

sub fallback { $_[0]->{fallback} }

sub set_fallback {
    my ($self, $n) = @_;
    croak 'Fallback exponent must be a non-negative integer'
        unless defined $n && !ref $n && $n =~ /\A\d+\z/;
    $self->{fallback} = 0 + $n;
    return $self;
}

sub all_codes {
    my ($self) = @_;
    return sort keys %{ $self->{table} };
}

1;
__END__

=head1 NAME

Coin::Hnoss::Currency::Repository - ISO 4217 currency metadata

=head1 SYNOPSIS

    use Coin::Hnoss::Currency::Repository;

    my $repo = Coin::Hnoss::Currency::Repository->default;

    $repo->exponent('USD');   # 2
    $repo->exponent('JPY');   # 0
    $repo->exponent('BHD');   # 3
    $repo->exponent('ZZZ');   # 2  (fallback)

    $repo->knows('USD');      # 1
    $repo->knows('ZZZ');      # '' (false)

    # Custom table (useful in tests)
    my $custom = Coin::Hnoss::Currency::Repository->new({ USD => 4 });
    $custom->exponent('USD'); # 4

=head1 DESCRIPTION

Provides minor-unit (subunit) exponent information for ISO 4217 currencies.
The default repository ships with a hard-coded table of active and
historical codes, so no filesystem, network, or JSON parser is required.

Exponent means "how many digits after the decimal point": USD has exponent
2 (cents), JPY has exponent 0 (yen), BHD has exponent 3 (fils).

Unknown codes fall back to exponent 2 (the overwhelmingly most common
value, and what most money libraries use by default). Use
C<set_fallback> to change this per-repository.

=head1 CLASS METHODS

=head2 default

    my $repo = Coin::Hnoss::Currency::Repository->default;

Returns a process-wide singleton with the built-in table. The singleton is
mutable (C<set_fallback> affects it), so avoid mutating it from library
code; create your own instance with C<new> if you need customization.

=head2 new

    my $repo = Coin::Hnoss::Currency::Repository->new(\%table);

Builds a repository from the given hashref mapping uppercase 3-letter codes
to non-negative integer exponents. Croaks if any key or value is malformed.

=head1 INSTANCE METHODS

=head2 exponent

    my $n = $repo->exponent('USD');

Returns the exponent for the given code, or the fallback for unknown codes.
Case-insensitive on input.

=head2 knows

    if ($repo->knows('USD')) { ... }

True if the code is in the table (does not consult the fallback).

=head2 fallback

Returns the current fallback exponent (default 2).

=head2 set_fallback

    $repo->set_fallback(0);

Sets the fallback exponent. Returns the repository for chaining.

=head2 all_codes

    my @codes = $repo->all_codes;

Returns the sorted list of known codes.

=head1 LICENSE

Same as Perl 5.

=cut
