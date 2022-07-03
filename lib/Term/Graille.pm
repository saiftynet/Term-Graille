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

<img src="https://user-images.githubusercontent.com/34284663/177032294-55dfda02-c24d-45c8-92ab-8c07ad39df66.gif">

=end html


=head1 FUNCTIONS

=cut

package Term::Graille;

use strict;use warnings;
our $VERSION="0.04";
use utf8;
use open ":std", ":encoding(UTF-8)";
use lib "../";
use base 'Exporter';
our @EXPORT_OK = qw/colour paint printAt clearScreen border/;
use Algorithm::Line::Bresenham 0.13;
use Time::HiRes "sleep";


=head2 C<my $canvas=Term::Graille-E<gt>new(%params)>

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
    for my $key (qw/borderStyle borderColour title titleColour top left/){
		$self->{ $key}=$params{$key} if exists $params{$key}
	}
	$self->{top}//=1;
	$self->{left}//=1;
	                            
    $self->{setPix}=[['⡀','⠄','⠂','⠁'],['⢀','⠠','⠐','⠈']];
    $self->{unsetPix}=[['⢿','⣻','⣽','⣾'],['⡿','⣟','⣯','⣷']];
    $self->{logoVars}={x=>$self->{width}/2,  # integrated Turtle Graphics
		               y=>$self->{height}/2, # initial variables x, y and direction
		               d=>0,                 
		               p=>1};
    bless $self,$class;
    $self->clear; # initiallises canvas to blank
    return $self;
}


=head2 C<$canvas-E<gt>draw()> , C<$canvas-E<gt>draw($row, $column)>  

Draws the canvas to the terminal window. Optional row and column
parameters may be passed to position the displayed canvas.  If 
borderStyle is specified, the border is drawn, If title is specified
this is added to the top border

=cut

sub draw{
	my ($self,$top,$left)=@_;  # the location on the screen can be overridden by passing row coloum position
	$top//=$self->{top};$left//=$self->{left};
	border($top-1,$left-1,$top+@{$self->{grid}}-1,$left+@{$self->{grid}->[0]},$self->{borderStyle},$self->{borderColour})
	    if defined $self->{borderStyle};
	printAt($top-1,$left+3,paint($self->{title},$self->{titleColour})) if defined $self->{title}; ;
	printAt($top,$left, [reverse @{$self->{grid}}]);
}

=head2 C<$canvas-E<gt>as_string()>  

Returns the string containing the canvas of utf8 braille symbols, rows
being separated by newline.

=cut

sub as_string{
	my $self=shift;
	my $str="";
	$str.=join("",@$_)."\n" foreach (reverse @{$self->{grid}});
	return $str;
}

=head2 C<$canvas-E<gt>set($x,$y,$pixelValue)>  

Sets a particular pixel on (default if C<$pixelValue> not sent) or off.

=cut
sub set{
	use integer;
    push @_, 1 if @_ == 3;
	my ($self,$x,$y,$value)=@_;
	
	#exit if out of bounds
	return unless(($x<=$self->{width})&&($x>=0)&&($y<$self->{height})&&($y>=0));
	
	#convert coordinates to character / pixel offset position
	my $chrX=$x/2;my $xOffset=$x- $chrX*2; 
	my $chrY=$y/4;my $yOffset=$y- $chrY*4;
	$self->{grid}->[$chrY]->[$chrX]=$value?         # if $value is false, unset, or else set pixel
	   (chr( ord($self->{setPix}  -> [$xOffset]->[$yOffset]) | ord($self->{grid}->[$chrY]->[$chrX]) ) ):
	   (chr( ord($self->{unsetPix}-> [$xOffset]->[$yOffset]) & ord($self->{grid}->[$chrY]->[$chrX])));
}

=head2 C<$canvas-E<gt>set($x,$y)>  

Sets the pixel value at C<$x,$y> to blank 

=cut
sub unset{
	my ($self,$x,$y)=@_;
	$self->set($x,$y,0);
}

