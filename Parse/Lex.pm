# © Philippe Verdret, 1995-1997

require 5.003;
use strict qw(vars);
use strict qw(refs);
use strict qw(subs);

package Parse::Lex;
$Lex::VERSION = '1.12';
use Parse::Token;
use Carp;
use Parse::Preprocess;
				# Default values
my $FH = \*STDIN;		# Input Filehandle 
my $eoi = 0;			# 1 if end of imput 
my $defaultToken = Parse::Token->new('default token', '.*'); # default token
my $pendingToken = 0;		# if 1 there is a pending token
				# You can access to these variables from outside!

my $skip = '[ \t]+';		# strings to skip
my $hold = 0;			# if true enable data saving
my $trace = 0;			# control trace mode

my $lexer = bless [];		# Prototype object
my $idx = 0;
$lexer->[my $fh_idx = $idx++] = $FH;
$lexer->[my $string_idx = $idx++] = 0; # data come from string
my $sub_idx = $idx++;
$lexer->[$sub_idx] = sub {
  $_[0]->[$fh_idx] = $FH;	# read on default Filehandle
  $_[0]->genlex;		# autogeneration
  &{$_[0]->[$sub_idx]};		# execution
};
$lexer->[my $buffer_idx = $idx++] = ''; # string to tokenize
$lexer->[my $pendingToken_idx = $idx++] = $defaultToken;
$lexer->[my $eoi_idx = $idx++] = $eoi;
$lexer->[my $skip_idx = $idx++] = $skip;
$lexer->[my $hold_idx = $idx++] = $hold; # save or not what is consumed
$lexer->[my $holdContent_idx = $idx++] = ''; # saved string
$lexer->[my $complex_idx = $idx++] = 0; # if three part regexp
$lexer->[my $codeHEAD_idx = $idx++] = ''; # lexer code
$lexer->[my $codeBODY_idx = $idx++] = ''; # lexer code
$lexer->[my $codeFOOT_idx = $idx++] = ''; # lexer code
$lexer->[my $trace_idx = $idx++] = $Lex::trace;
$lexer->[my $init_idx = $idx++] = 1; # for the first generation
$lexer->[my $tokenList_idx = $idx++] = undef;
$Lex::pendToken_idx = $pendingToken_idx;

sub next { &{$_[0]->[$sub_idx]} }
sub eoi { 
  my $self = shift;
  $self->[$eoi_idx];
} 
sub token {			# always return a Token object
  my $self = shift;
  $self->[$pendingToken_idx] or
    $defaultToken 
} 
sub tokenis {			# force the token
  my $self = shift;
  $self->[$pendingToken_idx] = $_[0];
}
sub set {			# set the token content
  my $self = shift;
  $self->[$buffer_idx] = $_[0];
} 
sub get {			# get the token content
  my $self = shift;
  $self->[$buffer_idx]; 
} 
sub buffer { 
  my $self = shift;
  if (defined $_[0]) {
    $self->[$buffer_idx] = $_[0] 
  } else {
    $self->[$buffer_idx];
  }
} 
sub flush {
  my $self = shift;
  my $tmp = $self->[$holdContent_idx];
  $self->[$holdContent_idx] = '';
  $tmp;
}
sub less { 
  my $self = shift;
  if (defined $_[0]) {
    $self->[$buffer_idx] = $_[0] . 
      $self->[$buffer_idx];
  }
}

# Purpose: execute some action on each token
# Arguments: an anonymous sub to call on each token
# Returns: undef

