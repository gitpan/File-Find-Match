package File::Find::Match;
use strict;
use warnings;

use constant {
	IGNORE   => undef,
	SKIP     => 0,
	DONE     => 1,
};

use Exporter;
use base 'Exporter';

our $VERSION     = 0.01;
our @EXPORT      = ();
our @EXPORT_OK   = qw( find match DONE SKIP IGNORE );
our %EXPORT_TAGS = (
	constants => [qw( DONE SKIP IGNORE )],
	subs      => [qw( find match )],
	all       => [@EXPORT_OK],
);


=head1 NAME

File::Find::Match - Perform actions on files matching a regexp.

=head1 SYNOPSIS


 use File::Find::Match qw( :all );
  my $matcher = match(
	  qr/\.pm$/ => sub {
		  print "Perl module: $_\n";
		  return SKIP;
	  },
	  qr/\.svn/ => sub {
		  # tell find() to ignore .svn dirs:
		  return IGNORE;
	  },
	  qr/\.pod$/ => sub {
		  print "Pod file: $_\n";
		  return DONE;
	  },
	  default => sub {
		  print "Other kind of file: $_\n";
	  },
  );
  find($matcher, '.');

=head1 DESCRIPTION

This module implements two functions, find() and match().

find() performs a breadth-first traversal of one or more directories,
and match() creates a closure for use in performing various on actions
depending on the filename.

=head1 EXPORT

None by default.

=head2 Export Tags

=over 4

=item :all

same as :constants and :subs

=item :subs

C<find()> and C<match()>

=item :constants

C<DONE>, C<SKIP>, and C<IGNORE>.

=back

=head1 FUNCTIONS

The following functions are optionally exported.

=cut


=head2 find($visitor, @dirs)

Perform breadth-first directory traversal of all @dirs,
calling the callback function reference $visitor for each file and directory seen.
$visitor takes no arguments, and instead uses $_ for the each file name.
$_ will have a (possibly relative) path prepended to it. find() I<does not>
call chdir().

Unlike L<File::Find>, the return value of $visitor is important.
If it is a false value, the current file will be skipped.
This only really matters for directories, as it prevents them from being added to the queue.

=cut

sub find {
	my $cb = shift;
	my @files = @_;
	my ($file);

	while (@files) {
		$file = shift @files;
		$_ = $file;
		next unless $cb->();
		
		if (-d $file) {
			my $dir;
			opendir $dir, $file;
			push @files, map { "$file/$_"  } grep {  $_ ne '.' and $_ ne '..' } readdir $dir;
			closedir $dir;
		}
	}
}

=head2 match(%actions)

This function takes a list of key-value pairs. The keys are either
regexp references from C<qr//> or the string 'default'. The values are subroutine references.

match() will return a reference to newly-created function.

This function, which we will call visitor, that is returned will check run each regular expression
on the value of $_, and if there is a match it will call the associated function reference.
If this function ref returns C<SKIP>, the next pattern will be tried.
If it returns C<IGNORE>, the visitor function will return undef.
If it returns C<DONE>, the visitor function will return a true value.

After all patterns have been tried, the visitor function will call the function
reference associated with the 'default' string, unless we got C<IGNORE>
or the default action was not specified.

  match(
	  qr/\.pm$/ => sub {
		  print "Perl module! $_\n";
		  return SKIP;
	  },
	  qr/\.pod$/ => sub {
		  print "Pod file! $_\n";
		  return SKIP;
	  },
	  qr/\.pl$/ => sub {
		  print "Perl file! $_\n";
		  return DONE;
	  },
	  qr/\.svn/ => sub {
		  return IGNORE
	  },
	  default => sub {
		  print "Called for every file, unless ignored or done-ed.";
		  # make sure to return a true value here.
	  });
  
  # the above is functionally the same as...
  sub {
	  if (/\.pm$/) {
		  print "Perl module! $_\n";
	  }
	  if (/\.pod$/) {
		  print "Pod file! $_\n";
	  }
	  if (/\.pl$/) {
		  print "Perl file! $_\n";
		  goto default;
	  }
	  if (/\.svn/) {
		  return undef;
	  }
	  default:
	  print "Called for every file, unless ignored or done-ed.";
	  return 1;
  };

  # So, match() makes things a bit more elegant, no?
=cut

sub match {
	my @acts;
	my $default = \&OK;
	
	while (@_) {
		my @pair = (shift, shift);
		
		if ($pair[0] eq 'default') {
			$default = $pair[1];
			next;
		}
			
		push @acts, \@pair;
	}
	
	sub {
		foreach my $pair (@acts) {
			if ($_ =~ $pair->[0]) {
				my $v = $pair->[1]->($_);

				# If IGNORE.
				return unless defined $v; # IGNORE
				next   unless $v;         # SKIP
				if ($v) { # DONE
					$default->();
					return $v;
				}
			}
		}
		return $default->();
	};
}

=head1 AUTHOR

Dylan William Hardison E<lt>dhardison@cpan.orgE<gt>

L<http://dylan.hardison.net/>

=head1 COPYRIGHT

  Copyright (C) 2004 Dylan William Hardison.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

