package File::Find::Match;
use strict;
use warnings;
use base 'Exporter';
use constant {
	# Indices for the $rule arrays.
	COND   => 0,
	ACTION => 1,
	NAME   => 2,

	# Return values for matching functions.
	PASS   => 400,
	MATCH  => 401,
	IGNORE => 402,
};

BEGIN {
	my  @constants   = qw( IGNORE MATCH PASS );
	our @EXPORT      = @constants;
	our @EXPORT_OK   = @constants;
	our %EXPORT_TAGS = ( constants => \@constants );
}

our $ID      = '$Id: Match.pm 284 2004-11-07 00:39:30Z dylan $';
our $VERSION = 0.02;

sub new {
	my ($this) = shift;
	my $me = bless {}, $this;
	
	$me->initialize(@_);

	return $me;
}

sub initialize {
	my ($me) = @_;

	$me->{predicates} = {
		file    => sub { -f $_ },
		dir     => sub { -d $_ },
		default => sub {  1    },
	};
	$me->{rules} = [];
}

sub find {
	my ($me, @files) = @_;
	my $matcher = $me->build_matcher();
	
	unless (@files) {
		@files = ('.');
	}

	while (@files) {
		my $path = shift @files;
		$_ = $path;
		next unless $matcher->();
		
		if (-d $path) {
			my $dir;
			opendir $dir, $path;
			
			# read all files from $dir
			# skip . and ..
			# prepend $path/ to the file name.
			# append to @files.
			push @files, map { "$path/$_"  } grep(!/^\.\.?$/, readdir $dir);
			
			closedir $dir;
		}
	}
}

# Alias rule() to rules()
*rule = \&rules;
sub rules {
	my $me = shift;
	
	while (@_) {
		my ($predicate, $action) = (shift, shift);
		my $pred = $me->predicate($predicate);
		my $act  = $me->action($action);
		push @{ $me->{rules} }, [ $pred, $act, "$predicate" ];
	}
}

sub build_matcher {
	my $me = shift;
	my @rules = @{ $me->{rules} };
	
	sub {
		foreach my $rule (@rules) {
			if ($rule->[COND]->()) {
				my $v = $rule->[ACTION]->();
				
				return 0 if $v == IGNORE;
				return 1 if $v == MATCH;
				next     if $v == PASS;
				my $vstr = defined $v ? "'$v'" : "undef";
				die "Bad return value ($vstr) for predicate $rule->[NAME]\n";
			}
		}
	};
}


sub predicate {
	my ($me, $pred) = @_;
	my $ref =  ref($pred) || '';
	
	die "Undefined predicate!" unless defined $pred;
	
	if (not $ref and exists $me->{predicates}{$pred}) {
		return $me->{predicates}{$pred};
	} elsif ($ref eq 'Regexp') {
		return sub { $_ =~ $pred };
	} elsif ($ref eq 'CODE') {
		return $pred;
	} else {
		die "Unknown predicate: $pred";
	}
}

sub action {
	my ($me, $act) = @_;
	my $ref = ref($act) || '';

	die "Undefined action!" unless defined $act;

	if ($ref eq 'CODE') {
		return $act;
	} elsif ($ref eq 'ARRAY') {
		my ($obj, $method) = (shift @$act, shift @$act);
		return sub { $obj->$method(@$act) };
	} else {
		die "Unknown action: $act";
	}
}

1;
__END__

=head1 NAME

File::Find::Match - Perform different actions on files based on file name.

=head1 SYNOPSIS
	
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
            MATCH;
        },
        qr/\.pl$/ => sub {
            print "This is a perl script: $_\n";
            PASS; # let the following rules have a crack at it.
        },
        qr/filer\.pl$/ => sub {
            print "myself!!! $_\n";
            MATCH;
        },
        dir => sub {
            print "Directory: $_\n";
            MATCH;
        },
    );

    $finder->find('.');

=head1 DESCRIPTION

This module is allows one to recursively process files and directories
based on the filename. It is meant to be more flexible than File::Find.

=head1 METHODS

=head2 new(%opts)

Creates a new C<File::Find::Match> object.
Currently %opts is ignored.

=head2 rules($predicate => $action, ...)

rules() accpets a list of $predicate => $action pairs.

See L</PREDICATES AND ACTIONS> for a detailed description.

=head2 rule($predicate => $action)

This is just an alias to rules().

=head2 find(@dirs)

Start the breadth-first search of @dirs (defaults to '.' if empty)
using the specified rules.

The return value of this function is unimportant.

=head1 PREDICATES AND ACTIONS

A predicate is one of: a Regexp reference from C<qr//>,
a subroutine reference, or a string.
An action is a subroutine reference that is called on
a filename when a predicate matches it.

Naturally for regexp predicates, matching occures when the pattern matches
the filename.

For coderef predicates, $_ is set to the filename and the subroutine is called.
If it returns a true value, the predicate is true. Else the predicate is false.

When the predicate is a string, it must be one of C<"file">, C<"dir">, or C<"default">.
The C<"file"> predicate is true when the current filename is a file, in the C<-f> sense.
The C<"dir"> predicate is true when the filename is a dir in the C<-d> sense,
The C<"default"> predicate is always true.

=head1 AUTHOR

Dylan William Hardison E<lt>dhardison@cpan.orgE<gt>

L<File::Find>, L<http://dylan.hardison.net>

=head1 COPYRIGHT

  Copyright (C) 2004 Dylan William Hardison.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
