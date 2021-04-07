use strict;
use warnings;
use Test::More;
use Pod::Coverage::TrustMe;

my $pc = Pod::Coverage::TrustMe->new(package => 'Pod::Coverage::TrustMe');

package wibble;
sub bar {};
package main;
sub foo {}
sub baz::baz {};
*bar = \&wibble::bar;
*baz = \&baz::baz;

is ( $pc->_CvGV(\&foo), '*main::foo',   'foo checks out' );
is ( $pc->_CvGV(\&bar), '*wibble::bar', 'bar looks right' );
is ( $pc->_CvGV(\&baz), '*baz::baz',    'baz too' );

done_testing;
