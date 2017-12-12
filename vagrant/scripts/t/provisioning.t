use warnings;
use strict;
use Test::More tests => 30;
use Capture::Tiny 0.46 qw(capture);
use Filesys::Df;
use Fcntl ':mode';
use File::stat;
use List::BinarySearch 0.25 'binsearch';

cmp_ok( check_cpu(), '>=', 2,          'the number of CPUs is 2 or more' );
cmp_ok( check_mem(), '>=', 1568604160, 'available RAM is at least 1.5GB' );
my %partitions = (
    '/'                   => 251790,
    '/home'               => 10000000,
    '/minicpan'           => 6000000,
    '/tmp'                => 1000000,
    '/usr'                => 1467790,
    '/var'                => 497966,
    '/mnt/cpan_build_dir' => 1014455
);

for my $partition ( keys(%partitions) ) {
    my $result = df($partition);
    cmp_ok( $result->{blocks}, '>=', $partitions{$partition},
        "$partition has the expected size" );
}

isnt( check_membership( 'vagrant', 'wheel' ),
    -1, 'vagrant user is part of wheel group' );
isnt( scalar( getgrnam('testers') ), '', 'the group testers is available' );
isnt( check_membership( 'vagrant', 'testers' ),
    -1, 'vagrant user is part of testers group' );
ok( mfs_perm(), 'the MFS partition has the correct directory permissions' );

my @wanted =
  qw(bzip2 unzip wget curl bash ntp tidyp sqlite3 libxml gmp libxslt mpfr gd pkg_mgr mariadb-server mariadb-client);
my $all_pkgs_ref = list_pkgs();
for my $package (@wanted) {
    ok( find_pkg( $package, $all_pkgs_ref ), "package $package is installed" );
}

is( check_mysqld(), 'mysqld(ok)', 'mariadb server is running' );

# tries to find exactly name with binsearch, otherwise with index
sub find_pkg {
    my ( $pkg_name, $pkgs_ref ) = @_;
    my $result = binsearch { $a cmp $b } $pkg_name, @{$pkgs_ref};
    unless ( defined($result) ) {
        note("binary search failed with $pkg_name");
        for my $package ( @{$pkgs_ref} ) {
            $result = index( $package, $pkg_name );
            last if ( $result != -1 );
        }
    }
    return 1 if ( $result == 0 );
    return 0 if ( $result == -1 );
    return $result;
}

sub check_cpu {
    my ( $stdout, $stderr, $exit );
    ( $stdout, $stderr, $exit ) =
      capture { system( '/usr/sbin/sysctl', 'hw.ncpufound' ); };
    chomp($stdout);
    my $cpu_num = ( split( '=', $stdout ) )[1];
    note("Exit code is $exit, output '$stdout' and errors '$stderr'");
    return $cpu_num;
}

sub check_mem {
    my ( $stdout, $stderr, $exit );

    # hw.physmem=1568604160
    ( $stdout, $stderr, $exit ) = capture { system( '/usr/sbin/sysctl', 'hw.physmem' ); };
    chomp($stdout);
    my $mem = ( split( '=', $stdout ) )[1];
    note("Exit code is $exit, output '$stdout' and errors '$stderr'");
    return $mem;
}

sub check_membership {
    my ( $user, $group ) = @_;
    my ( $name, $passwd, $git, $members ) = getgrnam($group);
    return index( $members, $user );
}

sub mfs_perm {
    my $info = stat("/mnt/cpan_build_dir");

    # converted to octal
    my $permissions = sprintf "%04o", S_IMODE( $info->mode );
    return ( ( getgrgid( $info->gid ) eq 'testers' )
          && ( oct($permissions) == 0775 ) );
}

sub list_pkgs {
    my ( $stdout, $stderr, $exit );
    ( $stdout, $stderr, $exit ) = capture { system( '/usr/sbin/pkg_info', '-q' ); };
    note("Exit code of pkg_info is $exit, errors '$stderr'");
    my @pkgs;
    for ( split /^/, $stdout ) {
        my $line = $_;
        chomp($line);
        my @parts = split /-/, $line;
        push( @pkgs, join( '-', ( (@parts)[ 0 .. ( $#parts - 1 ) ] ) ) );
    }
    my @sorted = sort(@pkgs);
    return \@sorted;
}

sub check_mysqld {
    my ( $stdout, $stderr, $exit );
    ( $stdout, $stderr, $exit ) =
      capture { system( '/usr/sbin/rcctl', 'check', 'mysqld' ); };
    note("Exit code of pkg_info is $exit, errors '$stderr'");
    chomp($stdout);
    return $stdout;
}
