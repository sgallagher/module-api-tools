#!/usr/bin/perl
use strict;
use warnings;
use autodie;

die "Usage: ./generate-api.pl <builds>\n" unless @ARGV;


my %builds;
my @arches;
open my $fh, '<', './arches';
{
    local $/ = undef;
    @arches = map { /^([^=]+)/; $1 } split "\n", <$fh>;
}
close $fh;
my $arches = join('|', @arches);

for my $build (@ARGV) {
    $build =~ s/^\d+:(.+)\.src$/$1/;
    $builds{$build} = [ map { s/^.*\///r } grep { /\.(?:noarch|${arches})\.rpm$/ && ! /debuginfo/ } split /\n/, `koji buildinfo ${build}` ];
}

for my $arch (@arches) {
    open $fh, '>', "./api.${arch}";
    for my $build (sort keys %builds) {
        print { $fh } "$build\n";
        for my $rpm (sort @{ $builds{$build} }) {
            print { $fh } "\t$rpm\n" if $rpm =~ /\.(?:noarch|${arch})\.rpm$/;
        }
    }
    close $fh;
}
