=head1 NAME

File::Find::Match - Perform different actions on files based on file name.

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use File::Find::Match qw( :constants );
	use File::Find::Match::Util qw( filename );

    my $finder = new File::Find::Match;
    $finder->rules(
        filename('.svn') => sub { IGNORE },
        qr/\.pm$/ => sub {
            print "Perl module: $_[0]\n";
            MATCH;
        },
        qr/\.pl$/ => sub {
            print "This is a perl script: $_[0]\n";
            # let the following rules have a crack at it.
        },
        qr/filer\.pl$/ => sub {
            print "myself!!! $_[0]\n";
            MATCH;
        },
        # dir =>  is the same as -d => or sub { -d } => 
        dir => sub {
            print "Directory: $_[0]\n";
            MATCH;
        },
        # default is like an else clause for an if statement.
        # It is run if none of the other rules return MATCH or IGNORE.
        default => sub {
            print "Default handler.\n";
            MATCH;
        },
    );

    $finder->find;


=head1 DESCRIPTION

This module is allows one to recursively process files and directories
based on the filename. It is meant to be more flexible than File::Find.

=cut

package File::Find::Match;
use 5.008;
use strict;
use warnings;
use base 'Exporter';
use File::Basename ();
use Carp;

use constant {
	RULE_PREDICATE   => 0,
	RULE_ACTION      => 1,
	
    # Author's birth year: 1985. :)
	IGNORE => \19,
	MATCH  => \85,
    VALUE  => \14, # day of month.
};


our $Id         = '$Id: Match.pm 345 2004-12-23 09:03:19Z dylan $';
our $VERSION    = 0.08;
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
	
    # Rule list
	$me->{rules} = [];

    # Named predicates:
    $me->{predicates} = {
        file => sub { -f $_[0] },
        dir  => sub { -d $_[0] },
    };
    
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
        croak "Undefined action!"          unless defined  $action;
        croak "Action not CODE reference!" unless ref $action eq 'CODE';
        
        if ($predicate eq 'default') {
            $me->{default} = $action;
            next;
        }
        
		my $pred = $me->_make_predicate($predicate);
        
		push @{ $me->{rules} }, [$pred, $action];
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
		next unless $matcher->($path);
		
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

Naturally for regexp predicates, matching occures when the pattern matches
the filename.

For coderef predicates, the coderef is called with one argument:
the filename to be matched.
If it returns a true value, the predicate is true. Else the predicate is false.

The 'default' string predicate is magical.
It must only be specified as a predicate once, and it is called after
all predicates, regardless of the order.

The 'dir' string predicate is the same as C<sub { -d $_[0] }>.

The 'file' string predicate is the same as C<sub { -f $_[0] }>.

Any other string will be evaluated as perl code.
In addition, $_ will be set to the first argument.
Thus a predicate of '-r' is the same as sub { -r $_[0] } (because -r defaults to using $_).

Any exceptions (e.g. calling C<die()>, or synax errors) within the eval'd perl code
will be raised to the caller.

=cut

# Take a predicate and return a coderef.
sub _make_predicate {
	my ($me, $pred) = @_;
	my $ref =  ref($pred) || '';
	
	die "Undefined predicate!" unless defined $pred;
	
	# If it is a qr// Regexp object,
	# the predicate is the truth of the regex.
    if ($ref eq 'Regexp') {
		return sub { $_[0] =~ $pred };
	}
	# If it's a sub, just return it.
	elsif ($ref eq 'CODE') {
		return $pred;
	} 
    elsif (not $ref) {
        if (exists $me->{predicates}{$pred}) {
            return $me->{predicates}{$pred};
        } else {
            my $code = eval "sub { \$_ = shift; $pred }";
            if ($@) {
                die $@;
            }
            return $code;
        }
    }   
    # All other values are illegal.
	else {
		die "Predicate must be code or regexp reference.";
	}
}


=head2 Actions

An action is just a subroutine reference that is called when its associated
predicate matches a file. When an action is called, 
its first argument will be the filename.


If an action returns C<IGNORE> or C<MATCH>, all following rules will not be tried.
You should return C<IGNORE> when you do not want to recurse into a directory, and C<MATCH>
otherwise. On non-directories, currently there is no difference between the two.

If an action returns niether C<IGNORE> nor C<MATCH>, the next rule will be tried.

=cut

sub _matcher {
	my $me      = shift;
	my @rules   = @{ $me->{rules} };
    my $default = $me->{default} || sub { };
	
	sub {
        my $file = shift;
        
		foreach my $rule (@rules) {
			if ( $rule->[RULE_PREDICATE]->($file) ) {
				my $v = $rule->[RULE_ACTION]->($file) || 0;
				
				return 0 if $v == IGNORE;
				return 1 if $v == MATCH;
			}
		}
        my $v = $default->($file) || 0;
		return 0 if $v == IGNORE;
		return 1 if $v == MATCH;
        return undef;
	};
}

=head1 BUGS

None known. Bug reports are welcome. 

Please use the CPAN bug ticketing system at L<http://rt.cpan.org/>.
You can also mail bugs, fixes and enhancements to 
C<< <bug-file-find-match >> at C<< rt.cpan.org> >>.

=head1 AUTHOR

Dylan William Hardison E<lt>dhardison@cpan.orgE<gt>

L<http://dylan.hardison.net/>

=head1 SEE ALSO

C<File::Find::Match::Util>, L<File::Find>, L<perl(1)>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2004 Dylan William Hardison.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
