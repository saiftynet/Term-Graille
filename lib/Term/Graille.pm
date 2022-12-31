=head1 NAME

Term::Graille - Graphical Display in the terminal using UTF8 Braille characters

=head1 SYNOPSIS
 
  my $canvas = Term::Graille->new(
    width  => 72,    # pixel width
    height => 64,    # pixel height
    top=>3,          # row position in terminal (optional,defaults to 1)
    left=>10,        # column position (optional,defaults to 1)
    borderStyle => "double",  # 
  );

=head1 DESCRIPTION

Inspired by Drawille by asciimoo, which has many variants (including 
a perl variant Term::Drawille by RHOELZ), this is a clone with a few
extras. The goal is to achieve performance and features. with built-in
turtle-like graphics, line and curve drawing (Algorithm::Line::Bresenham),
scrolling, border setting, and more in development.

=begin html

<img src="https://user-images.githubusercontent.com/34284663/180637940-01b583a0-1a71-4a5d-a29b-394a940ce46f.gif">

=end html


=head1 FUNCTIONS

=cut

package Term::Graille;

use strict;use warnings;
our $VERSION="0.11";
use utf8;
use open ":std", ":encoding(UTF-8)";
use base 'Exporter';
our @EXPORT_OK = qw/colour paint printAt clearScreen border blockBlit block2braille pixelAt cursorAt wrapText/;
use Algorithm::Line::Bresenham 0.15;
use Time::HiRes "sleep";

BEGIN {
  if ($^O eq "MSWin32") {
	  system("chcp 65001 >nul");
	  system("echo 'Please set console font to one that can handle utf8 fonts'")
  }
}

=head3 C<my $canvas=Term::Graille-E<gt>new(%params)>

Creates a new canavas; params are
C<width> The pixel width, required C<height> the pixel height, required,
C<top> terminal row (optional,default 1) C<left> terminal column (
optional,default 1) C<borderStyle> border type (optional,one of 'simple',
'double', 'thin', 'thick' or 'shadow') C<borderColour> border colour (
optional), C<title>  Title text for top border,(optional) C<titleColour> 
Title colour (optional)

=cut


sub new{
    my ( $class, %params ) = @_;     #  params are width and height in pixels
    my $self={width=>$params{width},height=>$params{height}};
    for my $key (qw/borderStyle borderColour title titleColour top left cartesian/){
		$self->{ $key}=$params{$key} if exists $params{$key}
	}
	$self->{top}//=1;
	$self->{left}//=1;
	$self->{cartesian}//=1;                            
    $self->{setPix}=[['⡀','⠄','⠂','⠁'],['⢀','⠠','⠐','⠈']];
    $self->{unsetPix}=[['⢿','⣻','⣽','⣾'],['⡿','⣟','⣯','⣷']];
    $self->{logoVars}={x=>$self->{width}/2,  # integrated Turtle Graphics
		               y=>$self->{height}/2, # initial variables x, y and direction
		               d=>0,                 
		               p=>1,
		               GV=>{},
		               PC=>0,
		               Stk=>[],};
    bless $self,$class;
    $self->clear; # initiallises canvas to blank
    return $self;
}


=head3 C<$canvas-E<gt>draw()> , C<$canvas-E<gt>draw($row, $column)>  

Draws the canvas to the terminal window. Optional row and column
parameters may be passed to position the displayed canvas.  If 
borderStyle is specified, the border is drawn, If title is specified
this is added to the top border

=cut

sub draw{
	my ($self,$top,$left)=@_;  # the location on the screen can be overridden by passing row coloum position
	$top//=$self->{top};$left//=$self->{left};
	border($top-1,$left-1,$top+@{$self->{grid}}-1,$left+@{$self->{grid}->[0]},
	     $self->{borderStyle},$self->{borderColour},
	     $self->{title},$self->{titleColour})
	         if ((defined $self->{borderStyle})&&(ref $self->{grid} eq "ARRAY"));
	printAt($top,$left, [reverse @{$self->{grid}}]);
	print colour("reset");
	
}

