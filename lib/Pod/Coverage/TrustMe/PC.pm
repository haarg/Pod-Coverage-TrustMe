package Pod::Coverage::TrustMe::PC;
use strict;
use warnings;

our $VERSION = '0.00100';
$VERSION =~ tr/_//d;

use Pod::Coverage::TrustMe;
our @ISA = qw(Pod::Coverage::TrustMe);

sub new {
  my $class = shift;
  my %args = (
    trust_roles     => 0,
    trust_parents   => 0,
    trust_pod       => 0,
    @_,
  );
  return $class->SUPER::new(%args);
}

sub _get_syms {
  my $self = shift;
  my $package = shift;
  my $file = Pod::Coverage::TrustMe::__pack_to_pm($package);
  require $file;
  $self->SUPER::_get_syms($package);
}

# nobody uses this, so maybe it can be left out?
sub _CvGV {
  my $self = shift;
  my $sub  = shift;
  require B;
  my $cv = B::svref_2object($sub);
  my $gv = $cv->GV;
  return $gv->object_2svref
    if $gv->can('object_2svref');

  no strict 'refs';
  return *{ $gv->STASH->NAME . '::' . $gv->NAME };
}

sub import {
  my $class = shift;
  return
    unless @_;

  my @args = @_ == 1 ? (package => $_[0]) : @_;
  my $pc = $class->new(@args);
  $pc->print_report;
}

package Pod::Coverage::TrustMe::PC::CountParents;
our @ISA = qw(Pod::Coverage::TrustMe::PC);

sub new {
  my $class = shift;
  my %args = (
    trust_parents => 1,
    @_,
  );
  return $class->SUPER::new(%args);
}

package Pod::Coverage::TrustMe::PC::ExportOnly;
our @ISA = qw(Pod::Coverage::TrustMe::PC);

sub new {
  my $class = shift;
  my %args = (
    export_only => 1,
    @_,
  );
  return $class->SUPER::new(%args);
}

package Pod::Coverage::TrustMe::PC::TrustPod;
our @ISA = qw(Pod::Coverage::TrustMe::PC::CountParents);

sub new {
  my $class = shift;
  my %args = (
    trust_pod => 1,
    @_,
  );
  return $class->SUPER::new(%args);
}

package Pod::Coverage::TrustMe::PC::MethodSignatures;
our @ISA = qw(Pod::Coverage::TrustMe::PC);

sub new {
  my $class = shift;
  my %args = @_;
  my @also_private = @{ delete $args{also_private} || [] };
  push @also_private, qw(func method);
  $args{also_private} = \@also_private;

  return $class->SUPER::new(%args);
}

package Pod::Coverage::TrustMe::PC::Moose;
our @ISA = qw(Pod::Coverage::TrustMe::PC);

sub new {
  my $class = shift;
  my %args = @_;
  my $self = $class->SUPER::new(@_);
  $self->{cover_requires} = $args{cover_requires} || 0;
  return $self;
}

sub cover_requires {
  my $self = shift;
  return $self->{cover_requires};
}

sub _trust_method_check {
  my $self = shift;
  my ($sym) = @_;

  my $meta = exists $self->{meta} ? $self->{meta} : $self->{meta} = (
    defined &Class::MOP::class_of ? Class::MOP::class_of($self->package) : undef
  );

  if ($meta and my $method_meta = $meta->find_method_by_name($sym)) {
    if ($method_meta->isa('Moose::Meta::Method::Meta')) {
      return 1;
    }
    if ($method_meta->isa('MooseX::AttributeHelpers::Meta::Method::Provided')) {
      return 1;
    }
    if ($method_meta->can('definition_context')) {
      return 1
        if $method_meta->definition_context->{type} eq 'role';
    }
  }

  if ($self->cover_requires && $meta->isa('Moose::Meta::Role')) {
    return 1
      if $meta->requires_method($sym);
  }

  return $self->SUPER::_trust_method_check(@_);
}

1;
__END__
