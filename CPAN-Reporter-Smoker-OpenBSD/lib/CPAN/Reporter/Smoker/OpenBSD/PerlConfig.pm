package CPAN::Reporter::Smoker::OpenBSD::PerlConfig;

use strict;
use warnings;
use Config;
use Hash::Util qw(lock_hash);

# VERSION

sub new {
    my $class = shift;
    my $self  = {
        osname   => $Config{osname},
        archname => $Config{archname}
    };

    if ( defined( $Config{useithreads} ) ) {
        $self->{useithreads} = 1;
    }
    else {
        $self->{useithreads} = 0;
    }

    bless $self, $class;
    lock_hash( %{$self} );
    return $self;
}

sub dump {
    my $self    = shift;
    my %attribs = %{$self};

    if ( $self->{useithreads} ) {
        $attribs{useithreds} = 'define';
    }
    else {
        delete( $attribs{useithreads} );
        $attribs{no_useithreads} = 'define';
    }

    return \%attribs;
}

1;
