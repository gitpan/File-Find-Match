=head1 NAME

File::Find::Match - Perform different actions on files based on file name.

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use File::Find::Match qw( :constants );
	use File::Find::Match::Sugar qw( dir default );

    my $finder = new File::Find::Match;
    $finder->rules(
        ".svn"    => sub { IGNORE },
        qr/\.pm$/ => sub {
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

=cut

package File::Find::Match;
use strict;
use warnings;
use base 'Exporter';
use File::Basename ();
use Carp;

use constant {
	RULE_PREDICATE   => 0,
	RULE_ACTION => 1,
	
	IGNORE => \19,
	MATCH  => \85,
};


our $Id         = '$Id: Match.pm 303 2004-11-25 07:37:05Z dylan $';
our $VERSION    = 0.07;
our @EXPORT     = qw( IGNORE MATCH );
our @EXPORT_OK  = @EXPORT;
our %EXPORT_TAGS = (
	constants => [ @EXPORT ],
	all       => [ @EXPORT ],
);

=head1 METHODS

=head2 new(%opts)

Creates a new C<File::Find::Match> object.
Currently %opts is ignored.

If you are going to sublcass C<File::Find::Match>, you may
override initialize() which new() calls right after object creation.

=cut

sub new {
	my ($this) = shift;
	my $me = bless {}, $this;
	
	$me->{rules} = [];
	
	return $me;
}


=head2 rules($predicate => $action, ...)

rules() accpets a list of $predicate => $action pairs.

See L</RULES> for a detailed description.

=cut

sub rules {
	my $me = shift;
	
	while (@_) {
		my ($predicate, $action) = (shift, shift);
		my $pred = $me->_predicate($predicate);
		my $act  = $me->_action($action);
		push @{ $me->{rules} }, [ $pred, $act];
	}
}

=head2 rule($predicate => $action)

This is just an alias to rules().

=cut 

*rule = \&rules;

=head2 find(@dirs)

Start the breadth-first search of @dirs (defaults to '.' if empty)
using the specified rules.

The return value of this function is unimportant.

=cut

sub find {
	my ($me, @files) = @_;
	my $matcher = $me->_matcher();
	
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

=head1 EXPORTS

Two constants are exported: C<IGNORE> and C<MATCH>.

See L</Actions> for usage.

=head1 RULES

A rule is a predicate => action pair.

A predicate is the code (or regexp, see below) used to determine if
we want to process a file.

An action is the code we use to process the file.
By process, I mean anything from sending it through a templating engine to printing
its name to C<STDOUT>.




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


=cut

# Take a predicate and return a coderef.
sub _predicate {
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


=head2 Actions

An action is just a subroutine reference that is called when its associated
predicate matches a file. When an action is called, $_ will be set to the filename.

=cut



sub _action {
	my ($me, $act) = @_;
	my $ref = ref($act) || '';

	confess "Undefined action!" unless defined $act;

	if ($ref eq 'CODE') {
		return $act;
	} else {
		die "Unknown action: $act";
	}
}

=pod

If an action returns C<IGNORE> or C<MATCH>, all following rules will not be tried.
You should return C<IGNORE> when you do not want to recurse into a directory, and C<MATCH>
otherwise. On non-directories, currently there is no difference between the two.

If an action returns niether C<IGNORE> nor C<MATCH>, the next rule will be tried.

=cut

sub _matcher {
	my $me = shift;
	my @rules = @{ $me->{rules} };
	
	sub {
		foreach my $rule (@rules) {
			if ( $rule->[RULE_PREDICATE]->() ) {
				my $v = $rule->[RULE_ACTION]->();
				
				return 0 if $v == IGNORE;
				return 1 if $v == MATCH;
			}
		}
	};
}

=head1 AUTHOR

Dylan William Hardison E<lt>dhardison@cpan.orgE<gt>

L<http://dylan.hardison.net/>

=head1 SEE ALSO

C<File::Find::Match::Sugar>, L<File::Find>, L<perl(1)>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2004 Dylan William Hardison.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
