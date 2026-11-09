package Coin::Hnoss::Exception;
use strict;
use warnings;

our $VERSION = '0.004';

use Carp qw(croak);
use overload '""' => sub { $_[0]->{message} }, fallback => 1;

sub new {
    my ($class, $message) = @_;
    croak 'Coin::Hnoss::Exception->new requires a message'
        unless defined $message;
    return bless { message => $message }, $class;
}

sub message { $_[0]->{message} }

1;
__END__

=head1 NAME

Coin::Hnoss::Exception - Base exception class for Coin::Hnoss

=head1 SYNOPSIS

    use Coin::Hnoss::Exception;

    die Coin::Hnoss::Exception->new('something went wrong');

    eval { ... };
    if (my $e = $@) {
        if (ref $e && $e->isa('Coin::Hnoss::Exception')) {
            warn $e->message;
        }
    }

=head1 DESCRIPTION

Base exception class. Stringifies to its message.

=head1 METHODS

=head2 new

    Coin::Hnoss::Exception->new($message)

=head2 message

Returns the exception message.

=head1 LICENSE

Same as Perl 5.

=cut
