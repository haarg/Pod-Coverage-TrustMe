package Pod::Coverage::TrustMe;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use Pod::Coverage ();
our @ISA = qw(Pod::Coverage);

use Pod::Coverage::TrustMe::Parser;
use B ();
use Devel::Symdump ();
use constant GVf_IMPORTED_CV => B->can('GVf_IMPORTED_CV') ? B::GVf_IMPORTED_CV() : 0x80;

sub new {
  my ($class, %args) = @_;
  $args{trust_roles} = 1
    if !exists $args{trust_roles};
  $args{trust_parents} = 1
    if !exists $args{trust_parents};
  $args{trust_pod} = 1
    if !exists $args{trust_pod};
  $args{require_link} = 0
    if !exists $args{require_link};
  $args{export_only} = 0
    if !exists $args{export_only};
  $args{trust_imported} = 1
    if !exists $args{trust_imported};

  my $self = $class->SUPER::new(%args);

  my $package = $self->{package};
  eval { require($self->_mod_for($package)); 1 } or do {
    $self->{why_unrated} = "requiring '$package' failed: $@";
  };

  return $self;
}

sub _search_packages {
  my $self = shift;
  my $package = $self->{package};
  return grep +(
    $_ ne 'main'
    && $_ ne ''
    && $_ ne 'UNIVERSAL'
    && $_ ne $package
  ), Devel::Symdump->rnew->packages;
}

sub _get_roles {
  my $self = shift;
  my $package = $self->{package};
  my $does
    = $package->can('does') ? 'does'
    : $package->can('DOES') ? 'DOES'
                            : 'isa'
    ;
  return grep $package->$does($_), $self->_search_packages;
}

sub _get_parents {
  my $self = shift;
  my $package = $self->{package};
  return grep $package->isa($_), $self->_search_packages;
}

sub _mod_for {
  my $self = shift;
  my ($package) = @_;
  (my $mod = "$package.pm") =~ s{::}{/}g;
  return $mod;
}

sub _pod_for {
  my $self = shift;
  my ($package) = @_;
  if ($self->{package} eq $package && exists $self->{pod_from}) {
    return $self->{pod_from};
  }

  my $mod = $self->_mod_for($package);
  my $full = $INC{$mod} or return;
  (my $maybe_pod = $full) =~ s{\.pm\z}{.pod};
  my $pod
    = -e $maybe_pod ? $maybe_pod
    : -e $full      ? $full
                    : undef
    ;
  if ($self->{package} eq $package) {
    $self->{pod_from} = $pod;
  }
  return $pod;
}

sub trusted_packages {
  my $self = shift;

  my %to_parse = (
    $self->{package} => 1,
  );
  @to_parse{$self->_get_roles} = ()
    if $self->{trust_roles};
  @to_parse{$self->_get_parents} = ()
    if $self->{trust_parents};

  my @trusted = sort keys %to_parse;
  return @trusted;
}

sub _new_pod_parser {
  my $self = shift;

  my $parser = Pod::Coverage::TrustMe::Parser->new;
  if ($self->{nonwhitespace}) {
    $parser->ignore_empty(1);
  }
  return $parser;
}

sub _parsed {
  my $self = shift;
  return $self->{_parsed}
    if $self->{_parsed};

  my %parsed = map {
    my $pack = $_;
    my $pod = $self->_pod_for($pack);

    $pod ? do {
      my $parser = $self->_new_pod_parser;
      $parser->parse_file($pod);

      ($pack => $parser);
    } : ();
  } $self->trusted_packages;

  if ($self->{require_link}) {
    my $package = $self->{package};
    my %allowed;
    my %find_links = (
      $package => delete $parsed{$package},
    );

    while (%find_links) {
      @allowed{keys %find_links} = values %find_links;
      %find_links =
        map +(exists $parsed{$_} ? ($_ => delete $parsed{$_}) : ()),
        map @{ $_->links },
        values %find_links;
    }

    %parsed = %allowed;
  }

  $self->{_parsed} = \%parsed;
}

sub _symbols_for {
  my $self = shift;
  my ($package) = @_;

  my @symbols;
  no strict 'refs';

  if ($self->{export_only}) {
    @symbols = (
      @{"${package}::EXPORT"},
      @{"${package}::EXPORT_OK"},
    );
  }
  else {
    my $syms = Devel::Symdump->new($package);
    for my $sym ( $syms->functions ) {
      if (!$self->{trust_imported}) {
        if (B::svref_2object(\*{$sym})->GvFLAGS & GVf_IMPORTED_CV) {
          next;
        }
      }

      $sym =~ s/\A\Q$package\E:://;

      next
        if $self->_private_check($sym);

      push @symbols, $sym;
    }
  }

  return @symbols;
}

sub _get_syms {
  my $self = shift;
  my $syms = $self->{_syms} ||= do {
    # recurse option?
    [ $self->_symbols_for($self->{package}) ];
  };
  return @$syms;
}

sub _get_pods {
  my $self = shift;

  $self->{_pods} ||= do {
    my $parsed = $self->_parsed;

    my %covered = map +( $_ => 1 ), map @{ $_->covered }, values %$parsed;

    [ sort keys %covered ];
  };
}

sub _trusted_from_pod {
  my $self = shift;

  $self->{_trusted_from_pod} ||= do {
    my $parsed = $self->_parsed;

    [ map @{ $_->trusted }, values %$parsed ];
  };
}

sub _trustme_check {
  my $self = shift;
  my ($sym) = @_;
 
  $self->SUPER::_trustme_check(@_) and return 1;

  return scalar grep $sym =~ /$_/, @{ $self->_trusted_from_pod };
}

1;
__END__

=head1 NAME

Pod::Coverage::TrustMe - Pod::Coverage but more powerful

=head1 SYNOPSIS

  use Pod::Coverage::TrustMe;

=head1 DESCRIPTION

Checks Pod coverage like L<Pod::Coverage>, but with several extra features. Also
uses different Pod parser based on L<Pod::Simple>.

=head1 OPTIONS

=over 4

=item trust_parents

Includes Pod from parent classes in list of covered subs. Like
L<Pod::Coverage::CountParents>. Defaults to true.

=item trust_roles

Includes Pod from consumed roles in list of covered subs. Like
L<Pod::Coverage::CountParents>, but checking C<does> or C<DOES>. Defaults to true.

=item trust_pod

Trusts subs listed in C<Pod::Coverage> blocks in Pod. Like
L<Pod::Coverage::TrustPod>. Defaults to true.

=item require_link

Requires a link in the Pod to parent classes or roles to include them in the
coverage.

=item export_only

Only requires subs listed in C<@EXPORT> and C<@EXPORT_OK> be covered.

=item trust_imported

Trusts subs that were imported from other packages. If set to false, every sub
in the package needs to be covered, even if it is imported from another package.
Subs that aren't part of the API should be cleaned using a tool like
L<namespace::clean>. See also L<Test::CleanNamespaces>. Defaults to true.

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2020 the Pod::Coverage::TrustMe L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
