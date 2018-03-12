#!perl

use warnings;
use strict;
use YAML::XS qw(LoadFile);
use Try::Tiny;
use File::Spec;

my $dir_path = 'prefs';
opendir(my $dir, $dir_path) or die "Cannot read $dir_path: $!";
my @yaml_files = readdir($dir);
close($dir);

shift(@yaml_files);
shift(@yaml_files);
my $error_counter = 0;

for my $yaml_file(@yaml_files) {

    try {
        LoadFile(File::Spec->catfile($dir_path, $yaml_file));
    } catch {
        warn "Caught a problem to parse $yaml_file: $_";
        $error_counter++;
    };
}

print "Finished, found a total of $error_counter errors.\n";
