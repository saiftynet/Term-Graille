=head1 NAME

Term::Graille - Terminal Graphics using Braille

=head1 SYNOPSIS
 
  my $canvas = Term::Graille->new(
    width  => 72,    # pixel width
    height => 64,    # pixel height
    top=>3,          # row position in terminal (optional,defaults to 1)
    left=>10,        # column position (optional,defaults to 1)
    borderStyle => "double",  # 
  );

=head1 DESCRIPTION

Ispired by Drawille by asciimoo, which has many variants (including 
a perl variant Term::Drawille by RHOELZ), this is a clone with a few
extras. The goal for better performance and features. with built-in
turtle-like graphics, line and curve drawing (Algorithm::Line::Bresenham),
scrolling, border setting, and more in development.

=head1 FUNCTIONS

=cut



package Term::Graille;

use strict;use warnings;
our $VERSION="0.02";
use utf8;
use open ":std", ":encoding(UTF-8)";
use lib "../";
use Algorithm::Line::Bresenham 0.13;
use Time::HiRes "sleep";


=head2 C<Term::Graille->new(%params)>

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


sub draw{
	my ($self,$top,$left)=@_;  # the location on the screen can be overridden by passing row coloum position
	$top//=$self->{top};$left//=$self->{left};
	Display::border($top-1,$left-1,$top+@{$self->{grid}}-1,$left+@{$self->{grid}->[0]},$self->{borderStyle},$self->{borderColour})
	    if defined $self->{borderStyle};
	Display::printAt($top-1,$left+3,Display::paint($self->{title},$self->{titleColour})) if defined $self->{title}; ;
	Display::printAt($top,$left, [reverse @{$self->{grid}}]);
}


sub as_string{
	my $self=shift;
	my $str="";
	$str.=join("",@$_)."\n" foreach (reverse @{$self->{grid}});
	return $str;
}

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

sub clear{
	my $self=shift;
    $self->{grid}=[map {[('⠀')x ($self->{width}/2+($self->{width}%2?1:0))]}(0..($self->{height}/4+($self->{height}%4?1:0)))];
                  # arrays containing Braille characters to bitwise OR or AND to set or unset individual pixels
}

# Pixel plotting primitives for shapes using Bresenham (Algorithm::Line::Bresenham)

sub line{
    push @_, 1 if @_ == 5;    # final optional parameter is set to one if not given
	my ($self,$x1,$y1,$x2,$y2,$value)=@_;
	my @points=Algorithm::Line::Bresenham::line($x1,$y1,$x2,$y2);
	$self->set(@$_,$value) foreach (@points);
}

sub circle{
    push @_, 1 if @_ == 4;
	my ($self,$x1,$y1,$radius,$value)=@_;
	my @points=Algorithm::Line::Bresenham::circle($x1,$y1,$radius);
	$self->set(@$_,$value) foreach (@points);
}

sub ellipse_rect{
    push @_, 1 if @_ == 5;
	my ($self,$x1,$y1,$x2,$y2,$value)=@_;
	my @points=Algorithm::Line::Bresenham::ellipse_rect($x1,$y1,$x2,$y2);
	$self->set(@$_,$value) foreach (@points);
}

sub quad_bezier{
    push @_, 1 if @_ == 7;
	my ($self,$x1,$y1,$x2,$y2,$x3,$y3,$value)=@_;
	my @points=Algorithm::Line::Bresenham::quad_bezier($x1,$y1,$x2,$y2,$x3,$y3);
	$self->set(@$_,$value) foreach (@points);
}

sub polyline{
    my $self=shift;
    my @vertices=@_;
    my $value= pop @vertices unless @vertices % 2;
    $value//=1;
    my @points=Algorithm::Line::Bresenham::polyline(@vertices);
	$self->set(@$_,$value) foreach (@points);
}



sub degToRad{
	return 3.14159267*$_[0]/180 ;
}

sub scroll{
	my ($self,$direction,$numberOfChar,$wrap)=@_;
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


# turtle graphics subroutine, parses and interprets a string of drawing instructions 
sub logo{   
	my ($self,$script)=@_;
	my @commands= map{s/^\s+|\s+$//g; $_}split(/[\n;]+/,$script);
	foreach my $instr (@commands){
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


package Display;

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

Artististic, Same as Perl

=head1 INSTALLATION


Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

=cut