=head3 C<$canvas-E<gt>as_string()>  

Returns the string containing the canvas of utf8 braille symbols, rows
being separated by newline.

=cut

sub as_string{
	my $self=shift;
	my $str="";
	$str.=join("",@$_)."\n" foreach (reverse @{$self->{grid}});
	return $str;
}

=head3 C<$canvas-E<gt>set($x,$y,$pixelValue)>  

Sets a particular pixel on (default if C<$pixelValue> not sent) or off.

=cut

 # this function creates a callback for plotting pixels directly
sub BresenhamPlot{   
	my($x,$y,$args)=@_;
	my ($canvas,$value)=(@$args);
	set($canvas,$x,$y,$value);
}

sub set{
	use integer;
    push @_, 1 if @_ == 3;
	my ($self,$x,$y,$value)=@_;
	#exit if out of bounds
	return unless(($x<$self->{width})&&($x>=0)&&($y<$self->{height})&&($y>=0));
	#convert coordinates to character / pixel offset position
	my ($chrX,$chrY,$xOffset,$yOffset)=$self->charOffset($x,$y);
	
	my $bChr=chop($self->{grid}->[$chrY]->[$chrX]);
	if ($value=~/^[a-z]/){$self->{grid}->[$chrY]->[$chrX]=colour($value);}
	elsif ($value=~/^\033\[/){$self->{grid}->[$chrY]->[$chrX]=$value;}
	# ensure character is a braille character to start with
	$bChr='⠀' if (ord($bChr)&0x2800 !=0x2800); 

	$self->{grid}->[$chrY]->[$chrX].=$value?         # if $value is false, unset, or else set pixel
	   (chr( ord($self->{setPix}  -> [$xOffset]->[$yOffset]) | ord($bChr) ) ):
	   (chr( ord($self->{unsetPix}-> [$xOffset]->[$yOffset]) & ord($bChr)));	
}

=head3 C<$canvas-E<gt>unset($x,$y)>  

Sets the pixel value at C<$x,$y> to blank 

=cut
sub unset{
	my ($self,$x,$y)=@_;
	$self->set($x,$y,0);
}

sub charOffset{  # gets the character grid position and offset within that character
	             # give the pixel position
	use integer;
	my ($self,$x,$y)=@_;	
	return -1 unless(($x<$self->{width})&&($x>=0)&&($y<$self->{height})&&($y>=0));
	my $chrX=$x/2;my $xOffset=$x- $chrX*2; 
	my $chrY=$y/4;my $yOffset=$y- $chrY*4;
	return ($chrX,$chrY,$xOffset,$yOffset);
	
}

=head3 C<$canvas-E<gt>pixel($x,$y)>  

Gets the pixel value at C<$x,$y>

=cut
sub pixel{ #get pixel value at coordinates
	my ($self,$x,$y,$value)=@_;
	
	#exit if out of bounds
	return unless(($x<($self->{width}-1))&&($x>=0)&&($y<($self->{height}-1))&&($x>=0));
	
	#convert coordinates to character / pixel offset position
	my $chrX=$x/2;my $xOffset=$x- $chrX*2; 
	my $chrY=$y/4;my $yOffset=$y- $chrY*4;
	my $orOp=ord($self->{setPix}-> [$xOffset]->[$yOffset]) & ord($self->{grid}->[$chrY]->[$chrX]);
	return $orOp == ord('⠀')?0:1;
}

=head3 C<$canvas-E<gt>clear()>  

Re-initialises the canvas with blank braille characters

=cut
sub clear{
	my ($self,$x1,$y1,$x2,$y2)=@_;
    if(@_<2){
		$self->{grid}=[map {[( '⠀')x ($self->{width}/2+($self->{width}%2?1:0))]}(0..($self->{height}/4+($self->{height}%4?1:0)))]
	}
	else{
		my @xr=$x1>$x2?($x2..$x1):($x1..$x2);
		my @yr=$y1>$y2?($y2..$y1):($y1..$y2);
		foreach my $y(@yr){
			foreach my $x(@xr){
				 $self->{grid}->[$y]->[$x]='⠀';
			}
		}
	}
}



# Pixel plotting primitives for shapes using Bresenham (Algorithm::Line::Bresenham)

=head3 C<$canvas-E<gt>line($x1,$y1,$x2,$y2,$value)>  

Uses Algorithm::Line::Bresenham to draw a line from C<$x1,$y1> to C<$x2,$y2>.
The optional value C<$value> sets or unsets the pixels. If C<$value> is a 
valid colour (see below) the line will be drawn with that colour.

=cut

sub line{
    push @_, 1 if @_ == 5;    # final optional parameter is set to one if not given
	my ($self,$x1,$y1,$x2,$y2,$value)=@_;
	my $setRef=\&Term::Graille::BresenhamPlot;
	my @points=Algorithm::Line::Bresenham::line($x1,$y1,$x2,$y2,$setRef,[$self,$value]);
}


=head3 C<$canvas-E<gt>circle($x1,$y1,$radius,$value)>  

Uses Algorithm::Line::Bresenham to draw a circle centered at C<$x1,$y1>
with radius C<$radius> to C<$x2,$y2>.
The optional value C<$value> sets or unsets the pixels. If C<$value> is a 
valid colour (see below) the line will be drawn with that colour.

=cut

sub circle{
    push @_, 1 if @_ == 4;
	my ($self,$x1,$y1,$radius,$value)=@_;
	my @points=Algorithm::Line::Bresenham::circle($x1,$y1,$radius);
	$self->set(@$_,$value) foreach (@points);
}


=head3 C<$canvas-E<gt>ellipse_rect($x1,$y1,$x2,$y2,$value)>    

Uses Algorithm::Line::Bresenham to draw a rectangular ellipse,  (an 
ellipse bounded by a rectangle defined by C<$x1,$y1,$x2,$y2>).
The optional value C<$value> sets or unsets the pixels. If C<$value> is a 
valid colour (see below) the line will be drawn with that colour.

=cut

sub ellipse_rect{
    push @_, 1 if @_ == 5;
	my ($self,$x1,$y1,$x2,$y2,$value)=@_;
	my @points=Algorithm::Line::Bresenham::ellipse_rect($x1,$y1,$x2,$y2);
	$self->set(@$_,$value) foreach (@points);
}

=head3 C<$canvas-E<gt>quad_bezier($x1,$y1,$x2,$y2,$x3,$y3,$value)>    

Uses Algorithm::Line::Bresenham to draw a quadratic bezier, defined by
end points C<$x1,$y1,$x3,$y3>) and control point C<$x2,$y2>.
The optional value C<$value> sets or unsets the pixels. If C<$value> is a 
valid colour (see below) the line will be drawn with that colour.

