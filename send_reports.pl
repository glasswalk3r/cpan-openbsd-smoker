#!/usr/bin/perl
use 5.012;
use warnings;
use strict;
use Test::Reporter;
use Test::Reporter::Transport::Socket;
use Term::ProgressBar;
use Getopt::Std;
use File::Spec;

my %opts;
getopts('pr:h:', \%opts);

die 'the parameter -r is required' unless (exists($opts{r}));
die 'the parameter -h is required' unless (exists($opts{h}));

my $sender = Test::Reporter->new(
    transport => 'Socket',
    transport_args => [
        host => $opts{h},
        port => 8080 
    ],
);
my $sent_counter = 0;
my $files_ref = read_reports(\%opts);
my $progress = Term::ProgressBar->new( { count => scalar( @{$files_ref} ) });

foreach my $report(@{$files_ref}) {

    if (-z $report) {
        warn "report $report has zero bytes lenght, skipping...\n";
        next;
    }

    $progress->update( $sent_counter ) if ( submit( $sender, $report ) );
}

#$progress->update( scalar(@files) );

sub submit {
    my ($sender,$report) = @_;

    if ( $sender->read($report)->send ) {
        $sent_counter++;
	unlink $report or warn "failed to remove $report: $!";
        return 1;
    } else {
	die $sender->errstr();
    }

}

sub read_reports {
    my ($opts_ref) = @_;
    my $dir = $opts_ref->{r};
    opendir(my $input,$dir) or die "cannot read $dir: $!";
    my $passed_regex = qr/^pass/;
    my @files;
   
    if ( exists($opts_ref->{p}) ) {
        print "Sending only reports that passed...\n";
        while(readdir($input)) {
            push(@files, File::Spec->catfile($dir,$_)) if ( $_ =~ $passed_regex );
        }
    } else {
        while(readdir($input)) {
            push(@files, File::Spec->catfile($dir,$_));
        }
        # removing "dot" files
        shift(@files);
        shift(@files);
    }

    close($input);
    return \@files;
}
