# © Philippe Verdret, 1995-1997

require 5.003;
use strict qw(@ISA @EXPORTER);

package Parse::Preprocess;
use Carp;
require Exporter;
@ISA = (Exporter);
@EXPORT = qw(ppcode ppregexp);

# Some utilities
# parts to substitute are inclosed between << >>
sub ppcode {
  my $code = shift;
  my $pkg = shift;
#  no strict;
  if ($pkg) {			# access to the right struc in the right package
    $code =~ s/<<([^<>]+)>>/"{ package $pkg; $1 }"/eeg;
  } else {
    $code =~ s/<<([^<>]+)>>/"$1"/eeg;
  }
  if ($code =~ /(<<[^<>]+>>)/) {
      croak "$1 found in: $code\n";
  }
#  use strict;
  $code;
}
sub ppregexp { # pre-process regexp: ! or / (delimiters) -> \! \/
  $_[0] =~ s{
    ((?:[^\\]|^)(?:\\{2,2})*)	# Context before
    ([/!\"])			# Delimiters which are used
  }{$1\\$2}xg;
  $_[0];
}
1;
__END__
