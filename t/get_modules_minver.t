#!/usr/bin/perl
use strict;
use warnings;

use Test::Deep;
use Test::More tests => 17;
use File::Basename;
use File::Spec::Functions qw(catfile);

my $class = "Module::Extract::Use";

use_ok( $class );

my $extor = $class->new;
isa_ok( $extor, $class );
can_ok( $extor, 'get_modules_minver' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file that doesn't exist, should fail
{
my $not_there = 'not_there';
ok( ! -e $not_there, "Missing file is actually missing" );

$extor->get_modules_minver( $not_there );
like( $extor->error, qr/does not exist/, "Missing file give right error" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with this file
{
my $test = $0;
ok( -e $test, "test file is there" );

my %wanted = (
    'strict'                => 0,
    'warnings'              => 0,
    'Test::Deep'            => 0,
    'Test::More'            => 0,
    'File::Basename'        => 0,
    'File::Spec::Functions' => 0,
);
my %found = $extor->get_modules_minver( $test );
ok( ! $extor->error, "no error for parseable file [$test]" );
cmp_deeply( \%found, \%wanted, 'all requires found, but no more' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file with some minimum version (including perl)
{
my $file = catfile( qw(corpus Version.pm) );
ok( -e $file, "test file is there" );

my %wanted = (
    'perl'          => '5.006',
    'Local::MinVer' => '0.50',
);
my %found = $extor->get_modules_minver( $file );
ok( ! $extor->error, "no error for parseable file [$file]" );
cmp_deeply( \%found, \%wanted, 'all requires found, but no more' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file with some inheritance
{
my $file = catfile( qw(corpus Inheritance.pm) );
ok( -e $file, "test file is there" );

my %wanted = (
    'base'                 => 0,
    'parent'               => 0,
    'Local::Base::base1'   => 0,
    'Local::Base::base2'   => 0,
    'Local::Base::base3'   => 0,
    'Local::Base::parent1' => 0,
    'Local::Base::parent2' => 0,
    'Local::Base::parent3' => 0,
);
my %found = $extor->get_modules_minver( $file );
ok( ! $extor->error, "no error for parseable file [$file]" );
cmp_deeply( \%found, \%wanted, 'all requires found, but no more' );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with a file with some moose stuff
{
my $file = catfile( qw(corpus Moose.pm) );
ok( -e $file, "test file is there" );

my %wanted = (
    'Local::Base::Moose1' => 0,
    'Local::Base::Moose2' => 0,
    'Local::Role'         => 0,
);
my %found = $extor->get_modules_minver( $file );
ok( ! $extor->error, "no error for parseable file [$file]" );
cmp_deeply( \%found, \%wanted, 'all requires found, but no more' );
}

