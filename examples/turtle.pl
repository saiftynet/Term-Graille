#! /usr/bin/env perl
use strict; use warnings;
use lib "../lib/";
 use Term::Graille  qw/colour paint printAt clearScreen border/;
 use Time::HiRes "sleep";
 
  my $canvas = Term::Graille->new(
    width  => 72,
    height => 64,
    top=>3,
    left=>10,
    borderStyle => "double",
  );
clearScreen();  

my %letters18=(
	A=>"lt 80;fd 20;rt 160; fd 20;pu;rt 160;fd 8;pd;rt 120; fd 3;pu; rt 80;fd 7; lt 83; fd 2; pd;",
	B=>"lt 90;fd 18;rt 90;". ("fd 4;rt 45;"x4)."fd 4;rt 180;". ("fd 4;rt 45;"x4)."fd 4;rt 180; pu; fd 10;pd;",
	P=>"lt 90;fd 19;rt 90;". ("fd 4;rt 45;"x4)."fd 4;lt 90;pu;fd 10;lt 90;fd 10;pd;",
	R=>"lt 90;fd 19;rt 90;". ("fd 4;rt 45;"x4)."fd 4;lt 125;fd 11;pu;lt 52;fd 4;pd;",
	D=>"lt 90;fd 19;rt 90;". ("fd 4;rt 45;"x2)."fd 10;".("fd 4;rt 45;"x2)."fd 4;rt 180; pu; fd 9;pd;", 
	I=>"fd 4;lt 180; fd 2;rt 90; fd 19; lt 90; fd 2; lt 180; fd 4; pu;rt 90;fd 19;lt 90; fd 3; pd;",
	L=>"fd 6;lt 180;fd 6;rt 90; fd 19; pu; lt 180; fd 19; lt 90; fd 9; pd;",
	E=>"fd 6;lt 180;fd 6;rt 90; fd 19; rt 90; fd 6; pu; rt 90; fd 9; rt 90; fd 2; pd;fd 4; pu; lt 90; fd 10; lt 90; fd 9; pd;",
	O=>"pu;fd 3;pd;".("fd 3;lt 45;"x2). "fd 15;".("lt 45;fd 3;"x3). "lt 45;fd 12;".("fd 3;lt 45;"x2)."pu;fd 8;pd;",
	Q=>"pu;fd 3;pd;".("fd 3;lt 45;"x2). "fd 15;".("lt 45;fd 3;"x3). "lt 45;fd 12;".("fd 3;lt 45;"x2)."pu;lt 90;fd 5;pd;rt 135; fd 8;lt 45; pu; fd 2; pd;",
	C=>"pu; lt 68; fd 19;pd;lt 22;".("lt 45;fd 3;"x3)."lt 45;fd 16;".("lt 45;fd 3;"x3)."pu;rt 90;fd 3;lt 45;pd; fd 2",
	G=>"pu; lt 68; fd 19;pd;lt 22;".("lt 45;fd 3;"x3)."lt 45;fd 15;".("lt 45;fd 3;"x4)." lt 90;fd 2;rt 180; fd 3;pu ;rt 90; fd 5;lt 90;fd 3;pd;;fd 2",
);

  
logo();
turtle();
cube();
lines();
waves();
 
printAt(20,50," ");

sub logo{
   $canvas->clear();
   $canvas->{borderColour}="cyan";
   $canvas->{title}="Term::Graille";
   $canvas->logo("pu;rt 90; fd 25; rt 90;fd 31;lt 180;pd;");
   printAt(5,50, paint("Introducing Term::Graille", "white on_black"));
   printAt(7,50, paint(["Inspired by Drawille by",
                                          "asciimoo, which has many",
                                          "variants (including a ",
                                          "Perl variant Term::Drawille",
                                          "by RHOELZ), this is a clone",
                                          "with a few extras. The goal",
                                          "is to deliver better",
                                          "performance and features.   "],"yellow"));
   
   
   $canvas->logo($letters18{G});
   $canvas->logo($letters18{R});
   $canvas->logo($letters18{A});
   $canvas->logo($letters18{I});   
   $canvas->logo($letters18{L});
   $canvas->logo($letters18{L});
   $canvas->logo($letters18{E});
   $canvas->ellipse_rect(20,63, 52,55);
   $canvas->quad_bezier(20,59,22,40,35,40);
   $canvas->quad_bezier(37,40,50,40,52,59);
   $canvas->polyline(35,40,35,35,20,35,20,33,55,33,55,35,37,35,37,40,12);
 #  $canvas->logo($letters18{C});
  #$canvas->logo("fd 35;lt 75") for (0..23);
   $canvas->draw();
   sleep 3;
   for (0..40){
     $canvas->scroll("r");
     sleep 0.05;
   $canvas->draw();
 }
}      

