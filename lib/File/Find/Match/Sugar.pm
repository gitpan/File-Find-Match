=head1 NAME

File::Find::Match::Sugar - Syntax sugar functions for File::Find::Match.

=head1 SYNOPSIS

See L<File::Find::Match>.

=head1 DESCRIPTION

The module exports a few functions that makes writing File::Find::Match
rules a bit prettier. Because, let's face it, writing C<sub { 1 } =E<gt> sub { ... }>
is not nearly as nice as C<default { ... }>.

=head1 EXPORT

The functions dir(), file(), and default() are exported by default.

=cut

package File::Find::Match::Sugar;
use strict;
use warnings;
use base 'Exporter';

our $VERSION     = '0.02';
our @EXPORT      = qw( dir file default );
our %EXPORT_TAGS = (
	all => [ @EXPORT ],
);

=head1 FUNCTIONS

These functions provide a bit of syntax sugar. All of them are prototyped as C<foo (&)>,
and thus you may call them as C<foo { ... }> instead of C<foo( sub { ... } )>.

All of them return a predicate => action pair, also called a rule.
See L<File::Find::Match/"RULES"> for details on rules.

=head2 file($coderef)

This is the same as C<sub { -f $_ } =E<gt> $coderef>.

=cut

sub file (&) {
	my $coderef = shift;
	return (sub { -f $_ } => $coderef);
}

=head2 dir($coderef)

This is the same as C<sub { -d $_ } =E<gt> $coderef>.

=cut

sub dir (&) {
	my $coderef = shift;
	return (sub { -d $_ } => $coderef);
}

=head2 default($coderef)

This is the same as C<sub { 1 } =E<gt> $coderef>.

You may think of this as similiar to an the else clause of an if statement.

=cut

sub default (&) {
	my $coderef = shift;
	return (sub { 1 } => $coderef);
}


1;
__END__

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
