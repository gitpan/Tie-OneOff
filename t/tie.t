#!./perl

use strict;
use warnings;

print "1..3\n";

my $testno;

sub t ($) {
    print "not " unless shift;
    print "ok ",++$testno,"\n";
}

require Tie::OneOff;

tie my %REV, 'Tie::OneOff' => {
    FETCH => sub { reverse shift },
};

t ($REV{olleH} eq 'Hello' );

tie my %REV2, 'Tie::OneOff' => sub {
    reverse shift;
};

t ($REV2{olleH} eq 'Hello' );


sub make_counter {
    my $step = shift;
    my $i = 0;
    tie my $counter, 'Tie::OneOff' => {
	BASE => \$i, # Implies: STORE => sub { $i = shift }
	FETCH => sub { $i += $step },
    };
    \$counter;
}

my $c1 = make_counter(1);
my $c2 = make_counter(2);
$$c2 = 10;
t("X $$c1 $$c2 $$c2 $$c2 $$c1 $$c1" eq 'X 1 12 14 16 2 3');
