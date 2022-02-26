#!/usr/bin/env perl

# This software is copyright (c) 2017 of Alceu Rodrigues de Freitas Junior,
# arfreitas@cpan.org
#
# This file is part of CPAN OpenBSD Smoker.
#
# CPAN OpenBSD Smoker is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CPAN OpenBSD Smoker is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CPAN OpenBSD Smoker.  If not, see http://www.gnu.org/licenses.

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
