=head1 NAME

Algorithm::Line::Bresenham - simple pixellated line-drawing algorithm

=head1 SYNOPSIS

 use Algorithm::Line::Bresenham qw/line/;
 my @points = line(3,3 => 5,0);
    # returns the list: [3,3], [4,2], [4,1], [5,0]
 my @points = circle(30,30,5);
    # returns the points to draw a circle centered at 30,30, radius 5

=head1 DESCRIPTION

Bresenham is one of the canonical line drawing algorithms for pixellated grids.
Given a start and an end-point, Bresenham calculates which points on the grid
need to be filled to generate the line between them. This module has been extended
to include cureves crcles ellipses and thick licnes, variable thickness lines.


=cut


package Algorithm::Line::Bresenham;
use strict; use warnings;
our $VERSION = 0.151;
use base 'Exporter';
our @EXPORT_OK = qw/line circle ellipse_rect quad_bezier polyline varthick_line thick_line/;


=head2 C<line>

 line ($from_x, $from_y => $to_x, $to_y);

Generates a list of all the intermediate points.  This is returned as a list
of array references. Previous versions used to include a callback parameter
as a CODE ref to act on each point in turn.  This version omits that for
performance reasons 

=cut

sub line { # ported from https://gist.github.com/bert/1085538
	use integer;
	 my ($x0, $y0, $x1, $y1,$callback,$cbArgs)=@_;
	 use integer;
     my $dx =  abs ($x1 - $x0);
     my $sx = $x0 < $x1 ? 1 : -1;
     my $dy = -abs ($y1 - $y0);
     my $sy = $y0 < $y1 ? 1 : -1; 
     my $err = $dx + $dy;
     my $e2; #/* error value e_xy */
     my @points;
 
     while(1){  #/* loop */
		 if ($callback){
			 $callback->($x0,$y0,$cbArgs);
		 }
		 else{
			 push @points,[$x0,$y0];
		 }
       
       last if ($x0 == $x1 && $y0 == $y1);
       $e2 = 2 * $err;
       if ($e2 >= $dy) { $err += $dy; $x0 += $sx; } #/* e_xy+e_x > 0 */
       if ($e2 <= $dx) { $err += $dx; $y0 += $sy; } #/* e_xy+e_y < 0 */
  }
  return @points;
}


=head2 C<circle>

    my @points = circle ($x, $y, $radius)

Returns the points to draw a circle centered on C<$x,$y> with
radius C<$radius> 

=cut

sub circle { # ported from https://gist.github.com/bert/1085538
	my ($xm, $ym, $r)=@_;
	use integer;
    my $x = -$r;
    my $y = 0;
    my $err = 2-2*$r; #/* II. Quadrant */ 
    my @points;
    do {
      push @points,[$xm-$x, $ym+$y];# /*   I. Quadrant */
      push @points,[$xm-$y, $ym-$x];# /*  II. Quadrant */
      push @points,[$xm+$x, $ym-$y];# /* III. Quadrant */
      push @points,[$xm+$y, $ym+$x];# /*  IV. Quadrant */
      $r = $err;
       $err += ++$x*2+1 if ($r >  $x); #/* e_xy+e_x > 0 */
       $err += ++$y*2+1 if ($r <= $y); #/* e_xy+e_y < 0 */
   } while ($x < 0);
   return @points;
}

=head2 C<ellipse_rect>

    my @points = ellipse_rect ($x0, $y0, $x1, $y1)

Returns the points to an ellipse bound within a rectangle defined by
the two coordinate pairs passed.

=cut


sub ellipse_rect{ # ported from https://gist.github.com/bert/1085538
	use integer;
	my ($x0, $y0, $x1, $y1)=@_;
   my $a = abs ($x1 - $x0);
   my $b = abs ($y1 - $y0);
   my $b1 = $b & 1; #/* values of diameter */
   my $dx = 4 * (1 - $a) * $b * $b;
   my $dy = 4 * ($b1 + 1) * $a * $a; #/* error increment */
   my $err = $dx + $dy + $b1 * $a * $a;
   my $e2; #/* error of 1.step */

   if ($x0 > $x1) { $x0 = $x1; $x1 += $a; } #/* if called with swapped points */
   $y0 = $y1 if ($y0 >$y1);# /* .. exchange them */
   $y0 += ($b + 1) / 2;
   $y1 = $y0-$b1;   #/* starting pixel */
   $a *= 8 * $a; $b1 = 8 * $b * $b;
   my @points;
   do
   {
       push @points,[$x1, $y0];# /*   I. Quadrant */
       push @points,[$x0, $y0];# /*  II. Quadrant */
       push @points,[$x0, $y1];# /* III. Quadrant */
       push @points,[$x1, $y1];# /*  IV. Quadrant */
       $e2 = 2 * $err;
       if ($e2 >= $dx)
       {
          $x0++;
          $x1--;
          $err += $dx += $b1;   # does this translate into perl
       } #/* x step */
       if ($e2 <= $dy)
       {
          $y0++;
          $y1--;
          $err += $dy += $a;
       }  #/* y step */ 
   } while ($x0 <= $x1);
   while ($y0-$y1 < $b)
   {  #/* too early stop of flat ellipses a=1 */
       push @points,[$x0-1, $y0]; #/* -> finish tip of ellipse */
       push @points,[$x1+1, $y0++]; 
       push @points,[$x0-1, $y1];
       push @points,[$x1+1, $y1--]; 
   }
   
   return @points;
}

