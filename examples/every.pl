#!/usr/local/bin/perl
require 5.000;

use Parse::Lex;

$lexer = Parse::Lex->new(qw(
			    ADDOP [-+]
			    INTEGER \d+
			    NEWLINE \n
			   ));

$lexer->from(\*DATA);

$lexer->every (sub { 
		 print $_[0]->name, "\t";
		 print $_[0]->getstring, "\n";
	       });

__END__
1+2+3+4+5+6+6+7+7+7-76
0+0+0+0+0+0+0+0+0+0+0+
1+2+3+4+5+6+6+7+7+7-76
