use strict;
use warnings;

use lib 't/Test-Pod-Coverage/lib';

use Test::More;
use Test::Builder::Tester;

use Test::Pod::Coverage::TrustMe;

OPTIONAL_MESSAGE: {
    test_out( "ok 1 - Pod coverage on Simple" );
    pod_coverage_ok( "Simple" );
    test_test( "Simple runs under T:B:T" );
}

done_testing;
