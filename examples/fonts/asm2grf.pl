#! /usr/bin/env perl   
use strict; use warnings;
use lib "../../lib/";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt clearScreen border block2braille pixelAt/;
use Term::Graille::Font  qw/convertDG saveGrf loadGrf/;
use Time::HiRes qw/sleep/;
use Data::Dumper;
use utf8;

#find all fonts
opendir my $fontDir,"." or die "Unable to open directory $!;";
my @files=readdir $fontDir;
@files=map{$_=~s/.z80.asm$//;$_} grep /z80.asm$/,@files;

unless (scalar @files){
	 print "No unconverted font files found";
	 exit ;
 }
foreach my $fontName(@files){
	print "Converting font $fontName\n";
	my $grf=convertDG("$fontName.z80.asm");
	next unless $grf;
	saveGrf($grf,"$fontName.grf");
	rename "$fontName.z80.asm","$fontName.z80.asm.done"or 
	      print "Unable to rename fontfile $fontName.z80.asm $!;\n" ;
}

