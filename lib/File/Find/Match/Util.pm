=head1 NAME

File::Find::Match::Util - Some exportable utility functions for writing rulesets.

=head1 SYNOPSIS

   use File::Find::Match::Util qw( filename );

   $pred = filename('foobar.pl');

   $pred->('foobar.pl')         == 1;
   $pred->('baz/foobar.pl')     == 1;
   $pred->('baz/bar/foobar.pl') == 1;
   $pred->('bazquux.pl')        == 0;
     
=head1 DESCRIPTION

This provides a few handy functions which create predicates
for L<File::Find::Match>.

=cut

package File::Find::Match::Util;
require 5.008;
use strict;
use warnings;
use base 'Exporter';
use File::Basename ();

our $VERSION = 0.08;
our @EXPORT     = qw( );
our @EXPORT_OK  = qw( filename );

=head1 FUNCTIONS

The following functions are available for export.

=head2 filename($basename)
  
This function returns a subroutine reference, which takes one argument $file
and returns true if C<File::Basename::basename($file) eq $basename>, false otherwise.
See C<File::Basename> for details.

Essentially, C<filename('foobar')> is equivalent to:

  sub { File::Basename::basename($_[0]) eq 'foobar' }

=cut

sub filename {
    my $basename = shift;
    
    return sub {
        File::Basename::basename($_[0]) eq $basename;
    };
}

=head1 EXPORTS

None by default. 

L</filename($basename)> upon request.

=head1 BUGS

None known. Bug reports are welcome. 

Please use the CPAN bug ticketing system at L<http://rt.cpan.org/>.
You can also mail bugs, fixes and enhancements to 
C<< <bug-file-find-match >> at C<< rt.cpan.org> >>.

=head1 CREDITS

Thanks to Andy Wardly for the name, and the Template Toolkit list for inspiration.

=head1 AUTHOR

Dylan William Hardison E<lt>dhardison@cpan.orgE<gt>

L<http://dylan.hardison.net/>

=head1 SEE ALSO

C<File::Find::Match>, L<File::Find>, L<perl(1)>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2004 Dylan William Hardison.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

1;