=cut


sub quad_bezier{
    push @_, 1 if @_ == 7;
	my ($self,$x1,$y1,$x2,$y2,$x3,$y3,$value)=@_;
	my @points=Algorithm::Line::Bresenham::quad_bezier($x1,$y1,$x2,$y2,$x3,$y3);
	$self->set(@$_,$value) foreach (@points);
}


=head3 C<$canvas-E<gt>thick_line($x1,$y1,$x2,$y2,$thickness,$value)>    

Uses Algorithm::Line::Bresenham to draw a thick line, defined by
end points C<$x1,$y1,$x2,$y2>) and thickness C<$thickness>.
The optional value C<$value> sets or unsets the pixels. If C<$value> is a 
valid colour (see below) the line will be drawn with that colour.

=cut


sub thick_line{
    push @_, 1 if @_ == 6;	
	my ($self,$x0,$y0,$x1,$y1,$thickness,$value)=@_;
	my @points=Algorithm::Line::Bresenham::thick_line($x0,$y0,$x1,$y1,$thickness);
	$self->set(@$_,$value) foreach (@points);
} 


=head3 C<$canvas-E<gt>varthick_line($x0,$y0,$x1,$y1,
       $left,$argL,
       $right,$argR, $value)=@_;>
       
Uses Algorithm::Line::Bresenham to draw a variable thickness, defined by
end points C<$x0,$y0,$x1,$y1>) and thickness defined by two user defined
functions, each function taking as arguments C<argE<lt>L|RE<gt>, $pos, $len>
and returning thickness of the left and right sides
of the line. The optional value C<$value> sets or unsets the pixels.
If C<$value> is a valid colour (see below) the line will be drawn with that colour.

