#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Std;

# see also vagrant/packer.json for the creation of the $opts{b} directory

our %opts;
getopts('b:s:', \%opts);

die '-b <cpan_build_dir> is required' unless ((exists($opts{b})) and ($opts{b} ne ''));
die '-s <MFS size in Mb> is required' unless ((exists($opts{s})) and ($opts{s} ne ''));

my $fstab = '/etc/fstab';
open( my $in, '<', $fstab ) or die "Cannot read $fstab: $!\n";
my @data = <$in>;
close($in);
my $has_mfs = 0;
open( my $out, '>', $fstab ) or die "Cannot write to $fstab: $!\n";

for my $line (@data) {
    chomp($line);
    my @parts = split( /\s/, $line );
    $has_mfs = 1 if (($parts[1] eq $opts{b}) and ($parts[2] eq 'mfs' ));

    if (   ( $parts[1] eq '/home' )
        or ( $parts[1] eq '/minicpan' )
        or ( $parts[1] eq '/tmp' ) )
    {
        $parts[3] = "$parts[3],softdep,noatime";
    }

    print $out join( ' ', @parts ), "\n";
}

unless ($has_mfs) {
    my @parts = ('swap', $opts{b}, 'mfs', "rw,async,nodev,nosuid,-s=$opts{s}m", '0', '0');
    print $out join( ' ', @parts ), "\n";
}

close($out);
