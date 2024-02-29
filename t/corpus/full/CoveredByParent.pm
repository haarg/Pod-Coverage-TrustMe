package CoveredByParent;
use strict;
use warnings;
use CoveredFile ();
BEGIN { our @ISA = qw(CoveredFile) }

sub foo {
}

sub bar {
}

1;
__END__

=head2 foo

This is covered

L<CoveredFile>
