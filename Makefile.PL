				# See the Camel, page 409-
use ExtUtils::MakeMaker;
require 5.002;
WriteMakefile(
	      'NAME'		=> 'Parse::Lex',
	      'VERSION_FROM'	=> 'Parse/Lex.pm',
	      'dist'            => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

