#!/usr/bin/perl

use strict;
use warnings;
use File::Find::Match qw( :constants );
use lib 'blib';

my $finder = new File::Find::Match;
$finder->rules(
	qr/\.svn/    => sub { IGNORE },
	qr/_build/   => sub { IGNORE },
	qr/\bblib\b/ => sub { IGNORE },
	qr/\.pm$/    => sub {
		print "Perl module: $_\n";
		return MATCH;
	},
	qr/\.pl$/ => sub {
		print "This is a perl script: $_\n";
		return PASS; # let the following rules have a crack at it.
	},
	qr/filer\.pl$/ => sub {
		print "myself!!! $_\n";
		return MATCH;
	},
	dir => sub {
		print "Directory: $_\n";
		MATCH;
	},
);

$finder->find('.');
