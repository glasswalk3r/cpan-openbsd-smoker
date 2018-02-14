#!/usr/bin/perl
use warnings;
use strict;
use YAML::XS qw(LoadFile);
use File::Temp qw(tempfile);
use Cwd;
use constant GROUP              => 'testers';
use constant IDEMPOTENT_CONTROL => "/var/vagrant_provision_users";

my $CPAN_MIRROR      = $ARGV[0];
my $CONFIG_YAML      = $ARGV[1];
my $BUILD_DIR        = $ARGV[2];
my $PROCESSORS       = $ARGV[3];
my $USE_LOCAL_MIRROR = $ARGV[4];
my $PREFS_DIR        = $ARGV[5];

my $now = localtime(time);
print "Starting provisioning at $now\n";
print 'Using', IDEMPOTENT_CONTROL, ' to control provisioning', "\n";
my $yaml = Load($CONFIG_YAML);

if ( -f IDEMPOTENT_CONTROL ) {
    print "All implemented, exiting...\n";
    exit 0;
}
else {
    print "Expanding the file system again for /home...\n";
    my $previous = getcwd();
    chdir '/home';
    system( 'dd', 'if=/dev/zero', 'of=bigemptyfile', 'bs=1000',
        'count=5000000' );
    unlink 'bigemptyfile';
    chdir $previous;
    my $config_script = $yaml->{config_script};

# WORKAROUND: this is to avoid issues with strings containing spaces that might be interpreted
# incorrectly by Bash, config_user.sh should read it from a file
    my $reports_from_config = '/tmp/reports_from.cfg';
    open( my $out, '>', $reports_from_config )
      or die "Cannot create $reports_from_config: $!";
    print $out $yaml->{reports_from};
    close($out);

    for my $user ( @{ $yaml->{users} } ) {
        print "Adding user $user to ", GROUP, "group\n";

        # password created with:
        # encrypt -c default vagrant
        my $password =
          '$2b$10$jwgI5jv2x5d9VFFnU.I9s..f8ndKQqsBRb8wB/LapqqX.jKpt2/9q';
        system( "adduser -shell bash -batch $user " . GROUP . " $user" );
        mariadb_add_user($user);
        my $old_dir = getcwd();

        if ( -f $config_script ) {
            print "Configuring user with $config_script\n";

            # required to avoid permission errors
            chdir "/home/$user";
            my $params;

            if ( $USE_LOCAL_MIRROR eq 'yes' ) {
                $params =
"file:///minicpan $user $BUILD_DIR $reports_from_config $PREFS_DIR";
                chmod 0770, '/minicpan';
            }
            else {
                $params =
"${CPAN_MIRROR} ${user} ${BUILD_DIR} ${reports_from_config} ${PREFS_DIR}";
            }

# this script expects too many parameters to be practical to use with parallel... and should execute fast enough
            print "Executing 'su -l $user -c \"$config_script $params\"'\n";
            system("su -l $user -c '$config_script $params'");
        }
        else {
            print "'$config_script' not available, cannot continue\n";
            opendir( DIR, '/tmp' ) or die "Cannot list the /tmp directory: $!";
            while (<readdir(DIR)>) {
                print $_, "\n";
            }
            close(DIR);
            exit 1;
        }

        chdir $old_dir;
    }

    print
      "Installing now the perl and required modules for the given users...\n";
    my $start = time();

    # this is an attempt to speed up things
    print
      "Installing a new perl and required modules for users with parallel\n";

#    parallel --link '/tmp/run_user_install.sh {} {#}' ::: ${USER_1} ${USER_2} ::: ${USERS[${USER_1}]} ${USERS[${USER_2}]}
    my $total = time() - $start;
    print "Provisioning of users took $total seconds\n";
    unlink $reports_from_config;
    open( my $idem, '>', IDEMPOTENT_CONTROL )
      or die 'Cannot create ' . IDEMPOTENT_CONTROL . ": $!";
    print $idem, localtime(time);
    close($idem);
}

$now = localtime(time);
print "Finished provisioning at $now\n";

sub mariadb_user {
    my $user = shift;
    print "Adding $user to the local MariaDB for DBD::mysql extended tests";
    my ( $fh, $filename ) = tempfile( UNLINK => 0 );
    print $fh <<BLOCK;
grant all privileges on test.* to '$user'\@'localhost';
grant select on performance_schema.* to '$user'\@'localhost';
BLOCK
    close($fh);

    # ugly, but MariaDB should be running for localhost only
    system("mysql -u root -pvagrant < $filename");
    unlink $filename;
}
