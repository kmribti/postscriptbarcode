#!/usr/bin/perl -Tw

#
#  cat gs1-format-spec.txt | ./build-gs1-syntax-dict.pl
#

use strict;

print "    /gs1syntax <<\n";
print "\n";

my $ai_rx = qr/
    (
        (0\d)
    |
        ([1-9]\d{1,3})
    )
/x;

my $ai_rng_rx = qr/${ai_rx}(-${ai_rx})?/;

my $flags_rx = qr/[\*]+/;

my $type_rx = qr/
    [XNC]
    (
        ([1-9]\d?)
        |
        (0?\.\.[1-9]\d?)
    )
/x;

my $comp_rx = qr/
    ${type_rx}
    (,\w+)*
/x;

my $spec_rx = qr/
    ${comp_rx}
    (\s+${comp_rx})*
/x;

my $title_rx = qr/\S.*\S/;

my $lastspecstr = '';
my $first = 1;

while (<>) {

    chomp;

    $_ =~ /^#/ and next;
    $_ =~ /^\s*$/ and next;

    # 999  *  N13,csum,key X0..17  # EXAMPLE TITLE
    $_ =~ /
        ^
        (?<ais>${ai_rng_rx})
        (
            \s+
            (?<flags>${flags_rx})
        )?
        \s+
        (?<spec>${spec_rx})
        (
            \s+
            \#
            \s
            (?<title>${title_rx})
        )?
        \s*
        $
    /x or die;

    my $ais = $+{ais};
    my $flags = $+{flags} || '';
    my $spec = $+{spec};
    my $title = $+{title} || '';

    my @elms = split(/\s+/, $spec);

    my $specstr = "        [\n";
    foreach (@elms) {

        (my $cset, my $checks) = split(',', $_, 2);

        ($cset, my $len) = $cset =~ /^(.)(.*)$/;
        $len = "1$len" if $len =~ /^\.\./;
        $len = "$len..$len" if $len !~ /\./;
        (my $min, my $max) = $len =~ /^(\d+)\.\.(\d+)$/;
        $min = sprintf('% 2s', $min);
        $max = sprintf('% 2s', $max);

        $checks=$checks || '';
        my @checks=split(',', $checks);
        $checks='';
        $checks .= "/lint$_ " foreach @checks;
        $checks =~ s/^\s+|\s+$//g;
        $checks = " $checks " unless $checks eq '';

        $specstr .= "        << /cset /$cset  /min $min  /max $max  /check [$checks] >>\n";

    }
    $specstr .= "        ]\n";

    $ais = "$ais-$ais" if $ais !~ /-/;
    (my $aimin, my $aimax) = $ais =~ /^(\d+)-(\d+)$/;

    if ($specstr ne $lastspecstr) {
        print "        pop\n\n" if $first != 1;
        print $specstr;
    }

    print "        ($_) exch dup\n" for ($aimin..$aimax);

    $lastspecstr = $specstr;

    $first = 0;

}

print "        pop\n";
print "\n";
print "    >> def\n"
