#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mysql::Dump::Simple' ) || print "Bail out!
";
}

diag( "Testing Mysql::Dump::Simple $Mysql::Dump::Simple::VERSION, Perl $], $^X" );
