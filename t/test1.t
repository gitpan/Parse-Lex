#!/usr/local/bin/perl

BEGIN {  push(@INC, './t') }
use W;

$test = W->new('1..1');
$test->result("examples/tokenizer.pl");
$test->expected(\*DATA);
print $test->report(1, sub { 
		      $test->expected eq $test->result 
		    });

__END__
Trace ON in class Lex
Tokenization of DATA:
Token read(main::INTEGER, "[1-9][0-9]*") 1
Line 1	Type: main::INTEGER	Content:->1<-
Token read(main::ADDOP, "[-+]") +
Line 1	Type: main::ADDOP	Content:->+<-
Token read(main::INTEGER, "[1-9][0-9]*") 2
Line 1	Type: main::INTEGER	Content:->2<-
Token read(main::ADDOP, "[-+]") -
Line 1	Type: main::ADDOP	Content:->-<-
Token read(main::INTEGER, "[1-9][0-9]*") 5
Line 1	Type: main::INTEGER	Content:->5<-
Token read(main::NEWLINE, "
") 

Line 1	Type: main::NEWLINE	Content:->
<-
Token read(main::STRING, "") "multiline
string with an embedded \" in it"
Line 3	Type: main::STRING	Content:->"multiline
string with an embedded \" in it"<-
Token read(main::NEWLINE, "
") 

Line 3	Type: main::NEWLINE	Content:->
<-
Token read(main::ERROR, ".*") embedded \" string"
can't analyze: "embedded \" string"" at examples/tokenizer.pl line 17, <DATA> chunk 4.
