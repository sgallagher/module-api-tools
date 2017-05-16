#!/usr/bin/perl
use strict;
use warnings;
use autodie;
use Getopt::Std;

sub HELP_MESSAGE {
    print "Usage: add-api.pl -a arch\n";
    exit 1;
}

my @arches;
open my $fh, '<', './arches';
{
    local $/ = undef;
    @arches = map { s/^([^=]+).*$/$1/r } split "\n", <$fh>;
}
close $fh;
my %opts;
getopts('a:', \%opts);
my $arch = $opts{a} or HELP_MESSAGE;
{
    my %sa = map { $_ => 1 } @arches;
    exists $sa{$arch} or HELP_MESSAGE;
}

my $changed;
my $pass = 1;
do {
    print "PASS $pass\n";
    $changed = 0;
    open my $fh, '<', "./api.${arch}";
    my $api;
    {
        local $/ = undef;
        $api = <$fh>;
    }
    close $fh;
    for (split "\n", $api) {
        next unless /^\t(.*)\.rpm$/;
        my $pkg = $1;
        $pkg =~ /^(.*)-[^-]+-[^-]+$/;
        my $shortpkg = $1;
        my $out = `./checkchain.pl -a${arch} ${shortpkg}`;
        unless ($out =~ /^(\t|E|-)/smg) {
            print "Updating ${shortpkg}...\n";
            `sed -e 's/^\\(\\t${pkg}\\.rpm\\)/+\\1/' -i api.${arch}`;
            $changed = 1;
        }
    }
    $pass++;
} while ($changed);
