#!/usr/bin/perl
use warnings;
use strict;
use Test::Reporter;
use Test::Reporter::Transport::Socket;
use Term::ProgressBar;

my $sender = Test::Reporter->new(
    transport => 'Socket',
    transport_args => [
        host => '192.168.1.118',
        port => 8080 
    ],
);
my $dir = '/home/arfreitas/smoker';
opendir(DIR,$dir) or die "cannot read $dir: $!";
my @files = readdir(DIR);
shift(@files);
shift(@files);
close(DIR);
chdir($dir);

my $progress = Term::ProgressBar->new( { count => scalar(@files) } );
my $sent_counter = 0;

foreach my $report(@files) {
    if (-z $report) {
        warn "report $report has zero bytes lenght, skipping...\n";
        next;
    }
    if ( $sender->read($report)->send ) {
        $sent_counter++;
	unlink $report or warn "failed to remove $report: $!";
    } else {
	die $sender->errstr();
    }
    $progress->update( $sent_counter );
}

$progress->update( scalar(@files) );

