package W;

sub new {
  my $self = shift;
  $class = (ref $self or $self);
  my $range = defined $_[0] ? shift : '1..1';
  print "$range\n";
  bless { 'range' => $range }, $class;
}

sub result {			# ad hoc method
  my $self = shift; 
  my $cmd = shift;
  my @result;
  my $result;
  if ($cmd) {
#    print "$^X $cmd\n";
#    print STDERR "Execution of $^X $cmd 2>&1\n";
    die qq^unable to find "$cmd"^ unless (-f $cmd);
    open(CMD, "$^X $cmd 2>&1 |" ) 
      or warn "$0: Can't run. $!\n";
    @result = <CMD>;
    close CMD;
    $self->{result} = join('', @result);
#    print $self->{result};
  } else {
    $self->{result};
  }
}
sub expected {			# ad hoc method
  my $self = shift;
  my $FH = shift;
  if ($FH) {
    $self->{'expected'} = join('', <$FH>);
#    print $self->{'expected'};
  } else {
    $self->{'expected'};
  }
}
sub assert {
  my $self = shift;
  my $regexp = shift;
  if ($self->{'expected'} !~ /$regexp/) {
    die "$regexp doesn't match expected string";
  }
}
sub report {			# borrowed to the DProf.pm package
  my $self = shift;
  my $num = shift;
  my $sub = shift;
  my $x;

  $x = &$sub;
  $x ? "ok $num\n" : "not ok $num\n";
}
sub debug {}
1;
