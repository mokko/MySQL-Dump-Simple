use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mysql::Dump::Simple',
    AUTHOR              => q{Maurice Mengel <mauricemengel@gmail.com>},
    VERSION_FROM        => 'lib/Mysql/Dump/Simple.pm',
    ABSTRACT_FROM       => 'lib/Mysql/Dump/Simple.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mysql-Dump-Simple-*' },
);