sub charOffset{  # gets the character grid position and offset within that character
	             # give the pixel position
	my ($self,$x,$y)=@_;	
	return undef unless(($x<$self->{width})&&($x>=0)&&($y<$self->{height})&&($x>=0));
	my $chrX=$x/2;my $xOffset=$x- $chrX*2; 
	my $chrY=$y/4;my $yOffset=$y- $chrY*4;
	return ($chrX,$chrY,$xOffset,$yOffset);
	
}

=head2 C<$canvas-E<gt>pixel($x,$y)>  

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

=head2 C<$canvas-E<gt>clear()>  

Re-initialises the canvas with blank braille characters

=cut
sub clear{
	my $self=shift;
    $self->{grid}=[map {[('⠀')x ($self->{width}/2+($self->{width}%2?1:0))]}(0..($self->{height}/4+($self->{height}%4?1:0)))];
}

# Pixel plotting primitives for shapes using Bresenham (Algorithm::Line::Bresenham)

=head2 C<$canvas-E<gt>line($x1,$y1,$x2,$y2,$value)>  

Uses Algorithm::Line::Bresenham to draw a line from C<$x1,$y1> to C<$x2,$y2>.
The optional value C<$value> sets or unsets the pixels

=cut

sub line{
    push @_, 1 if @_ == 5;    # final optional parameter is set to one if not given
	my ($self,$x1,$y1,$x2,$y2,$value)=@_;
	my @points=Algorithm::Line::Bresenham::line($x1,$y1,$x2,$y2);
	$self->set(@$_,$value) foreach (@points);
}


=head2 C<$canvas-E<gt>circle($x1,$y1,$radius,$value)>  

Uses Algorithm::Line::Bresenham to draw a circle centered at C<$x1,$y1>
with radius C<$radius> to C<$x2,$y2>.
The optional value C<$value> sets or unsets the pixels

=cut

sub circle{
    push @_, 1 if @_ == 4;
	my ($self,$x1,$y1,$radius,$value)=@_;
	my @points=Algorithm::Line::Bresenham::circle($x1,$y1,$radius);
	$self->set(@$_,$value) foreach (@points);
}


=head2 C<$canvas-E<gt>ellipse_rect($x1,$y1,$x2,$y2,$value)>    

Uses Algorithm::Line::Bresenham to draw a rectangular ellipse,  (an 
ellipse bounded by a rectangle defined by C<$x1,$y1,$x2,$y2>).
The optional value C<$value> sets or unsets the pixels

=cut

sub ellipse_rect{
    push @_, 1 if @_ == 5;
	my ($self,$x1,$y1,$x2,$y2,$value)=@_;
	my @points=Algorithm::Line::Bresenham::ellipse_rect($x1,$y1,$x2,$y2);
	$self->set(@$_,$value) foreach (@points);
}

=head2 C<$canvas-E<gt>quad_bezier($x1,$y1,$x2,$y2,$x3,$y3,$value)>    

Uses Algorithm::Line::Bresenham to draw a quadratic bezier, defined by
end points C<$x1,$y1,$x3,$y3>) and control point C<$x2,$y2>.
The optional value C<$value> sets or unsets the pixels

=cut


sub quad_bezier{
    push @_, 1 if @_ == 7;
	my ($self,$x1,$y1,$x2,$y2,$x3,$y3,$value)=@_;
	my @points=Algorithm::Line::Bresenham::quad_bezier($x1,$y1,$x2,$y2,$x3,$y3);
	$self->set(@$_,$value) foreach (@points);
}

=head2 C<$canvas-E<gt>polyline($x1,$y1,....,$xn,$yn,$value)>    

Uses Algorithm::Line::Bresenham to draw a poly line, form a
sequences of points.
The optional value C<$value> sets or unsets the pixels

=cut


sub polyline{
    my $self=shift;
    my @vertices=@_;
    my $value= pop @vertices unless (@vertices & 1);
    $value//=1;
    my @points=Algorithm::Line::Bresenham::polyline(@vertices);
	$self->set(@$_,$value) foreach (@points);
}

sub degToRad{
	return 3.14159267*$_[0]/180 ;
}