sub turtle{
   $canvas->clear();
   $canvas->{borderColour}="magenta";
   $canvas->{title}="Turtle";
   printAt(5,50, paint("Turtle Graphics          ", "white on_black"));
   printAt(7,50, paint(["This early version supports ",
                                          "Turtle-like drawing as well e.g.",
                                          "fd,bk,lt,rt,pu,pd,ce,sp "," "x30,], "yellow"));
   printAt(11,50, paint(["\$canvas->logo('fd 35;lt 75')",
                                          "   for (0..23);               ",  
                                          " "x 30," "x30," "x 30," "x30,], "green"));
   $canvas->logo("ce;pu; sp 20;fd 20;lt 90; fd 20; lt 90; pd");
   $canvas->logo("fd 35;lt 75") for (0..23);
}      


sub cube{
	# adapted from http://www.rosettacode.org/wiki/Draw_a_rotating_cube
	my $size = 60;
	my ($height, $width) = ($size, $size * sqrt 8/9);
	my $mid = $width / 2;
	my $rot = atan2(0, -1) / 3;         # middle corners every 60 degrees          
	$canvas->{borderColour}="green";

   printAt(5,50, paint("Animated drawings              ", "white on_black"));
   printAt(7,50, paint(["Rotating cube.  This algorithm ",
                                          "was adapted from code from     ",
                                          "http://www.rosettacode.org/    ",
                                          " "x 30," "x30," "x30," "x30,],"yellow"));
	$canvas->{title}="Rotating Cube";
	  foreach my $a (0..300)
	  {
	  my $angle = $a/30;                    
	  my @points = map { $mid + $mid * cos $angle + $_ * $rot,
		$height * ($_ % 2 + 1) / 3 } 0 .. 5;
		 $canvas->line(@points[0, 1], $mid, 0);
		 $canvas->line(@points[0, 1], @points[2, 3]);
		 $canvas->line(@points[4, 5], $mid, 0);
		 $canvas->line(@points[4, 5], @points[6, 7]);
		 $canvas->line(@points[8, 9],$mid, 0);
		 $canvas->line(@points[8, 9],@points[10, 11]);
		 $canvas->line(@points[2, 3], $mid, $height);
		 $canvas->line(@points[2, 3], @points[4, 5]);
		 $canvas->line(@points[6, 7],$mid, $height);
		 $canvas->line(@points[6, 7],@points[8, 9]);
		 $canvas->line(@points[10, 11],$mid, $height); 
		 $canvas->line(@points[10, 11],@points[0, 1]); 
		   $canvas->draw();
		   sleep .01;
		   $canvas->clear();
	  }
}  

sub lines{
   $canvas->clear();;
   $canvas->{borderColour}="yellow";
	$canvas->{title}="Lines, Curves, Circles Etc";
   printAt(5,50,  paint("Drawing Primitives    ", "white on_black"));
   printAt(7,50,  paint("Lines                         ","yellow"));
   printAt(8,50,  paint(["\$canvas->line(10,10,         ",
                                          "               30,30)        "],"green"));
   printAt(10,50, paint("Curves                       ","yellow"));
   printAt(11,50, paint(["\$canvas->quad_bezier(10,10, ",
                                          "               30,30,50,10); "],"green"));
   printAt(13,50, paint("Circles                    ","yellow"));
   printAt(14,50, paint("\$canvas->circle(30,30,5); ", "green"));

	 $canvas->quad_bezier(10,10,30,30,50,10);
	 sleep 0.5;	  $canvas->draw();
	 $canvas->ellipse_rect(10,10,30,50);
	 sleep 0.5;	  $canvas->draw();
	 $canvas->quad_bezier(50,10,30,30,50,50);
	 sleep 0.5;	  $canvas->draw();	
	 $canvas->quad_bezier(50,50,30,30,10,50);
	 sleep 0.5;	  $canvas->draw();
	 
	 $canvas->ellipse_rect(50,50,30,10);
	 sleep 0.5;	  $canvas->draw();
	 $canvas->quad_bezier(10,50,30,30,10,10);
	 sleep 0.5;	  $canvas->draw();
	 $canvas->circle(30,30,5);
	 sleep 0.5;	  $canvas->draw();
	 $canvas->polyline(55,10,60,15,55,20,60,25,55,30,60,30);
	 sleep 0.5;	  $canvas->draw();
	  sleep 1;
}

sub  waves{	  
   $canvas->clear();;
   $canvas->{borderColour}="blue";
   $canvas->{title}="Waves";	  
   printAt(5,50, paint("Charting/graphing        ", "white on_black"));
   printAt(7,50, paint(["This example plots a line     ",
                                          "on the left most two pixels   ",
                                          "and then scrolls the frame left   ",
                                          "by 2 pixels. e.g :-         ",
                                          " "x30], "yellow"));
   printAt(12,50, paint(["foreach my \$c (1..1000){     ",
                                          "\$canvas->line(70,20*sin(\$c/20)+",
                                          "40,71,20*sin((\$c+0.5)/20)+40);  ",
                                          "\$canvas->scroll('l');      ",
                                          "sleep 0.01;                 ",
                                          "\$canvas->draw();}          "], "green"));
 foreach my $c (1..500){
     sleep .01;
     $canvas->line(70,20*sin($c/20)+40,71,20*sin(($c+0.5)/20)+40);
     $canvas->line(70,20*cos($c/2)+40,71,20*cos(($c+0.5)/2)+40);
     $canvas->scroll("l");
	 $canvas->draw();   
 }
 
}

    
  
