#!/usr/bin/perl
use strict;
use warnings;

use Test::Deep;
use Test::More tests => 8;
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
