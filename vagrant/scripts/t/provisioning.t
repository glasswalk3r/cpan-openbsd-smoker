use warnings;
use strict;
use Config;
use Test::More tests => 47;
use Capture::Tiny 0.46 qw(capture);
use Filesys::Df;
use Fcntl ':mode';
use File::stat;
use File::Spec;
use List::BinarySearch 0.25 'binsearch';
use Module::Version qw(get_version);

# These tests are used to validate new boxes of OpenBSD created for Vagrant
# since many of them are still done manually

cmp_ok( check_cpu(), '>=', 2,          'the number of CPUs is 2 or more' );
cmp_ok( check_mem(), '>=', 1568604160, 'available RAM is at least 1.5GB' );
my %partitions = (
    '/'                   => 240000,
    '/home'               => 10000000,
    '/minicpan'           => 5000000,
    '/tmp'                => 1000000,
    '/usr'                => 1467790,
    '/var'                => 490000,
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

my @wanted
    = qw(bzip2 unzip wget curl bash ntp tidyp libxml gmp libxslt mpfr gd mariadb-server mariadb-client);

if ( check_os_version() eq '6.0' ) {
    push( @wanted, 'sqlite' );
}
else {
    push( @wanted, 'sqlite3' );
}

my $all_pkgs_ref = list_pkgs();

for my $package (@wanted) {
    ok( find_pkg( $package, $all_pkgs_ref ),
        "package $package is installed" );
}

@wanted = (
    'Module::Version',
    'Log::Log4perl',
    'POE::Component::Metabase::Client::Submit',
    'POE::Component::Metabase::Relay::Server',
    'metabase::relayd',
    'CPAN::Smoker::Utils',
);

my $all_modules_ref = list_modules();

for my $wanted_module (@wanted) {
    ok( ( binsearch { $a cmp $b } $wanted_module, @{$all_modules_ref} ),
        "$wanted_module is installed" );
}

note('Specific for modules that are installed without passing the tests');
my $broken = 'POE::Component::SSLify';
ok( get_version($broken), "$broken is installed even though fail the tests" );

is( check_mysqld(), 'mysqld(ok)', 'mariadb server is running' );

my @expected = (
    'performance_schema',
    'performance-schema-instrument',
    'performance-schema-consumer-events-stages-current',
    'performance-schema-consumer-events-stages-history',
    'performance-schema-consumer-events-stages-history-long'
);
my $enabled_regex = qr/ON/;
my $found_ref     = read_mysql_perf();

for my $directive (@expected) {
    my $result = exists( $found_ref->{$directive} );
    ok( $result, "$directive directive is available in /etc/my.cnf" )
        or diag( explain($found_ref) );
SKIP: {
        skip "directive is not even available in /etc/my.cnf", 1
            unless $result;
        like( $found_ref->{$directive},
            $enabled_regex,
            "directive $directive is enabled on /etc/my.cnf" );
    }
}

isnt( read_sshd_conf(), 'yes', 'sshd config PermitRootLogin is disabled' );

# tries to find exact name with binsearch(), otherwise tries with index()
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

sub check_os_version {
    my ( $stdout, $stderr, $exit );
    ( $stdout, $stderr, $exit )
        = capture { system( '/usr/bin/uname', '-r' ); };
    chomp($stdout);
    note("Exit code is $exit, output '$stdout' and errors '$stderr'");
    return $stdout;
}

sub check_cpu {
    my ( $stdout, $stderr, $exit );
    ( $stdout, $stderr, $exit )
        = capture { system( '/usr/sbin/sysctl', 'hw.ncpufound' ); };
    chomp($stdout);
    note("Exit code is $exit, output '$stdout' and errors '$stderr'");
    my $cpu_num = ( split( '=', $stdout ) )[1];
    return $cpu_num;
}

sub check_mem {
    my ( $stdout, $stderr, $exit );

    # hw.physmem=1568604160
    ( $stdout, $stderr, $exit )
        = capture { system( '/usr/sbin/sysctl', 'hw.physmem' ); };
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
    return (   ( getgrgid( $info->gid ) eq 'testers' )
            && ( oct($permissions) == 0775 ) );
}

sub list_pkgs {
    my ( $stdout, $stderr, $exit );
    ( $stdout, $stderr, $exit )
        = capture { system( '/usr/sbin/pkg_info', '-q' ); };
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
    ( $stdout, $stderr, $exit )
        = capture { system( '/usr/sbin/rcctl', 'check', 'mysqld' ); };
    note("Exit code of pkg_info is $exit, errors '$stderr'");
    chomp($stdout);
    return $stdout;
}

sub read_mysql_logging {
    my $cfg    = '/etc/my.cnf';
    my $regex1 = qr/log-bin/;
    my $regex2 = qr/binlog_format/;
    my $regex3 = qr/expire_log_days/;
    my @values;
    open( my $in, '<', $cfg ) or die "Cannot read $cfg: $!";

    while (<$in>) {
        if ( ( $_ =~ $regex1 ) or ( $_ =~ $regex2 ) or ( $_ =~ $regex3 ) ) {
            my $line = $_;
            chomp($line);
            push( @values, $line );
        }
    }

    close($in);
    return \@values;
}

sub read_mysql_perf {
    my $cfg = '/etc/my.cnf';
    open( my $in, '<', $cfg ) or die "Cannot read $cfg: $!";
    my %perf_settings;
    my $regex = qr/^performance/;
    while (<$in>) {
        if ( $_ =~ $regex ) {
            my $line = $_;
            chomp($line);

            # required to limit to 2 since there are value with "="
            my ( $directive, $value ) = split( /=/, $line, 2 );
            $perf_settings{$directive} = $value;
        }
    }
    close($in);
    return \%perf_settings;
}

sub read_sshd_conf {
    my $conf  = '/etc/ssh/sshd_config';
    my $regex = qr/^PermitRootLogin\s(\w+)/;
    open( my $in, '<', $conf ) or die "Cannot read $conf: $!";
    my $value;

    while (<$in>) {
        if ( $_ =~ $regex ) {
            chomp;
            $value = $1;
            last;
        }
    }

    close($in);
    return $value;
}

# returns all modules names installed by checking perllocal.pod file
# returns an sorted array reference
sub list_modules {
    my @possible_locations = (
        File::Spec->catfile( ( $Config{archlib} ), 'perllocal.pod' ),
        File::Spec->catfile(
            (
                $ENV{HOME},      'perl5',
                'lib',           'perl5',
                'amd64-openbsd', 'perllocal.pod'
            )
        )
    );
    my @data;

    foreach my $file (@possible_locations) {
        if ( -f $file ) {
            open( my $in, "<", $file ) or die "Cannot read $file: $!";
            @data = <$in>;
            close($in);
            chomp(@data);
        }
        else {
            note("$file is not available");
        }
    }

    my @temp = grep( /^=head2.*\:\sC<Module>/, @data );
    my @new;

    for my $module_line (@temp) {

   # =head2 Sat May 25 19:37:40 2019: C<Module> L<Capture::Tiny|Capture::Tiny>
        my $t = ( ( split( /\|/, $module_line ) ) )[1];
        die "Could not extract a value from $module_line"
            unless ( defined($t) );

        # removes ">" from the Pod line
        chop $t;
        push( @new, $t );
    }

    @new = sort(@new);
    return \@new;

}

