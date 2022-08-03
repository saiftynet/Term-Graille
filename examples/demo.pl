#! /usr/bin/env perl
use strict; use warnings;
 use Term::Graille  qw/colour paint printAt clearScreen border/;
 use Term::Graille::Font  qw/loadGrf fontWrite/;
 use Time::HiRes "sleep";
 
  my $canvas = Term::Graille->new(
    width  => 72,
    height => 64,
    top=>3,
    left=>10,
    borderStyle => "double",
  );
clearScreen();  

my $grf=loadGrf("./fonts/ZX Times.grf");
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
   
  

   fontWrite($canvas,$grf,4,5,"GRAILLE");
   $canvas->textAt(18,14,"Testing version $Term::Graille::VERSION","green italic");
   $canvas->textAt(18,10,"with Bresenham $Algorithm::Line::Bresenham::VERSION","green italic");
   $canvas->ellipse_rect(20,63, 52,55,"red");
   $canvas->quad_bezier(20,59,22,40,35,40);
   $canvas->quad_bezier(37,40,50,40,52,59);
   $canvas->polyline(35,40,35,35,20,35,20,33,55,33,55,35,37,35,37,40,"yellow");
   $canvas->draw();
   sleep 2;
   for (0..20){
     $canvas->scroll("d");
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
   $canvas->logo("mv 15,30;pc magenta;sp 8;");
   my @clrs=qw/red yellow green cyan magenta blue green red yellow/;
   $canvas->logo("fd 50;lt 160;pc $clrs[$_]") for (0..8);
   sleep 2;
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
		 $canvas->line(@points[0, 1], $mid, 0,"red");
		 $canvas->line(@points[0, 1], @points[2, 3],"green");
		 $canvas->line(@points[4, 5], $mid, 0,"yellow");
		 $canvas->line(@points[4, 5], @points[6, 7],"blue");
		 $canvas->line(@points[8, 9],$mid, 0,"magenta");
		 $canvas->line(@points[8, 9],@points[10, 11],"white");
		 $canvas->line(@points[2, 3], $mid, $height,"cyan");
		 $canvas->line(@points[2, 3], @points[4, 5],"blue");
		 $canvas->line(@points[6, 7],$mid, $height,"red");
		 $canvas->line(@points[6, 7],@points[8, 9],"green");
		 $canvas->line(@points[10, 11],$mid, $height,"yellow"); 
		 $canvas->line(@points[10, 11],@points[0, 1]); 
		   $canvas->draw();
		   sleep .01;
		   $canvas->clear();
	  }
	  sleep 2;
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

   $canvas->quad_bezier(10,30,37,-10,64,30,"green");
   $canvas->line(10,30,10,45,"green");
   $canvas->line(64,30,64,45,"green");
	 
   for my $rl(0..1){   # draw eyes
      for (0..4){
         $canvas->ellipse_rect(15+$_+30*$rl,45,30-$_+30*$rl,40,"magenta");
      }
   }
	 
	 
	 $canvas->quad_bezier(25,25,37,10,49,25,"red");
	 $canvas->quad_bezier(25,25,37,20,49,25,"red");
	 
	 $canvas->circle(37,33,5,"yellow");
	 $canvas->polyline(10,55,15,58,20,55,25,58,30,55,35,58,
	                   40,55,45,58,50,55,55,58,60,55,65,58,
	                   65,50,10,50,10,55,"yellow");
	 $canvas->draw();
	 sleep 2;
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
     $canvas->line(70,20*sin($c/20)+40,71,20*sin(($c+0.5)/20)+40,"red");
     $canvas->line(70,20*cos($c/2)+40,71,20*cos(($c+0.5)/2)+40,"green");
     $canvas->scroll("l");
	 $canvas->draw();   
 }
 
 sleep 5
 
}

    
  
