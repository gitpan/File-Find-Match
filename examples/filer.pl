#!/usr/bin/perl

use strict;
use warnings;
use File::Find::Tsite qw( :all );

my $finder = match(
	qr/\.svn/  => sub { IGNORE },
	qr/_build/ => sub { IGNORE },
	qr/\.pm$/  => sub {
		print "Perl module: $_\n";
		return DONE; # default is still executed.
	},
	default    => sub {
		if (-d $_) {
			print "$_/\n";
		} else {
			print "$_\n";
		}
	},
);

find($finder, '.');
