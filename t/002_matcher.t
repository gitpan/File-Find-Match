#!/usr/bin/perl
# vim: set ft=perl:
use strict;
use Test::More tests => 5;

use File::Find::Match qw( MATCH IGNORE );
my $finder = new File::Find::Match;

can_ok($finder,
	qw(
		_matcher
	),
);

$finder->rules(
    qr/\.match$/ => sub {
        my $file = shift;
        return MATCH;
    },
    qr/\.ignore$/ => sub {
        my $file = shift;
        return IGNORE;
    },
);
    

my $matcher = $finder->_matcher;

ok($matcher->('foobar.ignore') == 0, "IGNORE'd foobar.ignore");
ok($matcher->('foobar.match')  == 1, "MATCH'd foobar.match");
my $v = $matcher->('foobar.stuff');
ok((not defined $v), "Unknown foobar.stuff");
$finder->rule(
    qr/\.stuff$/ => sub {
        return MATCH;
    },
);
$matcher = $finder->_matcher;
ok($matcher->('foobar.stuff')  == 1, "MATCH'd foobar.stuff");

