use warnings;
use strict;
use Test::More tests => 2;
use YAML::XS qw(LoadFile Dump);
use CPAN::Reporter::Smoker::OpenBSD qw(block_distro);
use File::Spec;

my $data_ref = block_distro('AWWAIID/Devel-ebug', 'cperl-5.24.3', 'Tests hang smoker');
ok(delete($data_ref->{full_path}), 'can remove full_path property');
my $expected = LoadFile(File::Spec->catfile('t', 'distroprefs','AWWAIID.Devel-ebug.yml'));

is_deeply($data_ref, $expected, 'block_distro works as expected');

