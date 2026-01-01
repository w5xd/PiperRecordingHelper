#!/usr/bin/perl
use strict;
use warnings;

#rotate through phonetics for A-Z and 0-9 in 4 word combinations
#

my $ltr1 = 0;
my $ltr2 = 1;
my $ltr3 = 2;
my $dig1 = 0;

my $alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
my $digits = "0123456789";

my @itu=(
"Alpha",
"Bravo",
"Charlie",
"Delta",
"Echo",
"Foxtrot",
"Golf",
"Hotel",
"India",
"Juliett",
"Kilo",
"Leema",
"Mike",
"November",
"Oscar",
"Papa",
"Quebec",
"Romeo",
"Sierra",
"Tango",
"Uniform",
"Victor",
"Whiskey",
"X-ray",
"Yankee",
"Zulu");

my @dxp = (
"america",
"boston",
"canada",
"denmark",
"england",
"france",
"germany",
"honolulu",
"italy",
"japan",
"kilowatt",
"london",
"mexico",
"norway",
"ontario",
"pacific",
"quebec",
"radio",
"santiago",
"tokyo",
"united",
"victoria",
"washington",
"x-ray",
"yokohama",
"zanzibar");

my @dignames = (
	"zero",
	"one",
	"two",
	"three",
	"four",
	"five",
	"six",
	"seven",
	"eight",
	"nine",
);


for (my $i = 1; $i <= 26; $i++) {
	print "generate|".lc($itu[$ltr1]) . ' ' .
		$dignames[$dig1] . ' '.
		lc($itu[$ltr2]) . ' ' .
		lc($itu[$ltr3]) . "\n";
	print "generate|". lc($dxp[$ltr1]) . ' ' .
		$dignames[$dig1] . ' '.
		lc($dxp[$ltr2]) . ' ' .
		lc($dxp[$ltr3]) . "\n";
	$ltr1 += 1; $ltr2 += 1; $ltr3 += 1;
	$ltr1 = 0 if ($ltr1 >= 26);
	$ltr2 = 0 if ($ltr2 >= 26);
	$ltr3 = 0 if ($ltr3 >= 26);
	$dig1 += 1;
	$dig1 = 0 if ($dig1 >= 10);
}