=head2 C<$canvas-E<gt>scroll($direction,$wrap)>    

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
				my $end=pop(@r);
				unshift(@r,$wrap?$end:'⠀');
				$self->{grid}->[$row]=\@r;
			}
			last;
		};
		
		/^l/i && do{
			foreach my $row (0..$#{$self->{grid}}){
				my @r=@{$self->{grid}->[$row]};
				my $end=shift(@r);
				push(@r,$wrap?$end:'⠀');
				$self->{grid}->[$row]=\@r;
			}
			last;
		};
				
		/^d/i && do{
				my @r=@{$self->{grid}};
				my $end=shift(@r);
				push(@r,$wrap?$end:[('⠀')x ($self->{width}/2+($self->{width}%2?1:0))]);
				$self->{grid}=\@r;
			last;
		};
				
		/^u/i && do{
				my @r=@{$self->{grid}};
				my $end=pop(@r);
				unshift(@r,$wrap?$end:[('⠀')x ($self->{width}/2+($self->{width}%2?1:0))]);
				$self->{grid}=\@r;
			last;
		};		
	}
}


=head2 C<$canvas-E<gt>logo($script)>    

Interface to Graille's built in Turtle interpreter.
A string is taken and split by senicolons or newlines into intsructions.
The instructions are trimmed, and split by the first space character into 
command and parameters. Very simple in other words.

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
		next if ($instr=~/#/);
		my ($c,$p)=split(/[\s]+/,$instr,2);
		my @pars=split(/,/,$p) if $p;
		for ($c){
		/^fd/  && do{
			my $x=$self->{logoVars}->{x}+$pars[0]*cos(degToRad($self->{logoVars}->{d}));
			my $y=$self->{logoVars}->{y}+$pars[0]*sin(degToRad($self->{logoVars}->{d}));
			if ($self->{logoVars}->{p}){
				$self->line($self->{logoVars}->{x},$self->{logoVars}->{y},$x,$y)
				}
			$self->{logoVars}->{y}=$y;
			$self->{logoVars}->{x}=$x;
			last;
		};
		/^lt/  && do{
			$self->{logoVars}->{d}+=$pars[0];
			$self->{logoVars}->{d}-=360 while($self->{logoVars}->{d}>360);
			last;
		};
		/^rt/  && do{
			$self->{logoVars}->{d}-=$pars[0];
			$self->{logoVars}->{d}+=360 while($self->{logoVars}->{d}<360);
			last;
		};
		/^bk/  && do{
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

our %borders=(
  simple=>{tl=>"+", t=>"-", tr=>"+", l=>"|", r=>"|", bl=>"+", b=>"-", br=>"+",},
  double=>{tl=>"╔", t=>"═", tr=>"╗", l=>"║", r=>"║", bl=>"╚", b=>"═", br=>"╝",},
  shadow=>{tl=>"┌", t=>"─", tr=>"╖", l=>"│", r=>"║", bl=>"╘", b=>"═", br=>"╝",},
  thin  =>{tl=>"┌", t=>"─", tr=>"┐", l=>"│", r=>"│", bl=>"└", b=>"─", br=>"┘",},  
  thick =>{tl=>"┏", t=>"━", tr=>"┓", l=>"┃", r=>"┃", bl=>"┗", b=>"━", br=>"┛",}, 
);

our %colours=(black   =>30,red   =>31,green   =>32,yellow   =>33,blue   =>34,magenta   =>35,cyan  =>36,white   =>37,
               on_black=>40,on_red=>41,on_green=>42,on_yellow=>43,on_blue=>44,on_magenta=>4,on_cyan=>46,on_white=>47,
               reset=>0, bold=>1, italic=>3, underline=>4, strikethrough=>9,);
sub printAt{
  my ($row,$column,@textRows)=@_;
  @textRows = @{$textRows[0]} if ref $textRows[0];  
  my $blit="\033[?25l";
  $blit.= "\033[".$row++.";".$column."H".(ref $_?join("",@$_):$_) foreach (@textRows) ;
  print $blit;
  print "\n"; # seems to flush the STDOUT buffer...if not then set $| to 1 
};

sub border{
	my ($top,$left,$bottom,$right,$style,$colour)=@_;
	$style//="simple";
	return unless exists $borders{$style};
	my @box=(colour($colour).$borders{$style}{tl}.($borders{$style}{t}x($right-$left)).$borders{$style}{tr});
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
