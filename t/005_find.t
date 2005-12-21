#!/usr/bin/perl
# vim: set ft=perl:
use strict;
use Test::More tests => 4;
use ExtUtils::Manifest 'maniread';
use File::Find::Match 'IGNORE', 'MATCH';
use Fatal qw( open close );

my $have  = maniread();
my %found = ();
my $finder = new File::Find::Match;

my $fh;
open $fh, 'MANIFEST.SKIP';
while (my $re = <$fh>) {
    chomp $re;
    $finder->rule(
        qr/$re/ => sub { IGNORE },
    );
}
close $fh;

$finder->rules(
    dir     => sub { MATCH },
    default => sub { 
        my $s = shift;
        $s =~ s!^\./!!;
        $found{$s} = $have->{$s} = 1;
        return undef;
    },
);

$finder->find;

is_deeply($have, \%found, 'Check directory structure with File::Find::Match');

%found = ();
$finder = new File::Find::Match;

$finder->rules(
    dir     => sub { MATCH },
    file => sub { 
        my $s = shift;
        $s =~ s!^\./!!;
        $found{$s} = $have->{$s} = 1;
        return [];
    },
);

$finder->find('.');

is_deeply($have, \%found, 'Check directory structure with File::Find::Match');

eval { $finder->rule(dir => []) };

if ($@) {
	pass("Non-CODEref action died. Yay!");
} else {
	fail("Non-CODEref action did not died. Booh!");
}

eval { $finder->rule(dir => undef) };

if ($@) {
	pass("undef action died. Yay!");
} else {
	fail("undef action did not died. Booh!");
}

