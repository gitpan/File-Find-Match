#!/usr/bin/perl

use strict;
use warnings;
use File::Find::Match;
use File::Find::Match::Sugar;
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
	},
	"filer.pl" => sub {
		print "this is filer.pl: $_\n";
	},
	qr/filer\.pl$/ => sub {
		print "this is also filer.pl! $_\n";
		return MATCH;
	},
	dir {
		print "Directory: $_\n";
		MATCH;
	},
);

$finder->find('.');
