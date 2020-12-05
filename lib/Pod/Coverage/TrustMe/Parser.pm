package Pod::Coverage::TrustMe::Parser;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use Pod::Simple ();
our @ISA = qw(Pod::Simple);
use Carp qw(croak);
use constant DEBUG => 0;

DEBUG and require Data::Dumper;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->accept_targets_as_text('Pod::Coverage');
  $self->{+__PACKAGE__} = {};
  return $self;
}

sub parse_lines {
  my $self = shift;
  $self->SUPER::parse_lines(@_);
  my $me = $self->{+__PACKAGE__};
  {
    # these are regexes
    my $trusted = $me->{trusted} ||= [];
    my %seen;
    @$trusted = sort grep !$seen{$_}++, @$trusted;
  }
  {
    my $links = $me->{links} ||= [];
    my %seen;
    @$links = sort grep !$seen{$_}++, @$links;
  }
  {
    my $covered = $me->{covered} ||= [];
    my %seen;
    @$covered = sort grep !$seen{$_}++, @$covered;
  }
  return;
}

sub ignore_empty {
  my $self = shift;
  my $me = $self->{+__PACKAGE__};
  if (@_) {
    $me->{ignore_empty} = shift;
  }
  return $me->{ignore_empty};
}

sub _handle_element_start {
  my $self = shift;
  my $me = $self->{+__PACKAGE__};
  my ($name, $attr) = @_;
  warn "START $name\n" if DEBUG;
  local $Data::Dumper::Terse = 1, warn Data::Dumper::Dumper($attr) if DEBUG;
  if ($name eq 'for') {
    push @{ $me->{in} }, $attr;
  }
  elsif ($name eq 'L' && $attr->{type} eq 'pod' && defined $attr->{to}) {
    push @{ $me->{links} }, "$attr->{to}";
  }
  elsif ($name eq 'item' || $name =~ /\Ahead[2-9]\z/) {
    delete $me->{maybe_covered};
    $me->{consider} = $name;
    $me->{consider_text} = '';
  }
  elsif ($name =~ /\Ahead1\z/) {
    delete $me->{maybe_covered};
  }
  $self->SUPER::_handle_element_start(@_);
}
sub _handle_element_end {
  my $self = shift;
  my $me = $self->{+__PACKAGE__};
  my ($name) = @_;
  warn "END $name\n" if DEBUG;
  if ($name eq 'for') {
    pop @{ $self->{+__PACKAGE__}{in} };
  }
  elsif ($name eq ($me->{consider}||'')) {
    delete $me->{consider};
    my $text = delete $me->{consider_text};
    my @covered = $text =~ /([^\s\|,\/]+)/g;
    for my $covered ( @covered ) {
      # looks like a method
      $covered =~ s/.*->//;
      # looks fully qualified
      $covered =~ s/\A\w+(?:::\w+)*::(\w+)/$1/;
      # looks like it includes parameters
      $covered =~ s/(\w+)[;\(].*/$1/;
    }
    @covered = grep /\A\w+\z/, @covered;
    if ($self->ignore_empty) {
      push @{ $me->{maybe_covered} }, @covered;
    }
    else {
      push @{ $me->{covered} }, @covered;
    }
  }
  $self->SUPER::_handle_element_end(@_);
}

sub _handle_text {
  my $self = shift;
  my $me = $self->{+__PACKAGE__};
  my ($text) = @_;
  warn "TEXT '$text'\n" if DEBUG;
  my $in = $me->{in};
  if ($in && @$in && $in->[-1]{target} eq 'Pod::Coverage') {
    my @trusted;
    for my $token ($text =~ /(\S+)/) {
      if ($token eq '*EVERYTHING*') {
        push @trusted, qr{.?};
      }
      else {
        my $re = eval { qr/\A(?:$token)\z/ };
        if (!$re) {
          my $file = $self->{source_filename} || '<input>';
          my $line = $in->[-1]{start_line} || '<unknown>';
          croak "Error compiling Pod::Coverage regex /$token/ at $file line $line: $@";
        }
        push @trusted, $re;
      }
    }

    push @{ $me->{trusted} }, @trusted;
  }
  elsif ($me->{consider}) {
    $me->{consider_text} .= $text;
  }
  elsif ($me->{maybe_covered}) {
    push @{ $me->{covered} }, @{ delete $me->{maybe_covered} };
  }
  $self->SUPER::_handle_text(@_);
}

sub links {
  my $self = shift;
  return $self->{+__PACKAGE__}{links};
}

sub trusted {
  my $self = shift;
  return $self->{+__PACKAGE__}{trusted};
}

sub covered {
  my $self = shift;
  return $self->{+__PACKAGE__}{covered};
}

1;
__END__
