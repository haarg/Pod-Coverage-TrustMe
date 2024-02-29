use strict;
use warnings;
use Test::More;
use Pod::Coverage::TrustMe;

unshift @INC, 't/corpus/full';

for my $file (glob('t/corpus/full/*.pm')) {
  $file =~ s{\At/corpus/full/}{};
  my $package = $file;
  $package =~ s{\.pm\z}{};
  $package =~ s{/|\\}{::}g;

  my $cover = Pod::Coverage::TrustMe->new(
    package => $package,
    require_link => 1,
  );

  is $cover->coverage, 1, "$file is covered"
    or diag $cover->report;
}

done_testing;
