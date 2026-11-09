use strict;
use warnings;
use Test::More;

ok( eval { require Coin::Hnoss; 1 }, 'Coin::Hnoss loads' )
    or diag $@;

ok( defined $Coin::Hnoss::VERSION, 'Coin::Hnoss has a version' );
like( $Coin::Hnoss::VERSION, qr/^\d+\.\d+$/, 'version looks sane' );

done_testing;
