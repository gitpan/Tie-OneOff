#!/usr/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION_FROM    => "lib/Tie/OneOff.pm",
    NAME            => "Tie::OneOff",
    PREREQ_PM       => { 'Scalar::Util' => '1.07', },
    DISTNAME        => "Tie-OneOff",
);
