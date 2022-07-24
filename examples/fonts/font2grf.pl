#! /usr/bin/env perl   
use strict; use warnings;
#use lib "../../lib/";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt clearScreen border block2braille pixelAt loadGrf/;
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
	open my $zxFont,"<:utf8","$fontName.z80.asm" or 
	      print "Unable to open fontfile $fontName.z80.asm $!;\n"  && next;
	my $font="";
	$font.=$_ while(<$zxFont>);
	close $zxFont;	

	$font=~s/^[\s\t]?;([^\n]+)/{/g;
	my $info=$1;
	$font=~s/defb &/[[0x/g;
	$font=~s/,&/],[0x/g;
	$font=~s/ ; /]],# /g;
	$font=~s/\s([^#\s]*)#\s(.)/  '$2'=>$1/g;
	$font=~s/\'\'\'/\"\'\"/g;
	$font=~s/\'\\\'/\'\\\\\'/g;
	$font.="\n}\n";
	#	print $font;
	my $binFont=eval($font);
	my $grlFont={};
	for (keys %$binFont){
		use utf8;
		$grlFont->{$_}=block2braille($binFont->{$_}) ;
	}
	$grlFont->{info}=$info||"";
	
	
   my $output=Dumper([$grlFont])=~ s/\\x\{([0-9a-f]{2,})\}/chr hex $1/ger;
   $output=~s/^\$VAR1 = \[\n\s+|        \];\n?$//g;
   $output=~s/\[\n\s+\[/\[\[/g;
   $output=~s/\n\s+([^\s])/$1/g;
   $output=~s/\]\],/\]\],\n/g;
   if (length $output <100){
	   print "Conversion failed\n";
	   next;
	   };
    
	open my $dat,">:utf8","$fontName.grf" or 
	      print "Unable to save fontfile $fontName.grf $!;\n"  && next;
	print $dat $output;
	close $dat;
	
	rename "$fontName.z80.asm","$fontName.z80.asm.done"or 
	      print "Unable to rename fontfile $fontName.z80.asm $!;\n" ;
	
}

