use strict;
use warnings;
use Test::More;
use Pod::Coverage::TrustMe;

unshift @INC, 't/corpus';

for my $file (glob('t/corpus/*.pm')) {
  $file =~ s{\At/corpus/}{};
  my $package = $file;
  $package =~ s{\.pm\z}{};
  $package =~ s{/|\\}{::}g;

  Pod::Coverage::TrustMe->import(package => $package, require_link => 1);

  ok 1;
}

done_testing;
