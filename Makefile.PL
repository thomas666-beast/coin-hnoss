use strict;
use warnings;
use ExtUtils::MakeMaker;

my $version = '0.010';

WriteMakefile(
    NAME             => 'Coin::Hnoss',
    VERSION          => $version,
    ABSTRACT         => 'Exact monetary values for Perl',
    AUTHOR           => 'Thomas <selfworker112@mailfence.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.026',
    PREREQ_PM        => {
        # core only
    },
    TEST_REQUIRES    => {
        'Test::More' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => 'https://github.com/thomas666-beast/coin-hnoss',
            bugtracker => 'https://github.com/thomas666-beast/coin-hnoss/issues',
        },
        provides => {
            'Coin::Hnoss' => {
                file    => 'lib/Coin/Hnoss.pm',
                version => $version,
            },
            'Coin::Hnoss::Currency' => {
                file    => 'lib/Coin/Hnoss/Currency.pm',
                version => $version,
            },
            'Coin::Hnoss::Currency::Repository' => {
                file    => 'lib/Coin/Hnoss/Currency/Repository.pm',
                version => $version,
            },
            'Coin::Hnoss::Exception' => {
                file    => 'lib/Coin/Hnoss/Exception.pm',
                version => $version,
            },
            'Coin::Hnoss::Money' => {
                file    => 'lib/Coin/Hnoss/Money.pm',
                version => $version,
            },
        },
    },
);
