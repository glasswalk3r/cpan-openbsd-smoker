#!/usr/bin/env perl
use warnings;
use strict;
use YAML::XS 0.73 qw(DumpFile);
use File::HomeDir 1.00;
use File::Spec;

my $name = shift;
die "must receive a distro as parameter" unless(defined($name));
chomp($name);
my $distribution= '^' . $name;

my $filename = "$name.yml";
$filename =~ s/\//./;

my %data = ( comment => 'Tests hang smoker',
             match => { distribution => $distribution },
             disabled => 1 );

DumpFile( File::Spec->catfile( File::HomeDir->my_home, '.cpan', 'prefs', $filename), \%data );

