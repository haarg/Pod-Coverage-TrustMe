use strict;
use warnings;

use lib 't/Test-Pod-Coverage/lib';

use Test::More;
use Test::Builder::Tester;

use Test::Pod::Coverage::TrustMe;

pod_coverage_ok( "Simple", "Simple is OK" );

# Now try it under T:B:T
test_out( "ok 1 - Simple is still OK" );
pod_coverage_ok( "Simple", "Simple is still OK" );
test_test( "Simple runs under T:B:T" );

test_out( "ok 1 - Pod coverage on Simple" );
pod_coverage_ok( "Simple" );
test_test( "Simple runs under T:B:T" );

done_testing;
