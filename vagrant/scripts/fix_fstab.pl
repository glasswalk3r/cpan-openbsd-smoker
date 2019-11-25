#!/usr/bin/env perl
use warnings;
use strict;

my $fstab = '/etc/fstab';

open( my $in, '<', $fstab ) or die "Cannot read $fstab: $!\n";
my @data = <$in>;
close($in);

open( my $out, '>', $fstab ) or die "Cannot write to $fstab: $!\n";
for my $line (@data) {
    chomp($line);
    my @parts = split( /\s/, $line );

    if (   ( $parts[1] eq '/home' )
        or ( $parts[1] eq '/minicpan' )
        or ( $parts[1] eq '/tmp' ) )
    {
        $parts[3] = "$parts[3],softdep,noatime";
    }

    print $out join( ' ', @parts ), "\n";
}

close($out);