=head2 C<basic_bezier>

    my @points = basic_bezier ($x0, $y0, $x1, $y1, $x2, $y2)

This is not usefull on its own.  Iteturns the points to segment of a
bezier curve without a gradient sign change.   It is a companion to
the C<quad_bexier> function that splits a bezier into segments
with each gradient direction and these segments are computed in 
C<basic_bezier>

=cut


sub basic_bezier{  # without gradient changes adapted from https://gist.github.com/bert/1085538
	my ($x0, $y0, $x1, $y1, $x2, $y2)=@_;
	my $sx = $x0 < $x2 ? 1 : -1;
  my $sy = $y0 < $y2 ? 1 : -1; #/* step direction */
  my $cur = $sx * $sy *(($x0 - $x1) * ($y2 - $y1) - ($x2 - $x1) * ($y0 - $y1)); #/* curvature */
  my $x = $x0 - 2 * $x1 + $x2;
  my $y = $y0 - 2 * $y1 +$y2;
  my  $xy = 2 * $x * $y * $sx * $sy;
                               # /* compute error increments of P0 */
  my $dx = (1 - 2 * abs ($x0 - $x1)) * $y * $y + abs ($y0 - $y1) * $xy - 2 * $cur * abs ($y0 - $y2);
  my $dy = (1 - 2 * abs ($y0 - $y1)) * $x * $x + abs ($x0 - $x1) * $xy + 2 * $cur * abs ($x0 - $x2);
                               #/* compute error increments of P2 */
  my $ex = (1 - 2 * abs ($x2 - $x1)) * $y * $y + abs ($y2 - $y1) * $xy + 2 * $cur * abs ($y0 - $y2);
  my $ey = (1 - 2 * abs ($y2 - $y1)) * $x * $x + abs ($x2 - $x1) * $xy - 2 * $cur * abs ($x0 - $x2);
                             # /* sign of gradient must not change */
  warn "gradient change detected" unless (($x0 - $x1) * ($x2 - $x1) <= 0 && ($y0 - $y1) * ($y2 - $y1) <= 0); 
  if ($cur == 0)
  { #/* straight line */
     return line ($x0, $y0, $x2, $y2);
   
  }
  $x *= 2 * $x;
  $y *= 2 * $y;
  if ($cur < 0)
  { #/* negated curvature */
    $x = -$x;
    $dx = -$dx;
    $ex = -$ex;
    $xy = -$xy;
    $y = -$y;
    $dy = -$dy;
    $ey = -$ey;
  }
 #/* algorithm fails for almost straight line, check error values */
  if ($dx >= -$y || $dy <= -$x || $ex <= -$y || $ey >= -$x)
  {        
    return (line ($x0, $y0, $x1, $y1), line ($x1, $y1, $x2, $y2)); #/* simple approximation */
  }
  $dx -= $xy;
  $ex = $dx + $dy;
  $dy -= $xy; #/* error of 1.step */
  my @points;
  while(1)
  { #/* plot curve */
    push @points,[$x0, $y0];
    $ey = 2 * $ex - $dy; #/* save value for test of y step */
    if (2 * $ex >= $dx)
    { #/* x step */
      last if ($x0 == $x2);
      $x0 += $sx;
      $dy -= $xy;
      $ex += $dx += $y; 
    }
    if ($ey <= 0)
    { #/* y step */
      last if ($y0 == $y2);
      $y0 += $sy;
      $dx -= $xy;
      $ex += $dy += $x; 
    }
  }
  return @points;
}  


=head2 C<quad_bezier>

    my @points = quad_bezier ($x0, $y0, $x1, $y1, $x2, $y2)

