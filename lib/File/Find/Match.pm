package File::Find::Match;
use strict;
use warnings;
use base 'Exporter';
use File::Basename ();

use constant {
	# Indices for the $rule arrays.
	COND   => 0,
	ACTION => 1,
	NAME   => 2,
};
{
	# Special return values for matching functions.
	my $ignore;
	my $match;

	use constant {
		MATCH  => \$match,
		IGNORE => \$ignore,
	};
}

BEGIN {
	my  @constants   = qw( IGNORE MATCH );
	my  @func        = qw( file dir default );
	our @EXPORT      = @constants;
	our @EXPORT_OK   = (@constants, @func);
	our %EXPORT_TAGS = (
		constants => \@constants,
		functions => \@func,
		all       => [ @EXPORT_OK ],
	);
}

our $ID      = '$Id: Match.pm 295 2004-11-13 02:42:36Z dylan $';
our $VERSION = 0.05;

sub file (&);
sub dir (&);
sub default (&);

sub file (&) {
	my $code = shift;

	return (sub { -f $_ } => $code);
}

sub dir (&) {
	my $code = shift;

	return (sub { -d $_ } => $code);
}

sub default (&) {
	my $code = shift;
	
	return (sub { 1 } => $code);
}


sub new {
	my ($this) = shift;
	my $me = bless {}, $this;
	
	$me->initialize(@_);

	return $me;
}

sub initialize {
	my ($me) = @_;

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
			}
		}
	};
}


sub predicate {
	my ($me, $pred) = @_;
	my $ref =  ref($pred) || '';
	
	die "Undefined predicate!" unless defined $pred;
	
	# If $pred is just a string,
	# the predicate is that of equality.
	if (not $ref) {
		return sub { File::Basename::basename($_) eq $pred };
	}
	# If it is a qr// Regexp object,
	# the predicate is the truth of the regex.
	elsif ($ref eq 'Regexp') {
		return sub { $_ =~ $pred };
	}
	# If it's a sub, just return it.
	elsif ($ref eq 'CODE') {
		return $pred;
	}
	else {
		die "Unknown predicate: $pred";
	}
}

sub action {
	my ($me, $act) = @_;
	my $ref = ref($act) || '';

	die "Undefined action!" unless defined $act;

	if ($ref eq 'CODE') {
		return $act;
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
    use File::Find::Match qw( :all );
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
            # let the following rules have a crack at it.
        },
        qr/filer\.pl$/ => sub {
            print "myself!!! $_\n";
            MATCH;
        },
        # "dir {" is the same as "sub { -d $_ } => sub {"
        dir {
            print "Directory: $_\n";
            MATCH;
        },
        # default is like an else clause for an if statement.
        # It is run if none of the other rules return MATCH or IGNORE.
        default {
            print "Default handler.\n";
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

=head1 EXPORTS

By default we export :constants.

=head2 :constants

we export the numeric constants C<PASS>, C<IGNORE>, and C<MATCH>.

See L</Actions> for usage information on these constants.

=head2 :functions

We export a few functions that provide a bit of syntax sugar.
All of them are prototyped with C<(&)>, and so you may call
them as C<foo { ... }> instead of C<foo( sub { ... } )>.

All of them return a predicate => action pair, also called a rule.

=head3 file($coderef)

This is shorthand for C<sub { -f $_ } =E<gt> $coderef>.

=head3 dir($coderef)

This is shorthand for C<sub { -d $_ } =E<gt> $coderef>.

=head3 default($coderef)

This is shorthand for C<sub { 1 } =E<gt> $coderef>.
Think of it as similiar to and else clause.

=head2 :all

This is  :constants and :functions combined.

=head1 PREDICATES AND ACTIONS

A predicate is the code (or regexp, see below) used to determine if
we want to process a file. An action is the code we use to process the file.
By process, I mean anything from sending it through a templating engine to printing
its name to C<STDOUT>.

A predicate => action pair is called a rule.

=head2 Predicates

A predicate is one of: a Regexp reference from C<qr//>,
a subroutine reference, or a string.
An action is a subroutine reference that is called on
a filename when a predicate matches it.

Naturally for regexp predicates, matching occures when the pattern matches
the filename.

For coderef predicates, $_ is set to the filename and the subroutine is called.
If it returns a true value, the predicate is true. Else the predicate is false.

When the predicate is a string, it must match the basename of $_ (e.g. filename sans path) exactly.
For example, "foo" will match "bar/foo", "bar/baz/foo", and "bar/baz/quux/foo".

=head2 Actions

An action is just a subroutine reference that is called when its associated
predicate matches a file. When an action is called, $_ will be set to the filename.

If an action returns C<IGNORE> or C<MATCH>, all following rules will not be tried.
You should return C<IGNORE> when you do not want to recurse into a directory, and C<MATCH>
otherwise. On non-directories, currently there is no difference between the two.

If an action returns niether C<IGNORE> nor C<MATCH>, the next rule will be tried.

=head1 AUTHOR

Dylan William Hardison E<lt>dhardison@cpan.orgE<gt>

L<File::Find>, L<http://dylan.hardison.net>

=head1 COPYRIGHT

Copyright (C) 2004 Dylan William Hardison.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