=cut


sub varthick_line{
    push @_, 1 if @_ == 9;	
	my ($self,$x0,$y0,$x1,$y1,$left,$argL,$right,$argR,$value)=@_;
	my @points=Algorithm::Line::Bresenham::varthick_line($x0,$y0,$x1,$y1,$left,$argL,$right,$argR);
	$self->set(@$_,$value) foreach (@points);
	
}



=head3 C<$canvas-E<gt>polyline($x1,$y1,....,$xn,$yn,$value)>    

Uses Algorithm::Line::Bresenham to draw a poly line, form a
sequences of points.
The optional value C<$value> sets or unsets the pixels. If C<$value> is a 
valid colour (see below) the line will be drawn with that colour.

=cut

sub polyline{
    my $self=shift;
    my @vertices=@_;
    my $value= pop @vertices if (scalar @vertices & 1);
    $value//=1;
    my @points=Algorithm::Line::Bresenham::polyline(@vertices);
	$self->set(@$_,$value) foreach (@points);
}

sub degToRad{
	return $_[0]?3.14159267*$_[0]/180:0; ;
}

=head2 Character Level Functions;

=head3 C<$canvas-E<gt>scroll($direction,$wrap)>    

Scrolls in C<$direction>.  $direction may be
"l", "left", "r","right", "u","up","d", "down". 
Beacuse of the use of Braille characters, up/down scrolling is 4 pixels 
at a time, whereas left right scrolling is 2 pixels at a time. If 
C<$wrap> is a true value, the screen wraps around.

=cut

sub scroll{
	my ($self,$direction,$wrap,$numberOfChar)=@_;
	$numberOfChar//=1;$wrap//=0;
	for($direction){
		/^r/i && do{
			foreach my $row (0..$#{$self->{grid}}){
				my @r=@{$self->{grid}->[$row]};
				my @end=splice @r, -$numberOfChar, $numberOfChar;
				@end=('⠀')x$numberOfChar unless $wrap;
			#	unshift(@r,$wrap?@end:(('⠀')x$numberOfChar));
				$self->{grid}->[$row]=[@end,@r];
			}
			last;
		};
		
		/^l/i && do{
			foreach my $row (0..$#{$self->{grid}}){
				my @r=@{$self->{grid}->[$row]};
				my @end=splice @r, 0, $numberOfChar;
				@end=('⠀')x$numberOfChar unless $wrap;
			#	push(@r,$wrap?@end:(('⠀')x$numberOfChar));
				$self->{grid}->[$row]=[@r,@end];
			}
			last;
		};
				
		/^d/i && do{
				my @r=@{$self->{grid}};
				my @end=splice @r, 0, $numberOfChar;
				@end=([('⠀')x ($self->{width}/2+($self->{width}%2?1:0))])x$numberOfChar unless $wrap;
			#	push(@r,$wrap?@end:(([('⠀')x ($self->{width}/2+($self->{width}%2?1:0))])x$numberOfChar));
				$self->{grid}=[@r,@end];
			last;
		};
				
		/^u/i && do{
				my @r=@{$self->{grid}};
				my @end=splice @r, -$numberOfChar, $numberOfChar;
				@end=([('⠀')x ($self->{width}/2+($self->{width}%2?1:0))])x$numberOfChar unless $wrap;
			#	unshift(@r,$wrap?@end:(([('⠀')x ($self->{width}/2+($self->{width}%2?1:0))])x$numberOfChar));
				$self->{grid}=[@end,@r];
			last;
		};		
	}
}