Draws a Bezier curve from C<($x0,$y0)> to  C<($x2,$y2)> using control
point  C<($x1,$y1)> 

=cut


sub quad_bezier{  # adapted from http://members.chello.at/easyfilter/bresenham.html
	my ($x0, $y0, $x1, $y1, $x2, $y2)=@_;# /* plot any quadratic Bezier curve */
  my $x = $x0-$x1;
  my $y = $y0-$y1;
  my $t = $x0-2*$x1+$x2;
  my $r;
  my @points;
  if ($x*($x2-$x1) > 0) { #/* horizontal cut at P4? */
    if ($y*($y2-$y1) > 0){ #/* vertical cut at P6 too? */
      if (abs(($y0-2*$y1+$y2)/$t*$x) > abs($y)) { #/* which first? */
        $x0 = $x2; $x2 = $x+$x1; $y0 = $y2; $y2 = $y+$y1;# /* swap points */
      } #/* now horizontal cut at P4 comes first */
     }
    $t = ($x0-$x1)/$t;
    $r = (1-$t)*((1-$t)*$y0+2.0*$t*$y1)+$t*$t*$y2;# /* By(t=P4) */
    $t = ($x0*$x2-$x1*$x1)*$t/($x0-$x1); #/* gradient dP4/dx=0 */
    $x = int($t+0.5); $y = int($r+0.5);
    $r = ($y1-$y0)*($t-$x0)/($x1-$x0)+$y0; #/* intersect P3 | P0 P1 */
    push @points, basic_bezier($x0,$y0, $x,int($r+0.5), $x,$y);
    $r = ($y1-$y2)*($t-$x2)/($x1-$x2)+$y2; #/* intersect P4 | P1 P2 */
    $x0 = $x1 = $x; $y0 = $y; $y1 = int($r+0.5);# /* P0 = P4, P1 = P8 */
  }
  if (($y0-$y1)*($y2-$y1) > 0) { #/* vertical cut at P6? */
    $t = $y0-2*$y1+$y2; $t = ($y0-$y1)/$t;
    $r = (1-$t)*((1-$t)*$x0+2.0*$t*$x1)+$t*$t*$x2; # /* Bx(t=P6) */
    $t = ($y0*$y2-$y1*$y1)*$t/($y0-$y1); #/* gradient dP6/dy=0 */
    $x = int($r+0.5); $y = int($t+0.5);
    $r = ($x1-$x0)*($t-$y0)/($y1-$y0)+$x0; #/* intersect P6 | P0 P1 */
     push @points, basic_bezier($x0,$y0, int($r+0.5),$y, $x,$y);
    $r = ($x1-$x2)*($t-$y2)/($y1-$y2)+$x2; #/* intersect P7 | P1 P2 */
    $x0 = $x; $x1 = int($r+0.5); $y0 = $y1 = $y;# /* P0 = P6, P1 = P7 */
  }
   push @points, basic_bezier($x0,$y0, $x1,$y1, $x2,$y2); #/* remaining part */
   return @points;
}

=head2 C<polyline>

    my @points = polyline ($x0, $y0, $x1, $y1, $x2, $y2)

Draws a polyline between points served as a list of x,y pairs

=cut

sub polyline{
	my @vertices;
	push @vertices,[shift,shift] while (@_>1);
	my @points;
	foreach my $vertex(0..(@vertices-2)){
		push @points,line(@{$vertices[$vertex]},@{$vertices[$vertex+1]});	
		pop @points if ($vertex < (@vertices-2)); # remove duplicated points
	}
	return @points;
}

=head2 C<thick_line>

    my @points = thick_line ($x0, $y0, $x1, $y1,$thickness)

Draws a line thickened using Murphy's modication of Bresenham'salgorithm
between two points  of x,y pairs. This routine was further enahnced to 
provide variable thickness lines and uses multiple helper subroutines.

=head2 C<varthick_line>
  
  my @points= varthick_line($x0,$y0,$x1,$y1,$leftFn,$argL,$rightFn,$argR)

Variable thickness lines are implemented as described in
http://kt8216.unixcab.org/murphy/index.html ; This allows passing of 
two subroutine references (so the left side and the right sides of the
line can have differently varying thicknesses) along with a
user originated parameter. The subroutine reference example is shown below:

   my $leftFn=sub{
      my ($arg,$p,$l)=@_;
      # C<$arg> is passed by calling routine,
      # C<$p> is point on line
      # C<$l> is length of line
	  return $p % $arg;
   };

=cut