sub every {			
  my $self = shift;
  my $ref = ref($_[0]);
  if (not $ref or $ref ne 'CODE') { 
    croak "every must have an anonymous routine as argument";
  }
  my $token = &{$self->[$sub_idx]}($self);
  while (not $self->[$eoi_idx]) {
    &{$_[0]}($token);
    $token = &{$self->[$sub_idx]}($self);
  }
  undef;
}
sub reset { 
  my $self = shift;
  $self->[$eoi_idx] = 0; 
  $self->[$buffer_idx] = ''; 
  if ($self->[$pendingToken_idx]) { 
    $self->[$pendingToken_idx]->setstring();
    $self->[$pendingToken_idx] = 0;
  }
}
sub tokenlist {
  my $self = shift;
  @{$self}[$tokenList_idx..$#{$self}]; 
}
# where data come from
sub from {
  my $self = shift;
  if (ref($_[0]) eq 'GLOB'	# Read data from a filehandle
      and defined fileno($_[0])) {	
    if ($self->[$fh_idx] ne $_[0]) { # FH not defined or has changed
      $self->[$fh_idx] = $_[0];
      $self->genbody($self->tokenlist) if $self->[$complex_idx];
      $self->genlex();
    }
    $self->reset;
  } elsif (defined $_[0]) {		# Data from a variable or a list
    unless ($self->[$string_idx]) {
      $self->genbody($self->tokenlist) if $self->[$complex_idx];
      $self->genlex();
      $self->[$string_idx] = 1;
    }
    $self->reset;
    $self->[$buffer_idx] = join($", @_); # Data from a list
  } elsif ($self->[$fh_idx]) {
    $self->[$fh_idx];
  } else {
    undef;
  }
}

#Structure of the next routine:
#  $header_ST | $header_FH
#  (($rowHeader_SIMPLE|$rowHeader_COMPLEX_FH|$rowHeader_COMPLEX_ST)
#   ($rowFooter|$rowFooterSub))+
#  $footer

my $header_ST = q!
  {		
   my $buffer = $_[0]->[<<$_buffer_idx>>];
   if ($buffer ne '') {
     $buffer =~ s/^(<<$_skip_>>)//;
     <<$Lex::holdSkip>>
   }
   if ($buffer eq '') {
     $_[0]->[<<$_eoi_idx>>] = 1;
     $_[0]->[<<$_pendingToken_idx>>] = $Token::EOI;
     return $Token::EOI;
   }
   my $content = '';
   my $token = undef;
 CASE:{
!;

my $header_FH = q!
  {
   my $buffer = $_[0]->[<<$_buffer_idx>>];
   if ($buffer ne '') {
     $buffer =~ s/^(<<$_skip_>>)//;
     <<$Lex::holdSkip>>
   }
   if ($buffer eq '') {
     if ($_[0]->[<<$_eoi_idx>>]) # if EOI
       { 
         $_[0]->[<<$_pendingToken_idx>>] = $Token::EOI;
         return $Token::EOI;
       } 
     else 
       {
        my $fh = $_[0]->[<<$_fh_idx>>];
        do {
           $buffer = <$fh>; 
           if (defined($buffer)) {
             $buffer =~ s/^(<<$_skip_>>)//;
             <<$Lex::holdSkip>>
           } else {
             $_[0]->[<<$_eoi_idx>>] = 1;
             $_[0]->[<<$_pendingToken_idx>>] = $Token::EOI;
             return $Token::EOI;
           }
         } while ($buffer eq '');
       }
   }
   my $content = '';
   my $token = undef;
 CASE:{
!;
my $rowHeader_SIMPLE = q!  
   $buffer =~ s/^(<<$Lex::begin>>)// and do {!;
#not used
my $rowHeader_SIMPLE_TRACE = q!
   if ($_[0]->[<<$Lex::_trace_idx>>]) {
     print STDERR "Token read(", $<<$Lex::id>>->name, ", \"<<$Lex::begin>>\E\") $1\n"; 
   }!;
my $rowHeader_COMPLEX_ST = q!
   $buffer =~ s/^(<<$Lex::begin>><<$Lex::between>><<$Lex::end>>)// and do {!;
my $rowHeader_COMPLEX_FH = q!
    $buffer =~ s/^(<<$Lex::begin>>)// and do {
    my $string = $buffer;
    $buffer = "$1$buffer";
    do {
      my $fh = $_[0]->[<<$_fh_idx>>];
      while (not $string =~ /<<$Lex::end>>/) {
        $string = <$fh>;
        if (not defined($string)) {
           $_[0]->[<<$_eoi_idx>>] = 1;
           $_[0]->[<<$_pendingToken_idx>>] = $Token::EOI;
           return $Token::EOI;
        }
        $buffer .= $string;
      }
      $string = '';
    } until ($buffer =~ s/^(<<$Lex::begin>><<$Lex::between>><<$Lex::end>>)//);
!;
my $rowHeader_COMPLEX_TRACE = q!
  if ($_[0]->[<<$Lex::_trace_idx>>]) { # Trace
    print STDERR "Token read(", 
    $<<$Lex::id>>->name, ", <<$Lex::begin>><<$Lex::between>><<$Lex::end>>\E) $1\n"; 
  }!;
my $rowFooterSub = q!
    $_[0]->[<<$_buffer_idx>>] = $buffer;
    $content = $1;
    $<<$Lex::id>>->setstring($content);
    $_[0]->[<<$_pendingToken_idx>>] = $token = $<<$Lex::id>>;
    $content = &{$<<$Lex::id>>->mean}($token, $content);
    $<<$Lex::id>>->setstring($content);
    $token = $_[0]->[<<$_pendingToken_idx>>]; # if tokenis in sub
    last CASE;
  };
!;
my $rowFooter = q!
    $_[0]->[<<$_buffer_idx>>] = $buffer;
    $content = $1;
    $<<$Lex::id>>->setstring($content);
    $_[0]->[<<$_pendingToken_idx>>] = $token = $<<$Lex::id>>;
    last CASE;
   };
!;
my $footer = q!
  }#CASE
  <<$Lex::holdToken>>
  return $token;
}!;
$Lex::holdToken = qq!\$_[0]->[$holdContent_idx] .= \$content; # hold consumed strings!;
$Lex::holdSkip = qq!\$_[0]->[$holdContent_idx] .= \$1; # hold consumed strings!;

# Purpose: Toggle the trace mode
# todo: regenerate the analyser's body

sub trace { 
  my $self = shift;
  if (ref($self)) {			# for an object
    if ($self->[$trace_idx]) {
      $self->[$trace_idx] = 0;
      print STDERR "trace OFF\n";
    } else {
      $self->[$trace_idx] = 1;
      print STDERR "trace ON\n";
    }
  } else {			# for the class attribute
				# or perhaps change the default object
    $trace = not $trace;
    print STDERR $trace ? 
      "Trace ON in class Lex" : "Trace OFF in class Lex", "\n";
  }
}

# hold(EXPR)
# hold
# Purpose: hold or not consumed string, else return the current value
# Arguments: nothing or EXPR true/false
# Returns: the current value of the hold attribute

sub hold {			
  my $self = shift;
  if (ref $self) {
      $self->[$hold_idx] = not $self->[$hold_idx];
      $self->genbody($self->tokenlist);
      $self->genlex();
  } else {			# for the class attribute
				# or perhaps change the default object
    $hold = not $hold;
  }
}

# skip(EXPR)
# skip
# Purpose: return or set the value of the regexp used for consuming
#  inter-token strings. 
# Arguments: with EXPR changed the regexp and regenerate the
#  lexical analyzer 
# Returns: see Purpose

sub skip {			
  my $self = shift;
  if (ref $self) {
    if (defined($_[0])) {
      if ($_[0] ne $self->[$skip_idx]) {
	$self->[$skip_idx] = $_[0];
	$self->genlex();
      }
    } else {
      $self->[$skip_idx];
    }
  } else {			# for the class attribute
				# or perhaps change the default object
    defined $_[0] ? $skip = $_[0] : $skip;
  }
}


# Purpose: create the lexical analyzer, with the associated tokens
# Arguments: list of token specifications
# Returns: a lex object

sub new {
  my $self = shift;
  my $class = (ref $self or $self);
  if (not defined($_[0])) {
    croak "arguments of the new method must be a list of token specifications";
  }
  local $Lex::pkg = (caller(0))[0]; # From which package?

  $lexer->reset;
  my $self = bless[@{$lexer}], $class; # the default 

  $self->[$init_idx] = 1;
  $self->[$hold_idx] = $hold;	# perhaps put these info directly in the default object
  $self->[$trace_idx] = $trace; 
  $self->[$skip_idx] = $skip; 

  my @token = $self->newset(@_);
  splice(@{$self}, $tokenList_idx, 1, @token);	

  $self->genbody(@token);
}

# Purpose: create the lexical analyzer
# Arguments: list of tokens
# Returns: a Lex object

sub genbody {
  my $self = shift;
  my $sub;
  $self->[$complex_idx] = 0;
  local $Lex::id;	
  local $Lex::_trace_idx = $trace_idx;
  if ($self->[$init_idx]) {	# object creation
    $self->[$trace_idx] = $trace; # class current value
    $self->[$init_idx] = 0;
  }
  local $Lex::_pendingToken_idx = $pendingToken_idx;
  local $Lex::_buffer_idx = $buffer_idx;
  local $Lex::_eoi_idx = $eoi_idx;
  local $Lex::_fh_ = $self->[$fh_idx]; 
  local $Lex::_fh_idx = $fh_idx;
  local $Lex::holdToken = '' unless $self->[$hold_idx];
  local($Lex::regexp, $Lex::begin, $Lex::between, $Lex::end);
  no strict 'refs';		# => ${$Lex::id}
  my $token;
  my $body = '';
  while (@_) {
    $token = shift;
    $Lex::regexp = $token->regexp;
    $Lex::id = $token->name;

    if (ref($Lex::regexp) eq 'ARRAY') {
      $self->[$complex_idx] = 1;
      $Lex::begin = ppregexp(${$Lex::regexp}[0]);
      $Lex::between = ${$Lex::regexp}[1] ? 
	ppregexp(${$Lex::regexp}[1]) : '(?:.*?)';
      $Lex::end = ppregexp(${$Lex::regexp}[2] or ${$Lex::regexp}[0]);

      if ($Lex::_fh_) {
	$body .= ppcode($rowHeader_COMPLEX_FH, 'Lex');
      } else {
	$body .= ppcode($rowHeader_COMPLEX_ST, 'Lex');
      }
      $Lex::between = '';

      if ($self->[$trace_idx]) {
	$body .= ppcode($rowHeader_COMPLEX_TRACE, 'Lex');
      } 
    } else {
      $Lex::begin = ppregexp($Lex::regexp);
      $body .= ppcode($rowHeader_SIMPLE, 'Lex');
      if ($self->[$trace_idx]) {
	$body .= ppcode($rowHeader_SIMPLE_TRACE, 'Lex');
      } 
    }

    $sub = $token->mean;
    if ($sub) {			# Token with an associated sub
      $body .= ppcode($rowFooterSub, 'Lex');
      $sub = undef;		# 
    } else {
      $body .= ppcode($rowFooter, 'Lex');
    }
  }

  $self->[$codeBODY_idx] = $body;
  $self;
}

# Purpose: Generate the lexical analyzer
# Arguments: 
# Returns: 

sub genlex {
  my $self = shift;
				# save all what is consumed or not 
  local $Lex::holdToken = '' unless $self->[$hold_idx];
  local $Lex::holdSkip = ''  unless $self->[$hold_idx];
  local $Lex::_skip_ = $self->[$skip_idx];
  local $Lex::_fh_ = $self->[$fh_idx]; 
  local $Lex::_fh_idx = $fh_idx;
  local $Lex::_buffer_idx = $buffer_idx;
  local $Lex::_eoi_idx = $eoi_idx;
  local $Lex::_pendingToken_idx = $pendingToken_idx;
  my $head;			# sub genhead
  if ($Lex::_fh_) {
    $head = $self->[$codeHEAD_idx] = ppcode($header_FH, 'Lex');
  } else {
    $head = $self->[$codeHEAD_idx] = ppcode($header_ST, 'Lex');
  }
				# sub genfoot
  my $foot = $self->[$codeFOOT_idx] = ppcode($footer, 'Lex');

  my $analyser = $head . $self->[$codeBODY_idx] . $foot;
  eval qq!\$self->[$sub_idx] = sub $analyser!; # Create the lexer

  if ($@) {	# can be usefull ;-)
    my $line = 0;
    $analyser =~ s/^/sprintf("%3d", $line++)/meg if $@;	# line numbers
    print STDERR "$analyser\n";
    print STDERR "$@\n";
    die "\n";
  }
}

# Purpose: Returns code of the lexical analyzer
# Arguments: nothing
# Returns: code of the lexical analyzer
# Remarks: not documented

sub getcode {
  my $self = shift;
  $self->[$codeHEAD_idx] . $self->[$codeBODY_idx]. $self->[$codeFOOT_idx];
}

# Purpose: returns the lexical analyzer like an anonymous sub
# Arguments: nothing
# Returns: an anonymous sub implementing the lexical analyzer
# Remarks: not documented

sub getsub {
  my $self = shift;
  my $sub = "$self->[$codeHEAD_idx] $self->[$codeBODY_idx] $self->[$codeFOOT_idx]";
  eval "sub $sub";
}

# Purpose: Generate a set of tokens and define these tokens
#          in the package of the caller
# Arguments: list of token specification
# Returns: list of token objects
# Remarks: define a new class (container)

sub newset {		
  my $self = shift;
  local $Lex::pkg = $Lex::pkg;
  if (not defined $Lex::pkg) {
    $Lex::pkg = (caller(0))[0];
  }
  if (not defined($_[0])) {
    croak "arguments of the newset method must be a list of token specifications";
  }
  my $sub;
  my $ref;
  my $tokenid;
  my $regexp;
  my $tmp;
  my @token;
  no strict 'refs';		# => ${$tokenid}
  while (@_) {
    ($tokenid, $regexp) = (shift, shift);
    $tokenid = "$Lex::pkg" . "::" . "$tokenid";
    if (@_) {
      $ref = ref($_[0]);
      if ($ref and $ref eq 'CODE') { # if next arg is a sub reference
	$sub = shift;
      } else {
	$sub = undef;
      }
    }
    # Creation of a new Token object
    ${$tokenid} = $tmp = Parse::Token->new($tokenid, $regexp, $sub, $self);
    push(@token, $tmp);				    
  }
  @token;
}
sub readline {
  my $fh = $_[0]->[$fh_idx];
  $_ = <$fh>;
  if (not defined($_)) {
    $_[0]->[$eoi_idx] = 1;
  } else {
    $_;
  }
}
1;
__END__
