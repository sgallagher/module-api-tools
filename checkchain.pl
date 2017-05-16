#!/usr/bin/perl
use strict;
use warnings;
use autodie;
use Getopt::Std;

sub HELP_MESSAGE {
    print "Usage: ./checkchain.pl -a <arch> build\n";
    exit 1;
}

my @builds;
my %arches;
open my $fh, '<', './arches';
{
    local $/ = undef;
    %arches = map { /^([^=]+)=(.*)$/; $1 => $2 } split "\n", <$fh>;
}
close $fh;
my %opts;
getopts('a:', \%opts);
my $arch = $opts{a} or HELP_MESSAGE;
exists $arches{$arch} or HELP_MESSAGE;
my $param = shift @ARGV or HELP_MESSAGE;

open $fh, '<', "/home/contyk/m/base-runtime/api.${arch}";
while (<$fh>) {
    chomp;
    next unless /^(\*|\+|-|\t)/;
    push @builds, $_;
}
close $fh;

my $repo = $arches{$arch};
#my $output = `dnf repoquery --repofrompath=local,${repo} --repo=local --qf='\%{name}-\%{version}-\%{release}.\%{arch}' --arch ${arch},noarch --requires --resolve ${param} 2>/dev/null`;
my $output = `repoquery --repofrompath=local,${repo} --repoid=local --qf='\%{name}-\%{version}-\%{release}.\%{arch}' --arch ${arch},noarch --requires --resolve ${param} 2>/dev/null`;

OUTER: for my $dep (split /\n/, $output) {
    next OUTER if $dep =~ /^Added local repo from/;
    # Let's weaken it because repodata can be off
    $dep =~ s/-[^-]+-[^-]+$//;
    for my $build (@builds) {
        if ($build =~ /\t\Q${dep}\E-[^-]+-[^-]+\.rpm/) {
            print "${build}\n";
            next OUTER;
        }
    }
    print "ERROR:\t$dep not found in the set!\n";
}