=head3 C<$canvas-E<gt>blockBlit($block,$gridX, $gridY)> 

Allows blitting a 2d arrays to a grid location in the canvas.  Useful for 
printing using a Graille font.

=cut

sub blockBlit{  # needs protection
	my ($self, $blk, $gridX, $gridY)=@_;
	for my $x(0..$#{$blk->[0]}){
		for my $y(0..$#$blk){
			$self->{grid}->[$gridY+$y-$#$blk]->[$gridX+$x]=$blk->[$#$blk-$y]->[$x]
			   if $self->inGrid( $gridX+$x,$gridY+$y-$#$blk);
		}
	}
}

=head3 C<$canvas-E<gt>inGrid($gridX, $gridY)> 

Determines a character coordinate is in display area or not

=cut


sub inGrid{
	my ($self, $gridX, $gridY)=@_;
	(($gridX>=0) && ($gridY>=0) && ($gridX<$self->{width})  && ($gridY<$self->{height}))?1:0;
}


=head3 C<$canvas-E<gt>exportCanvas($filename)> , C<$canvas-E<gt>importCanvas($filename,[$toBuffer])>

This allows the loading and unloading of a canvas from a file.  There is
no checking of the dimension of the canvas being imported at the moment.
Import can be direct to the canvas, the function return the loaded data
as an ArrayRef, the optional c<$toBuffer> parameter, if true prevents 
loading the data onto the canvas.

=cut


sub exportCanvas{
	my ($self,$file)=@_;
	open (my $fh, ">$file") or die "can not open $file for writing $!";
	binmode($fh, ":utf8");
	print $fh $self->as_string();
	close $fh; 
	
}

sub importCanvas{
	my ($self,$file,$toBuffer)=@_;
	open (my $fh,'<', $file) or die "can not open $file for reading $!";
	my @grd;
	while (<$fh>){
		last if (@grd > ($self->{height}/4)); # stop if too big for canvas
		#  extend if too narrow for canvas, trucate if too wide
		unshift @grd, [split(//,substr($_.('⠀')x($self->{width}/2),0,$self->{width}/2))];
	}
	close $fh; 
	$self->{grid}=[@grd] unless $toBuffer;
	return [@grd];
}

=head3 C<$canvas-E<gt>textAt($x,$y,$text,$fmt)> 

Printing text on the C<$canvas>.  This is different from the exported 
C<printAt()> function.  the characters are printed on the C<$canvas>
and may be scrolled with the canvas and will overwrite or be over written
othe $canvas drawing actions.  The optional C<$fmt> allows the setting of colour; 

=cut


sub textAt{
	my ($self,$x,$y,$text,$fmt)=@_;
	return unless defined $text;
	my ($chrX,$chrY,$xOffset,$yOffset)=charOffset($self,$x,$y);
	if ($chrX!=-1){
		my @chrs=split(//,$text);
		my $lastChar=$chrX+(length $text)-1;
		$lastChar = $self->{width}/2 if ($lastChar>$self->{width}/2);
		$chrs[0]=colour($fmt).$chrs[0] if $fmt;
		for my $tc ($chrX..$lastChar){
		   $self->{grid}->[$chrY]->[$tc]=shift @chrs;
	   }

	}
}

sub resetUnpainted{
	my ($self,$chX,$chY)=@_;
	return if (($chX>$self->{width}/2)||($chX<0)||($chY>$self->{height}/4)||($chY<0));
	$self->{grid}->[$chY]->[$chX]=colour("reset").$self->{grid}->[$chY]->[$chX] if (length  $self->{grid}->[$chY]->[$chX] ==1);
}

sub stripColour{
	my $ch=shift;
	return chop $ch;
}

sub axis{
	my ($self,$xOrigin,$yOrigin,$xPos,$xNeg,$yPos,$yNeg,$xTics,$yTics)=@_;	         
	for my $y ($yOrigin-$yNeg..$yOrigin+$yPos) {     
			 $self->textAt($xOrigin,$y,'│');
	}
	$self->textAt($xOrigin-$xNeg,$yOrigin,'─' x (($xNeg+$xPos)/2));
	$self->textAt($xOrigin,$yOrigin,'┼' );

}


sub axis2{
	my ($self,$xOrigin,$yOrigin,$xPos,$xNeg,$yPos,$yNeg,$xTics,$yTics)=@_;
	$self->line($xOrigin-$xNeg,$yOrigin,$xOrigin+$xPos,$yOrigin);	         
	$self->line($xOrigin,$yOrigin-$yNeg,$xOrigin,$yOrigin+$yPos);
}


=head2  Enhancements
 
=head3 C<$canvas-E<gt>logo($script)>    

Interface to Graille's built in Turtle interpreter.
A string is taken and split by senicolons or newlines into instructions.
The instructions are trimmed, and split by the first space character into 
command and parameters. Very simple in other words. No syntax checking
is done 

C<"fd distance">  pen moves forward a certain distance.  
C<"lt angle">, C<"rt angle"> turns left or right.  
C<"bk distance"> pen moves back a certain distance. 
C<"pu">, C<"pd"> Pen is up or down, up means no drawing takes place,
and down means the turtle draws as it moves.
C<"dir"> set the direction at a specific angle in dgrees, 
with 0 being directly left.
C<"mv">moves pen to specific coordinates without drawing. 
C<"ce"> centers the turtle in the middle of a canvas
C<"sp"> allows animated drawing by specifiying the the number 
of centiseconds between instructions

=cut

sub logo{   
	my ($self,$script)=@_;
	my @commands= map{s/^\s+|\s+$//g; $_}split(/[\n;]+/,$script);
	foreach my $instr (@commands){
		next unless $instr;
		$instr=~s/#\.*$//;
		next if ($instr=~/#/);
		my ($c,$p)=split(/[\s]+/,$instr,2);
		my @pars=split(/,/,$p) if $p;
		for ($c){
		/^(fd|forward)/  && do{
			last unless ($pars[0] && (0+$pars[0]));
			my $x=$self->{logoVars}->{x}+$pars[0]*cos(degToRad($self->{logoVars}->{d}));
			my $y=$self->{logoVars}->{y}+$pars[0]*sin(degToRad($self->{logoVars}->{d}));
			if ($self->{logoVars}->{p}){
				$self->line($self->{logoVars}->{x},$self->{logoVars}->{y},$x,$y,($self->{logoVars}->{c}//1))
				}
			$self->{logoVars}->{y}=$y;
			$self->{logoVars}->{x}=$x;
			last;
		};
		/^(lt|left)/  && do{
			last unless ($pars[0] && (0+$pars[0]));
			$self->{logoVars}->{d}+=$pars[0];
			$self->{logoVars}->{d}-=360 while($self->{logoVars}->{d}>360);
			last;
		};
		/^(rt|right)/  && do{
			last unless ($pars[0] && ($pars[0]=~/^\d+$/));
			$self->{logoVars}->{d}-=$pars[0];
			$self->{logoVars}->{d}+=360 while($self->{logoVars}->{d}<360);
			last;
		};
		/^(bk|back)/  && do{
			$pars[0]=-$pars[0];
			$_="fd";
			redo;
		};
		/^pu/  && do{
			$self->{logoVars}->{p}=0;
			last;
		};
		/^pd/  && do{
			$self->{logoVars}->{p}=1;
			last;
		};
		/^pc/  && do{
			$self->{logoVars}->{c}=colour($pars[0]);
			last;
		};
		/^dir/  && do{
			$self->{logoVars}->{d}=$pars[0];
			last;
		};
		/^mv/  && do{
			$self->{logoVars}->{x}=$pars[0];			
			$self->{logoVars}->{y}=$pars[1 ];
			last;
		};
		/^ce/  && do{
			$self->{logoVars}->{x}=$self->{width}/2;			
			$self->{logoVars}->{y}=$self->{height}/2;
			last;
		};
		/^cs/  && do{
			$self->clear();
			last;
		};
		/^sp/ && do{
			$self->{logoVars}->{sp}=$pars[0];
			last
		}
		
		
	   }
	   if (defined $self->{logoVars}->{sp}){
		   sleep $self->{logoVars}->{sp}/100;
		   $self->draw();
	   }  
	}
}


=head3 Exported Routines   

Graille exports some functions for additional console graphical manipulation
This includes drawing of borders, printing characters at specific locations
in the terminal window, and colouring the characters, clearing the screen, etc.

  printAt($row,$column,@textRows); 

Prints text sent as a scalar, a list of scalars or a reference to list
of scalars, at a specific location on the screen.  Lists are printed 
from the same column but increasing row positions.

  border($top,$left,$bottom,$right,$style,$colour);

Draws a border box.

  paint($txt,$fmt)
  
Paints text the colour and background specified, $text may be a string, or ref 
to a list of strings. This is combined with C<printAt()> abouve

  clearScreen()
  
Guess what? clears the enire screen. This is different from C<$canvas-E<gt>clear()>
which clears the Graille canvas.


  block2braille($block)

Given a block of binary data (a 2D Array ref of 8-bit data), return a
corresponding 2d Array ref of braille blocks.  This is handy to convert, 
say, binary font data tinto Braille blocks for blittting into the canvas;

  pixelAt($block,$px,$py)
  
Given a binary block of data e.g.  a font or a sprite offered as a 2D Array ref
find the pixel value at a certain coordinate in that block.


=cut


our %borders=(
  simple=>{tl=>"+", t=>"-", tr=>"+", l=>"|", r=>"|", bl=>"+", b=>"-", br=>"+",ts=>"|",te=>"|",},
  double=>{tl=>"╔", t=>"═", tr=>"╗", l=>"║", r=>"║", bl=>"╚", b=>"═", br=>"╝",ts=>"╣",te=>"╠",},
  shadow=>{tl=>"┌", t=>"─", tr=>"╖", l=>"│", r=>"║", bl=>"╘", b=>"═", br=>"╝",ts=>"┨",te=>"┠",},
  thin  =>{tl=>"┌", t=>"─", tr=>"┐", l=>"│", r=>"│", bl=>"└", b=>"─", br=>"┘",ts=>"┤",te=>"├",},  
  thick =>{tl=>"┏", t=>"━", tr=>"┓", l=>"┃", r=>"┃", bl=>"┗", b=>"━", br=>"┛",ts=>"┫",te=>"┣",}, 
);

our %colours=(black   =>30,red   =>31,green   =>32,yellow   =>33,blue   =>34,magenta   =>35,cyan  =>36,white   =>37,
               on_black=>40,on_red=>41,on_green=>42,on_yellow=>43,on_blue=>44,on_magenta=>4,on_cyan=>46,on_white=>47,
               reset=>0, bold=>1, italic=>3, underline=>4, blink=>5, strikethrough=>9, invert=>7,);
               
sub printAt{
  my ($row,$column,@textRows)=@_;
  @textRows = @{$textRows[0]} if ref $textRows[0];  
  my $blit="\033[?25l";
  $blit.= defined $_?("\033[".$row++.";".$column."H".(ref $_?join("",@$_):$_)):"" foreach (@textRows) ;
  print $blit;
  print "\n"; # seems to flush the STDOUT buffer...if not then set $| to 1 
};

sub cursorAt{
	my ($r,$c)=@_;
	return "\033[?25l\033[".$r.";".$c."H";
}

sub border{
	my ($top,$left,$bottom,$right,$style,$colour,$title,$titleColour)=@_;
	$style//="simple";
	return unless exists $borders{$style};
	my @box=(colour($colour).$borders{$style}{tl}.($borders{$style}{t}x($right-$left)).$borders{$style}{tr});
	if ($title){
		my $titleSize=4+length $title;
		$title=$borders{$style}{ts}.colour($titleColour||"reset")." ".$title.colour($colour)." ".$borders{$style}{te};
		substr ($box[0],6,$titleSize)=$title;    
	};
	push @box,($borders{$style}{l}.(" "x($right-$left)).$borders{$style}{r})x($bottom-$top);;
	push @box,($borders{$style}{bl}.($borders{$style}{b}x($right-$left)).$borders{$style}{br}.colour("reset"));
	printAt($top,$left,\@box);
	
}

sub paint{
	my ($txt,$fmt)=@_;
	return $txt unless $fmt;
	return colour($fmt).$txt.colour("reset") unless ref $txt;
	return [map {colour($fmt).$_.colour("reset");} @$txt]
}

sub clearScreen{
	system($^O eq 'MSWin32'?'cls':'clear');
}

sub colour{
  my ($fmts)=@_;
  return "" unless $fmts;
  my @formats=map {lc $_} split / +/,$fmts;  
  return join "",map {defined $colours{$_}?"\033[$colours{$_}m":""} @formats;
}

sub wrapText{
	my ($str,$width)=@_;
	my @lines=();
	my $line="";
	$str=~s/ +/ /gm;
	$str=~s/\n/ \n /gm;
	foreach my $word(split / /,$str){
		if ($word eq "\n"){
			push @lines,$line;
			$line="";
		}
		elsif (1+length $line.$word > $width){
			push @lines,$line;
			$line=$word;
		}
		elsif ($line eq "") {
			$line=$word
		}
		else{
			$line=$line." ".$word
		}
	}
	push @lines,$line;
	return \@lines;
}



# given an 8 bit block of data, produce a braille block
sub block2braille{
	use integer;
	my ($block)=@_;
	my $pixelHeight=@$block;
	my $pixelWidth=@{$block->[0]}*8;
	my $brCharWidth=$pixelWidth/2 +($pixelWidth & 1?1:0);
	my $brCharHeight=$pixelHeight/4 + ($pixelHeight & 1?1:0);
	my $brBlk=[];
	
	foreach my $chX(0..($brCharWidth-1)){
		foreach my $chY(0..($brCharHeight-1)){
			my $b=ord('⠀');
			$b|=ord('⠁') if (pixelAt($block,$chX*2,$chY*4));
			$b|=ord('⠂') if (pixelAt($block,$chX*2,$chY*4+1));
			$b|=ord('⠄') if (pixelAt($block,$chX*2,$chY*4+2));
			$b|=ord('⡀') if (pixelAt($block,$chX*2,$chY*4+3));
			$b|=ord('⠈') if (pixelAt($block,$chX*2+1,$chY*4));
			$b|=ord('⠐') if (pixelAt($block,$chX*2+1,$chY*4+1));
			$b|=ord('⠠') if (pixelAt($block,$chX*2+1,$chY*4+2));
			$b|=ord('⢀') if (pixelAt($block,$chX*2+1,$chY*4+3));
			$brBlk->[$chY]->[$chX]=chr($b);
		}
	}
	return $brBlk;
}

# given a block of binary data identify pixel value at a
# particular position
sub pixelAt{ 
	use integer;
	my ($blk,$px,$py)=@_;
	return (($blk->[$py]->[$px/8]) & 2**(7-($px%8)));
}


sub DESTROY{
  if ($^O eq "MSWin32") {
	 system("chcp 850");
  }
}

1;
__END__
=head1 AUTHOR

Saif Ahmed

=head1 LICENSE

Artistic

=head1 INSTALLATION



Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

=cut
