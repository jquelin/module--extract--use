package Module::Extract::Use;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.17';

=head1 NAME

Module::Extract::Use - Pull out the modules a module uses

=head1 SYNOPSIS

	use Module::Extract::Use;

	my $extor = Module::Extract::Use->new;
	
	my @modules = $extor->get_modules( $file );
	if( $extor->error ) { ... }
	
	
=head1 DESCRIPTION

Extract the names of the modules used in a file using a static analysis.
Since this module does not run code, it cannot find dynamic uses of
modules, such as C<eval "require $class">.

=cut

=over 4

=item new

Makes an object. The object doesn't do anything just yet, but you
need it to call the methods.

=cut

sub new 
	{ 
	my $class = shift;
	
	my $self = bless {}, $class;
	
	$self->init;
	
	$self;
	}

=item init

Set up the object. You shouldn't need to call this yourself.

=cut

sub init 
	{ 
	$_[0]->_clear_error;
	}

=item get_modules( FILE )

Returns a list of namespaces explicity use-d in FILE. Returns undef if the
file does not exist or if it can't parse the file.

Each used namespace is only in the list even if it is used multiple times
in the file. The order of the list does not correspond to anything so don't
use the order to infer anything.

=cut

sub get_modules {
	my( $self, $file ) = @_;

	my %modules = $self->get_modules_minver($file);
	return keys %modules;
	}

=item get_modules_minver( FILE )

Returns a hash of module with their minimum version explicity use-d in
FILE. The version will be 0 if not specified in code. Returns undef if
the file does not exist or if it can't parse the file.

=cut

sub get_modules_minver {
	my( $self, $file ) = @_;

	$_[0]->_clear_error;

	unless( -e $file )
		{
		$self->_set_error( ref( $self ) . ": File [$file] does not exist!" );
		return;
		}

	# parse the document with ppi and extract include statements
	require PPI;
	my $Document = eval { PPI::Document->new( $file ) };
	unless( $Document )
		{
		$self->_set_error( ref( $self ) . ": Could not parse file [$file]" );
		return;
		}
	my $modules = $Document->find( 'Statement::Include' ) || [];

	# extract minimum versions
	my %prereqs;
	foreach my $include ( @$modules )
		{
		# minimum perl version
		if ( $include->version )
			{
			$prereqs{perl} = $include->version;
			next;
			}

		# regular modules
		my $version = $include->module_version
		    ? $include->module_version->content
		    : 0;
		$prereqs{ $include->module } = $version;

		# inheritance: extract base class
		if ( $include->module =~ /^(base|parent)$/ )
			{
			# the content is in the 5th token
			my $meat = $include->child(4);
			my @parents = $meat->isa('PPI::Token::QuoteLike::Words')
				? ( $meat->literal )     # use base qw{ ... }
				: ( $meat->string  );	 # use base "..."
			@prereqs{ @parents } = (0) x @parents;
			}
		}

	{ # Moose specificities
	# let's fetch top-level statements
	my @statements =
		grep { $_->child(0)->isa('PPI::Token::Word') }
		grep { ref($_) eq 'PPI::Statement' } # no ->isa()
		$Document->children;

	# roles: with ...
	my @roles =
		map  { $_->child(2)->string }
		grep { $_->child(0)->literal eq 'with' }
		@statements;
	@prereqs{ @roles } = (0) x @roles;

	# inheritance: extends ...
	my @bases =
		map  { $_->string }
		grep { $_->isa('PPI::Token::Quote') }
		map  { $_->children }
		grep { $_->child(0)->literal eq 'extends' }
		@statements;
	@prereqs{ @bases } = (0) x @bases;
	}

	return %prereqs;
	}



=item error

Return the error from the last call to C<get_modules>.

=cut

sub _set_error   { $_[0]->{error} = $_[1]; }
	
sub _clear_error { $_[0]->{error} = '' }

sub error        { $_[0]->{error} }

=back

=head1 TO DO

* Make it recursive, so it scans the source for any module that
it finds.

=head1 SEE ALSO

L<Module::ScanDeps>

=head1 SOURCE AVAILABILITY

The source code is in Github:

	git://github.com/briandfoy/module--extract--use.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
