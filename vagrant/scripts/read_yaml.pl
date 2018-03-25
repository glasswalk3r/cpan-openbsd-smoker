#!/usr/bin/perl
# Reads the YAML file depending on users running the script and
# creates a text file with information about how to run the install
# with perlbrew.
# First line is the command itself.
# Second line is the perl version/flavor
use warnings;
use strict;
use YAML::XS qw(LoadFile);
use File::Spec;

my $YAML_FILE = $ARGV[0];
my $self      = $ENV{LOGNAME};
my $yaml      = LoadFile($YAML_FILE);
my $perlbrew =
  File::Spec->catfile( $ENV{HOME}, 'perl5', 'perlbrew', 'bin', 'perlbrew' );
my @options = (
    $perlbrew, 'install',
    $yaml->{users}->{$self}->{perl},
    @{ $yaml->{users}->{$self}->{args} }
);
my $install_perl_cmd = File::Spec->catfile( $ENV{HOME}, 'install_perl.txt' );
open( my $out, '>', $install_perl_cmd )
  or die "Cannot create $install_perl_cmd: $!";
print $out join( ' ', @options ), "\n";
print $out $yaml->{users}->{$self}->{perl}, "\n";
close($out);

