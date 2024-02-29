use strict;
use warnings;

use lib 't/Test-Pod-Coverage/lib';

use Test::More;
use Test::Builder::Tester;

use Test::Pod::Coverage::TrustMe;

test_out( "not ok 1 - Checking Nopod" );
test_fail(+7);
test_diag( "         got: '  0%'" );
test_diag( "    expected: '100%'" );
test_diag( "Naked subroutines:" );
test_diag( "    bar" );
test_diag( "    baz" );
test_diag( "    foo" );
pod_coverage_ok( "Nopod", "Checking Nopod" );
test_test( "Handles files with no pod at all" );

done_testing;
