#! /usr/bin/env perl
use strict; use warnings;
use lib "../lib/";
use Term::Graille qw/colour paint printAt clearScreen border/;
use Image::Magick;

# convert2grl--converts an image to .grl format.

my $imgFile=$ARGV[0];

my $canvas = Term::Graille->new(
    width  => 72,
    height => 60,
    top=>4,
    left=>10,
    borderStyle => "double",
  );
clearScreen();
loadImage($imgFile||"perl2.jpg");
$canvas->exportCanvas("save.grl");

#$canvas->importCanvas("save.grl");

sub loadImage{
	my $imgfile=shift;
	my $image = Image::Magick->new();
	my $wh = $image->Read($imgfile); 
	$image->Resize(geometry => "$canvas->{width}x$canvas->{height}");
	warn $wh if $wh; 
	$image->set('monochrome'=>'True');
	for (my $x =0;$x<$canvas->{width};$x++){
		for (my $y=0;$y<$canvas->{height};$y++){
			$canvas->set($x,$y) if $image->GetPixel("x"=>$x,"y",$canvas->{height}-$y); 
		}
	}
}

$canvas->draw();
print "\n";
print $imgFile//"no File input";;
