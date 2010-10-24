package Mysql::Dump::Simple;

use warnings;
use strict;
use Carp qw/croak carp/;

=head1 NAME

Mysql::Dump::Simple - Simple OO interface to mysqldump

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Mysql::Dump::Simple;

    my $dumper = Mysql::Dump::Simple->new('/usr/bin/mysqldump');
	#add single command line options (one or two options)
	$dumper->config ('quick');
	$dumper->config ('compatible','oracle');

	#set of preconfigured configuration options
	$dumper->config_1;

	#report on mysqldump version
	my $version=$dumper->version

	#separate methods for user,pass, db
	$dumper->user ($user);
	$dumper->password ($pass)
	$dumper->database($db)

	#execute mysqldump
	$response=$dumper->run;
	#alternatively write to file directly
	$response=$dumper->run($filename);

	#check for error from run
	if ($dumper->isError) {
		print $response
	}

=head1 DESCRIPTION

This is a simple and not particular safe or fast way to use mysqldump from
perl.

STDERR and STDOUT: As a rule of thumb, return nothing on failure and 1 on
success (which seems good for testing). Where this doesn't work since another
return value expected use isError.

Should we reset isError's error status after accessing it? No. Just make a
new Mysql::Dump::Simple object when you're done.

Use Data::Dumper to inspect Mysql::Dump::Simple object. It contains debug info
in self->{cmd}.

=head1 SECURITY CONCERNS

-you might be able to see password using ps
-you could relatively easy replace the bin for mysqldump

=head1 LIMITED SMARTNESS

Mysql::Dump::Simple tries not to be particularly smart; instead it tries to be
what you expect it to do, e.g. construct a command line with the parameters you
hand over to it.

However, limited smartness is provided:
-if you don't specify any database, it will add --all-databases

=head1 METHODS

=head2 my $dumper = Mysql::Dump::Simple->new('/usr/bin/mysqldump');

=cut

sub new {
	my $class = shift;
	my $bin   = shift;
	return if ( !$bin );
	return if ( !-e $bin );
	my $self = {};
	$self->{bin} = $bin;
	return bless( $self, $class );
}

=head2 config

=cut

sub config {
	my $self   = shift;
	my $switch = shift;
	my $param  = shift;

	croak "switch \$dumper->config(\$switch) not defined" if ( !$switch );

	if ( $switch =~ /^-/ ) {
		carp
		  "Unlikely that you want to start you config argument with a hyphen!";
	}

	if ( $switch =~ /^--all-databases/ ) {
		carp "If you want Mysql::Dump::Simple to use --all-databases, don't "
		  . "specify any database! Otherwise you likely get messed up command "
		  . "line";
	}

	$self->{args} .= "--$switch ";

	#print "TT:$switch\n";
	if ($param) {
		$self->{args} .= "$param ";
	}

}

=head2 $dumper->config_1;

Use quick, add-locks, add-drop-table and if mysql version permits it date-dump.

=cut

sub config_1 {
	my $self=shift;
	$self->config('quick');
	$self->config('add-locks');
	$self->config('add-drop-table');

	#not sure about the version number at this point. Might be higher!
	if ($self->version('numeric') gt 5051) {
		$self->config('date-dump');
	}

}

=head2 my $version=$dumper->version;

Return version info of mysqldump. Several forms so one can quickly test against
it:

my $version=$dumper->version(full); #full reply from mysqldump
my $version=$dumper->version(numeric); #contract version to number e.g. '5234'
my $version=$dumper->version(); #extract string e.g. '5.0.45a'

=cut

sub version {
	my $self = shift;
	my $arg  = shift;
	my $cmd  = "'$self->{bin}'" . ' --version';
	my $full = qx ($cmd);
	if ($arg) {
		if ( $arg eq 'full' ) {
			chomp($full);
			return $full;
		}
		if ( $arg eq 'numeric' ) {
				$full =~ /Distrib (\d)\.(\d)\.([\d]+),/;
				my $num="$1$2$3";
				return $num;
		}
	}
	$full =~ /Distrib (\d\.\d\.[\d\w]+),/;
	return $1 if ($1);

	#TODO: check error value here
}

=head2 user
=cut

sub user {
	my $self = shift;
	my $user = shift;

	return if ( !$user );

	#or croak?

	$self->{user} = '--user=' . $user . ' ';
}

=head2 password
=cut

sub password {
	my $self = shift;
	my $pass = shift;

	return if ( !$pass );

	#or croak?

	$self->{pass} = '--password=' . $pass . ' ';
}

=head2 database
=cut

sub database {
	my $self = shift;
	my $db   = shift;

	#databases can be repeated in command line if using --database
	return if ( !$db );

	#or croak?
	#first db
	if ( !$self->{db} ) {
		$self->{db} = $db;
		return 1;
	}

	#not first db:add if you don't have already
	if ( !( $self->{db} =~ /^--databases/ ) ) {
		$self->{db} = '--databases ' . $self->{db};
	}
	$self->{db} .= " $db";
}

=head2 run
=cut

sub run {
	my $self = shift;
	my $file = shift;

	#construct and save $cmd
	my $cmd = "'$self->{bin}' ";
	if ( $self->{args} ) {
		$cmd .= $self->{args};
	}

	if ( $self->{user} ) {
		$cmd .= $self->{user};
	}

	if ( $self->{pass} ) {
		$cmd .= $self->{pass};
	}

	#be a little smart
	#if no db specified dump all
	if ( $self->{db} ) {
		$cmd .= $self->{db} . ' ';
	} else {
		$cmd .= '--all-databases ';
	}

	# How to test cmd's success? via $?
	# How to obtain STDERR?
	#

	#open(CMD, '-|', '/usr/bin/ls', '$4', '$PATH');
	#my $output = do { local $/; <CMD> };
	#close CMD;
	#print "$output\n";

	if ($file) {

		#write output to file directly
		#return STDERR
		$cmd .= "2>&1 1> $file ";
		$self->{cmd} = $cmd;
		my $output = qx/$cmd/;

		$self->{error_value} = $?;
		return $output;

		#first attempt: use command
		#system($cmd);
		#I don't get STDERR
		#2nd attempt
		#I get output which is empty on error this way, but not STDOUT
		#3rd attempt
		#redirect STDERR to STDOUT?

		#not sure what to return? nothing or 1
		#or STDERR;
		#return 1;

	}

	#else write output and STDERR in perl variable
	#depends on shell is unlikely to work under windows
	$cmd .=' 2>&1';
	$self->{cmd} = $cmd;

	my $output = qx/$cmd/;

	$self->{error_value} = $?;
	return $output;
}

=head2 isError
=cut

sub isError {
	my $self = shift;

	#returns 0 on success and at a >0
	return $self->{error_value};
}

=head1 AUTHOR

Maurice Mengel, C<< <mauricemengel at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mysql-dump-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mysql-Dump-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mysql::Dump::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mysql-Dump-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mysql-Dump-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mysql-Dump-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Mysql-Dump-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Maurice Mengel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Mysql::Dump::Simple
