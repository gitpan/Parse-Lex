use ExtUtils::MakeMaker;
require 5.002;
$Verbose = 1;
WriteMakefile(
	'NAME'		=> 'Parse::Lex',
#	'DISTNAME'	=> '',
	'VERSION_FROM'	=> 'Parse/Lex.pm',
	'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

