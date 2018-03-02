use warnings;
use strict;
use Test::More;
use File::Spec;

opendir(my $dir, 'bin') or die "cannot read bin: $!";
my @programs = readdir($dir);
closedir($dir); 

# removing dots...
for (1..2) {
    shift(@programs);
}

plan tests => scalar(@programs);

for my $script(@programs) {
    is(system('perl', '-cw', File::Spec->catfile('bin', $script)), 0, "$script sintax is OK");
}

