#! /usr/bin/env perl
use strict; use warnings;
use lib "../lib/";
use utf8;
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt clearScreen border loadGrf/;
use Time::HiRes qw/sleep/;

my $canvas = Term::Graille->new(
    width  => 120,
    height => 60,
    top=>4,
    left=>10,
    borderStyle => "double",
  );


my $fontName="Cinema Bold";
my $brlF = loadGrf("./fonts/$fontName.grf");

my $scrollText=" Term::Graille Scrolling Text Demo  ".$fontName."   ".
       join ("", sort keys %$brlF);

my $x=0;
for (0..length $scrollText){
  $canvas->blockBlit($brlF->{substr($scrollText,$x++,1)},55,12);
   for (0..3){
	   $canvas->scroll("l");
	   sleep .05;
	   $canvas->draw();
   }
   
   $x=0 if ($x>=length $scrollText); 
}


