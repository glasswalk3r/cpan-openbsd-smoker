#!/usr/bin/env perl

# Downloads a ISO image from OpenBSD based on command line arguments

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use DateTime::TimeZone;

{

    package OpenBSD::ISO;

    use warnings;
    use strict;
    use Carp qw(confess);

    # TODO: detect OS and configure the path accordingly
    use constant WGET => '/usr/bin/wget';

    use constant SHA256_FILENAME  => 'SHA256';
    use constant SHA_SIG_FILENAME => 'SHA256.sig';

    sub new {
        my ( $class, $data_ref ) = @_;
        my @required = qw(mirror architecture version timezone);
        my $self     = {};

        my $ref_type = ref($data_ref);

        confess
          "Configuration parameter must be a hash reference, not \"$ref_type\""
          unless ( $ref_type eq 'HASH' );

        for my $attrib (@required) {
            if ( not( exists( $data_ref->{$attrib} ) ) ) {
                confess(
"The attribute \"$attrib\" is required when creating an instance"
                );
            }

            confess "$attrib must have a value"
              unless ( $data_ref->{$attrib}
                and ( $data_ref->{$attrib} ne '' ) );

            $self->{$attrib} = $data_ref->{$attrib};
        }

        my $stripped_version = $data_ref->{version};
        $stripped_version =~ tr/.//d;

        $self->{stripped_version} = $stripped_version;
        $self->{base_url}         = sprintf( 'https://%s/pub/OpenBSD/%s',
            $data_ref->{mirror}, $data_ref->{version} );
        $self->{public_key} = "openbsd-$stripped_version-base.pub";
        $self->{iso_image}  = "install$stripped_version.iso";
        $self->{timezone}   = $data_ref->{timezone};

        bless $self, $class;
        $self->_define_signify();
        return $self;
    }

    sub _define_signify {
        my $self = shift;

        if ( $^O eq 'openbsd' ) {
            $self->{signify} = 'signify';
        }
        else {
            $self->{signify} = 'signify-openbsd';
        }
    }

    sub _get_iso {
        my $self = shift;
        my $url  = join( '/',
            ( $self->{base_url}, $self->{architecture}, $self->{iso_image} ) );
        my @args = ( WGET, '--quiet', '--continue', $url );
        system(@args) or confess "execution failed: $?";
    }

    sub _get_public_key {
        my $self = shift;
        my $url  = join( '/', ( $self->{base_url}, $self->{public_key} ) );
        my @args = ( WGET, '--quiet', '--continue', $url );
        system(@args) or confess "@args execution failed: $?";
    }

    sub _get_sha {
        my $self  = shift;
        my @files = ( SHA256_FILENAME, SHA_SIG_FILENAME );

        for my $file (@files) {
            my $url =
              join( '/', ( $self->{base_url}, $self->{architecture}, $file ) );
            my @args = ( WGET, '--quiet', '--continue', $url );
            system(@args) or confess "@args execution failed: $?";
        }
    }

    sub _validate {
        my $self = shift;
    }

    sub download {
        my ( $self, $root_path ) = @_;
        self->_get_iso();
        self->_get_public_key();
        self->_get_sha();
    }
}

my $arch;
my $openbsd_version;
my $help = 0;
my $man  = 0;
my $mirror;
my $timezone;

GetOptions(
    'arch=s'     => \$arch,
    'version=s'  => \$openbsd_version,
    'mirror=s'   => \$mirror,
    'timezone=s' => \$timezone,
    'help|?'     => \$help,
    'man'        => \$man
) or pod2usage(2);

pod2usage(1)                              if $help;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;

pod2usage(1) unless ($arch);
pod2usage(1) unless ($openbsd_version);

$mirror   = 'https://cdn.openbsd.org/' unless ($mirror);
$timezone = DateTime::TimeZone->new( name => 'local' )->name()
  unless ($timezone);

my $downloader = OpenBSD::ISO->new(
    {
        mirror       => $mirror,
        architecture => $arch,
        version      => $openbsd_version,
        timezone     => $timezone
    }
);

__END__

=pod

=encoding utf-8

=head1 NAME

get_iso.pl - A CLI to download OpenBSD ISO images

=head1 SYNOPSIS

get_iso.pl --arch=i386 --version=7.3 --timezone=America/Sao_Paulo

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-arch>

Processor architecture (i386 or amd64) of the image to download.

=item B<-version>

The OpenBSD version you want to download the ISO image.

=item B<-mirror>

The OpenBSD mirror you want to use the download. If not provided, it will
default to https://cdn.openbsd.org/.

=item B<-timezone>

Specific to the usage with Packer, in order to setup the VM image time zone.

If not provided, it will be default to your local time zone, as defined in the
operational system configuration.

=back

=head1 DESCRIPTION

C<get-iso.pl> will download OpenBSD ISO images based on given parameters and
validate them by using SHA256 hashes and GnuPG signatures from OpenBSD team.

Given the parameters, it will create on the current directory a directory tree
like the one shown below:

    ISO
    └── 7.4
        ├── amd64
        │   ├── install74.iso
        │   ├── openbsd-74-base.pub
        │   ├── SHA
        │   ├── SHA256
        │   └── SHA256.sig
        └── i386
            ├── install74.iso
            ├── openbsd-74-base.pub
            ├── SHA
            ├── SHA256
            └── SHA256.sig

C<get-iso.pl> will also generate a variables file to be used together with
L<Packer|https://www.packer.io/> and the C<packer.pkr.hcl> configuration file
that ships together with this CLI.

=head1 REQUIREMENTS

The follow programs are necessary to be installed because this CLI will use
system exec call to execute them:

=over

=item B<wget>

In order to download the images with proper resume download in the case of
failures.

=item B<signify>

Or signify-openbsd (if you're on Linux) in order to check the signatures of
the ISO image.

=back

=cut
