#!/usr/bin/perl

use warnings;
use strict;
use YAML::XS qw(DumpFile);

my $name = shift;
die "must receive a distro as parameter" unless(defined($name));
chomp($name);
my $distribution= '^' . $name;

my $filename = "$name.yml";
$filename =~ s/\//./;

my %data = ( comment => 'Tests hang smoker',
             match => { distribution => $distribution },
             disabled => 1 );

DumpFile( "/home/arfreitas/.cpan/prefs/$filename", \%data );

