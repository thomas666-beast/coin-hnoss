use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Coin::Hnoss',
    VERSION_FROM     => 'lib/Coin/Hnoss.pm',
    ABSTRACT         => 'Exact monetary values for Perl',
    AUTHOR           => 'Thomas <selfworker112@mailfence.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.026',
    PREREQ_PM        => {
        # core only for now
    },
    TEST_REQUIRES    => {
        'Test::More' => '0',
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/thomas666-beast/coin-hnoss',
            bugtracker => 'https://github.com/thomas666-beast/coin-hnoss/issues',
        },
    },
);
