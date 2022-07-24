#! /usr/bin/env perl
use strict; use warnings;
#use lib "../lib/";
use lib "../lib";
use Term::Graille qw/colour paint printAt clearScreen border/;
use Image::Magick;
use Time::HiRes "sleep";

# convert2grl--converts an image to .grv format.

my $animationFolder=$ARGV[0]||"./animations/cheetah/";
opendir my $dir,$animationFolder or die;
my @files=sort grep !/^(\.|\.\.|.*\.pl)$/,readdir $dir;

my $canvas = Term::Graille->new(
    width  => 120,
    height => 50,
    top=>4,
    left=>10,
    borderStyle => "double",
    borderColour  => "yellow",
    title=>" Animation test ",
  );
my $animation=[];

my $frame=0;
for my $image (@files){
	$canvas->clear();
	print "Loading image ",$animationFolder.$image," ",++$frame,"\n";
	$animation->[$frame]=[];
	loadImage($animationFolder.$image);
	#loadImage("./animations/chimp/chimp$frame.png"); 
	foreach my $row (0..$#{$canvas->{grid}}){
		foreach my $col(0..$#{$canvas->{grid}->[0]}){
			$animation->[$frame]->[$row]->[$col]=$canvas->{grid}->[$row]->[$col];
		}
	}
}

sleep 1;
clearScreen();


foreach (0..100){
	foreach my $frame (1..@$animation){
		next unless ref $animation->[$frame];
		$canvas->{grid}=$animation->[$frame]; 
		$canvas->draw();
		sleep 0.08;
	}
}

sub loadImage{
	my $imgfile=shift;
	my $image = Image::Magick->new();
	my $wh = $image->Read($imgfile); 
	$image->Resize(geometry => "$canvas->{width}x$canvas->{height}");
	die $wh if $wh; 
	$image->set('monochrome'=>'True');
	$image->Negate();
	for (my $x =0;$x<$canvas->{width};$x++){
		for (my $y=0;$y<$canvas->{height};$y++){
			$canvas->set($x,$y) if $image->GetPixel("x"=>$x,"y",$canvas->{height}-$y); 
		}
	}
}

