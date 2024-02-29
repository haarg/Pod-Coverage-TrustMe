use strict;
use warnings;

use lib 't/Test-Pod-Coverage/lib';

use Test::More;
use Test::Builder::Tester;

use Test::Pod::Coverage::TrustMe;

test_out( "ok 1 - Checking Nosymbols" );
test_out( "# Nosymbols: no public symbols defined" );
pod_coverage_ok( "Nosymbols", "Checking Nosymbols" );
test_test( "Handles files with no symbols" );

done_testing;