## Variable thickness lines using Murphy's Modification of Bresenham Line Algorithm**
## Codes ported from C in http://kt8216.unixcab.org/murphy/index.html  

 #*                            X BASED LINES                            *
 
sub x_perpendicular{
  my ($x0,$y0,$dx,$dy,$xstep,$ystep,$einit,$w_left,$w_right,$winit)=@_;
  
  my @pts;

  my $threshold = $dx - 2*$dy;
  my $E_diag= -2*$dx;
  my $E_square= 2*$dy;
  my $p=my $q=0;

  my $y= $y0;
  my $x= $x0;
  my $error= $einit;
  my $tk= $dx+$dy-$winit; 

  while($tk<=$w_left)
  {
     push (@pts,[$x,$y]);
     if ($error>=$threshold)
     {
       $x= $x + $xstep;
       $error = $error + $E_diag;
       $tk= $tk + 2*$dy;
     }
     $error = $error + $E_square;
     $y= $y + $ystep;
     $tk= $tk + 2*$dx;
     $q++;
  }

  $y= $y0;
  $x= $x0;
  $error= -$einit;
  $tk= $dx+$dy+$winit;

  while($tk<=$w_right)
  {
     push (@pts,[$x,$y]) if ($p);
     if ($error>$threshold)
     {
       $x= $x - $xstep;
       $error = $error + $E_diag;
       $tk= $tk + 2*$dy;
     }
     $error = $error + $E_square;
     $y= $y - $ystep;
     $tk= $tk + 2*$dx;
     $p++;
  }

  push (@pts,[$x,$y]) if ($q==0 && $p<2); # we need this for very thin lines
  
  return @pts;
}


sub x_varthick_line{
   my ($x0,$y0,$dx,$dy,$xstep,$ystep,
    $left, $argL, #left  thickness function
    $right,$argR, #right thickness function
    $pxstep,$pystep)=@_;
  
  my @xPoints;
  
  my $p_error= 0;
  my $error= 0;
  my $y= $y0;
  my $x= $x0;
  my $threshold = $dx - 2*$dy;
  my $E_diag= -2*$dx;
  my $E_square= 2*$dy;
  my $length = $dx+1;
  my $D= sqrt($dx*$dx+$dy*$dy);

  for(my $p=0;$p<$length;$p++)
  {
    my $w_left=  $left->($argL, $p, $length)*2*$D;
    my $w_right= $right->($argR,$p, $length)*2*$D;
    push @xPoints,x_perpendicular($x,$y, $dx, $dy, $pxstep, $pystep,
                                      $p_error,$w_left,$w_right,$error);
    if ($error>=$threshold)
    {
      $y= $y + $ystep;
      $error = $error + $E_diag;
      if ($p_error>=$threshold) 
      {
      push @xPoints,x_perpendicular($x,$y, $dx, $dy, $pxstep, $pystep,
                                    ($p_error+$E_diag+$E_square), 
                                     $w_left,$w_right,$error);
        $p_error= $p_error + $E_diag;
      }
      $p_error= $p_error + $E_square;
    }
    $error = $error + $E_square;
    $x= $x + $xstep;
  }
  return @xPoints;
}

 #*                            Y BASED LINES                            *

sub y_perpendicular{
	my ($x0,$y0,$dx,$dy,$xstep,$ystep,
        $einit,$w_left, $w_right,$winit)=@_;

  my @pts;

  my $threshold = $dy - 2*$dx;
  my $E_diag= -2*$dy;
  my $E_square= 2*$dx;
  my $p=my $q=0;

  my $y= $y0;
  my $x= $x0;
  my $error= -$einit;
  my $tk= $dx+$dy+$winit; 


  while($tk<=$w_left)
  {
     push @pts,[$x,$y];
     if ($error>$threshold)
     {
       $y= $y + $ystep;
       $error = $error + $E_diag;
       $tk= $tk + 2*$dx;
     }
     $error = $error + $E_square;
     $x= $x + $xstep;
     $tk= $tk + 2*$dy;
     $q++;
  }


  $y= $y0;
  $x= $x0;
  $error= $einit;
  $tk= $dx+$dy-$winit; 

  while($tk<=$w_right)
  {
     push (@pts,[$x,$y]) if ($p);
     if ($error>=$threshold)
     {
       $y= $y - $ystep;
       $error = $error + $E_diag;
       $tk= $tk + 2*$dx;
     }
     $error = $error + $E_square;
     $x= $x - $xstep;
     $tk= $tk + 2*$dy;
     $p++;
  }

  push (@pts,[$x,$y])  if ($q==0 && $p<2); # we need this for very thin lines
  return @pts;
 }


