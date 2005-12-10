#!/usr/bin/perl
#
# Makefile.PL
#

use ExtUtils::MakeMaker;

my %params = 
(
 NAME => 'Curses::Menu',
 VERSION_FROM => 'lib/Curses/Menu.pm',
 PREREQ_PM => {
     Curses => 0,
 },
 
);

WriteMakefile(%params);
