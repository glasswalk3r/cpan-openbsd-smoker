use warnings;
use strict;
use Test::More;
use YAML::XS qw(LoadFile Dump);
use CPAN::Reporter::Smoker::OpenBSD qw(block_distro);
use File::Spec;
use CPAN;
use CPAN::HandleConfig;

my $total_tests = 2;
plan tests => $total_tests;

SKIP: {

    skip "Can only run those tests with cpan client, currently testing with cpanplus, version $ENV{PERL5_CPANPLUS_IS_VERSION}",
      $total_tests
      unless (not(exists($ENV{PERL5_CPANPLUS_IS_VERSION})));

    CPAN::HandleConfig->load;
    my $prefs_dir = $CPAN::Config->{prefs_dir};

    skip "prefs_dir '$prefs_dir' is not available for reading/writing",
      $total_tests
      unless ( -d $prefs_dir && -r $prefs_dir && -w $prefs_dir );

    my $cpan_id = 'ARFREITAS';
    my $distro_name = gen_random($cpan_id); 
    my $data_ref =
      block_distro( $distro_name, 'perl-5.24.3', 'Tests hang smoker' );
    ok( delete( $data_ref->{full_path} ), 'can remove full_path property' );
    my $expected = LoadFile(
        File::Spec->catfile( 't', 'distroprefs', 'ARFREITAS.Foo-Bar.yml' ) );
    is_deeply( $data_ref, $expected, 'block_distro works as expected' );
}

sub gen_random {
    my $cpan_id = shift;
    my @chars = ("A".."Z", "a".."z", 0..9);
    my $string .= $chars[int rand scalar @chars] for 1..20;
    return "$cpan_id/$string";
}
