#!/usr/local/bin/perl

BEGIN {  push(@INC, './t') }
use W;

$test = W->new('1..1');
$test->result("examples/every.pl");
$test->expected(\*DATA);
$test->assert('\n\n$');
print $test->report(1, sub { 
		      $test->expected eq $test->result 
		    });

__END__
main::INTEGER	1
main::ADDOP	+
main::INTEGER	2
main::ADDOP	+
main::INTEGER	3
main::ADDOP	+
main::INTEGER	4
main::ADDOP	+
main::INTEGER	5
main::ADDOP	+
main::INTEGER	6
main::ADDOP	+
main::INTEGER	6
main::ADDOP	+
main::INTEGER	7
main::ADDOP	+
main::INTEGER	7
main::ADDOP	+
main::INTEGER	7
main::ADDOP	-
main::INTEGER	76
main::NEWLINE	

main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::INTEGER	0
main::ADDOP	+
main::NEWLINE	

main::INTEGER	1
main::ADDOP	+
main::INTEGER	2
main::ADDOP	+
main::INTEGER	3
main::ADDOP	+
main::INTEGER	4
main::ADDOP	+
main::INTEGER	5
main::ADDOP	+
main::INTEGER	6
main::ADDOP	+
main::INTEGER	6
main::ADDOP	+
main::INTEGER	7
main::ADDOP	+
main::INTEGER	7
main::ADDOP	+
main::INTEGER	7
main::ADDOP	-
main::INTEGER	76
main::NEWLINE	

