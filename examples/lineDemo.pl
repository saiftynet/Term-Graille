#! /usr/bin/env perl
use strict; use warnings;
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
    title=>"Variable Thickness Line Demo",
  );
my @colours=qw/red blue green yellow cyan magenta white/;
clearScreen();  
$canvas->clear(); 

my $squiggles={
	sin1=>sub{
		my ($arg, $p, $length)=@_;
		return  abs(4*sin ($p/$arg));
	},
	sin2=>sub{
		my ($arg, $p, $length)=@_;
		return   abs(4*sin (($p+4)/$arg));
	},
	zigzag=>sub{
		my ($arg, $p, $length)=@_;
		return $p % $arg;
	},
	fixed=>sub{
		my ($arg, $p, $length)=@_;
		return $arg;
	},
	linear=>sub{
		my ($arg, $p, $length)=@_;
		return $arg*$p/$length;
	},	
};

#for (2..9){
#$canvas->thick_line(60,30,60+sin($_*45*3.14159267/180)*20,30+cos($_*45*3.14159267/180)*20,3,$colours[$_% 7]);
#}

my ($x1,$y1,$x2,$y2)=(5,55,115,5);
$canvas->varthick_line($x1,$y1,$x1,$y2,$squiggles->{sin1},3,$squiggles->{sin2},3,"green");
$canvas->varthick_line($x1,$y2,$x2,$y2,$squiggles->{sin1},3,$squiggles->{sin2},3,"green");
$canvas->varthick_line($x2,$y2,$x2,$y1,$squiggles->{sin1},3,$squiggles->{sin2},3,"green");
$canvas->varthick_line($x2,$y1,$x1,$y1,$squiggles->{sin1},3,$squiggles->{sin2},3,"green");

$canvas->varthick_line(20,12,20,48,$squiggles->{linear},4,$squiggles->{linear},4,"red");

$canvas->varthick_line(40,12,40,48,$squiggles->{zigzag},4,$squiggles->{fixed},2,"blue");
$canvas->varthick_line(60,12,60,48,$squiggles->{zigzag},4,$squiggles->{zigzag},6,"yellow");
$canvas->varthick_line(80,12,80,48,$squiggles->{sin1},4,$squiggles->{sin1},8,"magenta");
$canvas->varthick_line(100,12,100,48,$squiggles->{sin1},4,$squiggles->{sin1},4,"cyan");

$canvas->draw();
