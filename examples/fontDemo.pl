#! /usr/bin/env perl
use strict; use warnings;
use lib "../lib/";
use utf8;
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt clearScreen border/;
use Term::Graille::Font  qw/convertDG saveGrf loadGrf fontWrite/;
use Time::HiRes qw/sleep/;


my $canvas = Term::Graille->new(
    width  => 120,
    height => 60,
    top=>4,
    left=>10,
    borderStyle => "double",
  );

my @fontNames=("Area51","Cinema Bold","Mutual","Everest","ZX Times");
my @fonts = map {my $f=loadGrf("./fonts/$_.grf");$f} @fontNames;
my @texts = map {" $_->{info} 8x8 Fonts imported from https://damieng.com/typography/zx-origins/ "} @fonts;

my @pointers=(0) x scalar @fontNames;

fontWrite($canvas,$fonts[0],10,8,"Font Demo");
$canvas->textAt(30,25,"Mixed text is also possible");
$canvas->textAt(30,22,"printable directly on canvas");

$canvas->draw();
sleep 5;

for (0..100){
  for my $fn (0..$#fontNames){
	 fontWrite($canvas,$fonts[$fn],55,1+$fn*3,substr($texts[$fn],$pointers[$fn]++,1));
	  $pointers[$fn]=0 if ($pointers[$fn]>=length $texts[$fn]); 
  }
  
	   for (0..3){
		   $canvas->scroll("l");
		   sleep .05;
		   $canvas->draw();
	   }
	   
   }
	


