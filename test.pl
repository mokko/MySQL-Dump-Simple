#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use MySQL::Dump::Simple;
use Data::Dumper;


my $dumper=MySQL::Dump::Simple->new('/cygdrive/C/Program Files/mysql/bin/mysqldump');

if ($dumper) {
	print "D exists\n";
}

$dumper->config ('quick');
#$dumper->config ('all-databases');


print "VERSION". $dumper->version ('numeric')."\n";

$dumper->database ('aimp');

$dumper->user ('testuser');
$dumper->password ('testpass');

my $out=$dumper->run ("test.txt"); #returns 1 on success???
if ($dumper->isError) {
	print "IsError yes\n";
	print "ERROR MESSAGE?:$out\n";
} else {
	print "IsError no\n";
	print $out;

}

print Dumper $dumper;