sub y_varthick_line {
  my ($x0,$y0,$dx,$dy,$xstep,$ystep,
    $left, $argL, #left  thickness function
    $right,$argR, #right thickness function
    $pxstep,$pystep)=@_;
  
  my @yPoints;
  my $p_error= 0;
  my $error= 0;
  my $y= $y0;
  my $x= $x0;
  my $threshold = $dy - 2*$dx;
  my $E_diag= -2*$dy;
  my $E_square= 2*$dx;
  my $length = $dy+1;
  my $D= sqrt($dx*$dx+$dy*$dy);

  for(my $p=0;$p<$length;$p++)
  {
    my $w_left=  $left->($argL, $p, $length)*2*$D;
    my $w_right= $right->($argR,$p, $length)*2*$D;
    push @yPoints,y_perpendicular($x,$y, $dx, $dy, $pxstep, $pystep,
                                      $p_error,$w_left,$w_right,$error);
    if ($error>=$threshold)
    {
      $x= $x + $xstep;
      $error = $error + $E_diag;
      if ($p_error>=$threshold)
      {
      push @yPoints,y_perpendicular($x,$y, $dx, $dy, $pxstep, $pystep,
                                      ($p_error+$E_diag+$E_square),$w_left,$w_right,$error);
        $p_error= $p_error + $E_diag;
      }
      $p_error= $p_error + $E_square;
    }
    $error = $error + $E_square;
    $y= $y + $ystep;
  }
  return @yPoints;
}

 #*                                ENTRY                                *

sub thick_line{
     my ($x0,$y0,$x1,$y1,$thickness)=@_;
     return varthick_line($x0,$y0,$x1,$y1,sub{return (1+$thickness)/2},undef,sub{return (1+$thickness)/2},undef)
};
sub varthick_line{
     my ($x0,$y0,$x1,$y1,
       $left,$argL,
       $right,$argR)=@_;

  my $dx= $x1-$x0;
  my $dy= $y1-$y0;
  my $xstep= my $ystep= 1;

  if ($dx<0) { $dx= -$dx; $xstep= -1; }
  if ($dy<0) { $dy= -$dy; $ystep= -1; }

  $xstep= 0 if ($dx==0);
  $ystep= 0 if ($dy==0);
  my $pxstep; my $pystep;

  my $xch= 0;
  for($xstep + $ystep*4){
    ($_==-1 + -1*4) && do {$pystep= -1; $pxstep= 1; $xch= 1; last;};   # -5
    ($_==-1 +  0*4) && do {$pystep= -1; $pxstep= 0; $xch= 1; last;};   #  -1
    ($_==-1 +  1*4) && do {$pystep=  1; $pxstep= 1;  last;};   #  3
    ($_== 0 + -1*4) && do {$pystep=  0; $pxstep= -1; last;};   #  -4
    ($_== 0 +  0*4) && do {$pystep=  0; $pxstep= 0;  last;};   #  0
    ($_== 0 +  1*4) && do {$pystep=  0; $pxstep= 1;  last;};   #  4
    ($_== 1 + -1*4) && do {$pystep= -1; $pxstep= -1; last;};   #  -3
    ($_== 1 +  0*4) && do {$pystep= -1; $pxstep= 0;  last;};   #  1
    ($_== 1 +  1*4) && do {$pystep=  1; $pxstep= -1; $xch=1; last;};   #  5
  }

  if ($xch){
	  my $K;
	  $K= $argL; $argL= $argR; $argR= $K;
	  $K= $left; $left= $right; $right= $K; }

  if ($dx>$dy){
	  return x_varthick_line($x0,$y0,$dx,$dy,$xstep,$ystep,
                                                $left,$argL,$right,$argR,
                                                $pxstep,$pystep);
   }
   else{
	   return y_varthick_line($x0,$y0,$dx,$dy,$xstep,$ystep,
                                                $left,$argL,$right,$argR,
                                                $pxstep,$pystep);
   }
}




1;
__END__

=head1 TODO and BUGS

polylines
nurbs
arc
line width
fills
pattern fills

=head1 THANKS

Patches for the circle algorithm and a float value bug contributed by Richard Clamp, thanks!

=head1 AUTHOR

osfameron, osfameron@cpan.org
saiftynet 


=head1 LICENSE

Artistic (Perl)

=head1 INSTALLATION

Using C<cpan>:

    $ cpan Algorithm::Line::Bresenham

Manual install:

    $ perl Makefile.PL
    $ make
    $ make install


Copyright (c) 2004-2022 saiftynet, osfameron. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
