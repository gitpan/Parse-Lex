# © Philippe Verdret, 1995-1997

require 5.003;
use strict qw(vars);
use strict qw(refs);
use strict qw(subs);

package Parse::Token;
use Carp;
if ((caller(0))[0] ne 'Parse::Lex') {
  carp "The Parse::Token must be called only via the Parse::Lex module";
}

my $trace = 0;
my $idx = 0;
my $status_idx = $idx++;
my $string_idx = $idx++;
my $name_idx = $idx++;
my $regexp_idx = $idx++;
my $sub_idx = $idx++;
my $reader_idx = $idx++;
my $trace_idx = $idx++;		
$Token::EOI = Parse::Token->new('EOI');

#  new()
# Purpose: token constructor
# Arguments:
# Returns: Return a token object

sub new {
  bless [
	 0,			# object status
	 '',			# recognized string 
	 $_[1],			# symbolic name
	 $_[2],			# regexp
	 $_[3],			# associated sub
 	 $_[4],			# reader object
	 $trace,
	];
}

# status()
# Purpose: Indicate is the last token search has succeeded or not
# Arguments:
# Returns:

sub status { 
  defined($_[1]) ? 
    $_[0]->[$status_idx] = $_[1] : 
      $_[0]->[$status_idx];
} 
# setstring()
# Purpose: Return the symbolic name of the object
# Arguments:
# Returns: see purpose
# Extension: save $1, $2... in a list

sub setstring    { $_[0]->[$string_idx] = $_[1] } # set token string

# getstring()
# Purpose:
# Arguments:
# Returns:

sub getstring    { $_[0]->[$string_idx] }	# get token string 

#  name()
# Purpose:
# Arguments:
# Returns:

sub name { $_[0]->[$name_idx] }	# name of the token
*type = \&name;			# synonym of the name method

#  
# Purpose:
# Arguments:
# Returns:

sub regexp { $_[0]->[$regexp_idx] }	# regexp

#  mean()
# Purpose:
# Arguments:
# Returns:

sub mean   { $_[0]->[$sub_idx] }	# anonymous fonction

# reader(EXP)
# reader
# Purpose: Defines or returns the associated lexer
# Arguments:
# Returns:
sub reader {		
  if (defined $_[1]) {
    if (ref($_[1]) eq 'Parse::Lex') {
      $_[0]->[$reader_idx] = $_[1];
    } else {
      my $mesg = "$_[1] must be Parse::Lex object";
      croak $mesg;
    }
  } else {
    $_[0]->[$reader_idx];
  }
}	
sub do     { &{$_[1]}($_[0]) }	# why not? 

# next()
# Purpose: Return the string token if token is the pending one
# Arguments: no argument
# Returns: a token string if token is found, else undef

sub next {			# return the token string content
  my $self = shift;
  my $reader = $self->[$reader_idx];
  my $pendingToken = $reader->[$Lex::pendToken_idx];
  if ($pendingToken == $Token::EOI) {
    if ($trace) {
      print STDERR "Try to find: ", $self->[$name_idx], "\n";
      print STDERR "End of input at line $.\n";
    }
    if ($self == $Token::EOI) {
      $self->[$status_idx] = 1;
    } else {
      $self->[$status_idx] = 0;
    }
    return undef;		
  }
  if ($trace) {
    print STDERR "Try to find: ", $self->[$name_idx], "";
    if ($pendingToken) {
      print STDERR " (pending token: ", $pendingToken->name, ")\n";
    } else {
      print STDERR "\n";
    }
  }
  $reader->next() unless $pendingToken;
  if ($self == $reader->[$Lex::pendToken_idx]) {
    if ($trace) {
      print STDERR "Token found: ", $self->[$name_idx], " ", 
      $self->[$string_idx], "\n";
    }
    $reader->[$Lex::pendToken_idx] = 0; # now no pending token
    my $content = $self->getstring();		
    $self->setstring();
    $self->[$status_idx] = 1;
    $content;			# return token string
  } else {
    $self->[$status_idx] = 0;
    undef;
  }
}
# met()
# Purpose: What is the status of the token object, and what is the
#  recognized string
# Arguments: scalar reference
# Returns: 
#  1. the object status
#  2. the recognized string is put in the scalar reference

sub met {			# return the token string content
  my $self = shift;
  my $reader = $self->[$reader_idx];
  my $pendingToken = $reader->[$Lex::pendToken_idx];
  if ($pendingToken == $Token::EOI) {
    if ($trace) {
      print STDERR "Try to find: ", $self->[$name_idx], "\n";
      print STDERR "End of input at line $.\n";
    }
    ${$_[0]} = undef;
    if ($self == $Token::EOI) {
      return $self->[$status_idx] = 1;
    } else {
      return $self->[$status_idx] = 0;
    }
  }
  if ($trace) {
    print STDERR "Try to find: ", $self->[$name_idx], "";
    if ($pendingToken) {
      print STDERR " (pending token: ", $pendingToken->name, ")\n";
    } else {
      print STDERR "\n";
    }
  }
  $reader->next() unless $pendingToken;
  if ($self == $reader->[$Lex::pendToken_idx]) {
    if ($trace) {
      print STDERR "Token found: ", $self->[$name_idx], " ", 
      $self->[$string_idx], "\n";
    }
    $reader->[$Lex::pendToken_idx] = 0; # now no pending token
    my $content = $self->getstring();		
    $self->setstring();
    $self->[$status_idx] = 1;
    ${$_[0]} = $content;
    1;
  } else {
    $self->[$status_idx] = 0;
    ${$_[0]} = undef;
    0;
  }
}

# trace()
# Purpose: Activate/disactivate a trace showing which tokens are searched 
#  and have been found.
# Arguments: 
# Returns:

sub trace { 
  my $self = shift;
  my $pkg = ref($self);
  if ($pkg) {		
    if ($self->[$trace_idx]) {
      $self->[$trace_idx] = 0;
    } else {
      $self->[$trace_idx] = 1;
    }
  } 
  $trace = not $trace;
  print STDERR $trace ? "Trace ON" : "Trace OFF", "\n";
}

1;

__END__
