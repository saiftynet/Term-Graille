package Term::Graille::Chart;
use strict; use warnings;
use utf8;
use Term::Graille  qw/colour paint printAt clearScreen border blockBlit block2braille pixelAt/;
use open ":std", ":encoding(UTF-8)";

our $VERSION="0.08";

my $chart=new Term::Graille::Chart(
     hOffset=>10,
     BottomAxis=>{tickSeparation=>7,tickLabels=>[" ",qw/ red green yellow violet indigo blue/," "]},
     LeftAxis  =>{tickSeparation=>2,tickLabels=>[0..5]},
     RightAxis  =>{tickSeparation=>3,tickLabels=>[0..3]},
     TopAxis=>{tickSeparation=>7,tickLabels=>[" ",qw/ red green yellow violet blue/," "]},
     );
print "\n\n", join("\n",@{$chart->mergeAxes()});

sub new{
    my ($class, %params) = @_; 
    my $self={};
    $self->{hOffset}=$params{hOffset}//6;
    $self->{vOffset}=$params{vOffset}//6;
    $self->{Axes}={};
    bless $self,$class;
    foreach my $side (qw/BottomAxis TopAxis LeftAxis RightAxis/){
		next unless $params{$side};
		$self->{Axes}->{$side}->{params}=$params{$side};;
		$self->makeAxis($side) ;
	}
    return $self;
    
}

sub makeAxis{
	my ($self,$side)=@_;
	my $params=$self->{Axes}->{$side}->{params};
	my $tickSeparation=$$params{tickSeparation};
	my $tickLabels=$$params{tickLabels};
	my $title=$$params{title};
	my @axis=();
	if ($side=~	/BottomAxis|TopAxis/){
		my $gap="─"x( $tickSeparation-1);
		my $axis=(" "x$self->{hOffset})."┼".(($gap."┼")x(@{$tickLabels}-2)).$gap."┤";
		my $axisWidth=$tickSeparation*$#{$tickLabels}+1;
		$self->{chartWidth}=$axisWidth if (!$self->{chartWidth}  || $axisWidth >$self->{chartWidth});
		my $tickLabelLine=(" "x$self->{hOffset});
		foreach my $tick (0..$#{$tickLabels}){ 
			substr ($tickLabelLine, ($self->{hOffset}+$tick*$tickSeparation+1)-length($tickLabels->[$tick])/2,)=$tickLabels->[$tick];
			$tickLabelLine.=" "x($tickSeparation-1);
		}
		$self->{$side}=$side=~/^T/?[$tickLabelLine,$axis]:[$axis,$tickLabelLine];	
	
	}
	else{
		
		my $axisHeight=$tickSeparation*$#{$tickLabels}+1;
		$self->{chartHeight}=$axisHeight if (!$self->{chartHeight}  || $axisHeight >$self->{chartHeight});
		if ($side=~/^L/){
			my @gap=(" "x$self->{hOffset}."│")x($tickSeparation-1);
			foreach my $tick (0..$#{$tickLabels}){
				my $row=" "x$self->{hOffset}."│";	
				substr ($row,$self->{hOffset}-(1+length $tickLabels->[$tick]),)=$tickLabels->[$tick]." ┼";
				unshift @axis,@gap if $tick;
				unshift @axis,$row;
			}			
		}
		else{
			my @gap=("│")x($tickSeparation-1);
			foreach my $tick (0..$#{$tickLabels}){
				my $row="┼ ".$tickLabels->[$tick];
				unshift @axis,@gap if $tick;
				unshift @axis,$row;
			}					
		}
		
		$self->{$side}=[@axis]
	}
}	

sub mergeAxes{
	my $self=shift;
	my @Axes;
	if (exists $self->{LeftAxis} && exists $self->{BottomAxis} ){
		@Axes=@{$self->{LeftAxis}};
		my $bA=$self->{BottomAxis}->[0];
		$bA=~s/^ +//;
		substr ($Axes[-1],-1,)=	$bA;
		push @Axes,$self->{BottomAxis}->[1];
	}
	else {
		return ["unable to create axes"];
	}
	if (exists $self->{RightAxis}){
		my @rA=@{$self->{RightAxis}};
		substr ($Axes[-2],-1,)=	$rA[-1];
		for (my $i=2;$i<=@rA;$i++){
			$Axes[@Axes-$i-1].=(" "x($self->{chartWidth}-2)).$rA[@rA-$i];
		}
	}
	if (exists $self->{TopAxis}){
		my $tA=$self->{TopAxis}->[1];
		$tA=~s/^ +//;
		substr ($Axes[0],$self->{hOffset},$self->{chartWidth})=	$tA;
		unshift @Axes,$self->{TopAxis}->[0];
		
	}
	return [@Axes];
}

sub autoAxis{
	my ($self,$side,$data,$nTicks,$axisLength)=@_;
	
	
}





# given a list of numbers determines whether the numbers cross zero;
sub zeroCrossing{
   my @list=sort @_;
   return ($list[0] <0 && $list[-1] >0)?1:0;
}

#given a list of data (as an array or arrayref, return minimum and maximum)
sub minmax{
   my @list=@_;
   @list=@{$list[0]} if (ref $list[0]);
   my $max=my $min = shift @list;;
   foreach my $v (@list){
      $max=$v if $max<$v;
	  $min=$v if $min>$v;   
   }
   return ($min,$max)
}

# niceTicks
# takes minimum value, maximum value and number of desired ticks;
# returns list of ticks
sub niceTicks{
   my ($axisStart,$axisEnd,$nTicks)=@_;
   ($axisStart,$axisEnd,my $tick)=niceAxis($axisStart,$axisEnd,$nTicks);
   my @tickList=($axisStart);
   push @tickList,$tickList[-1]+$tick while ($tickList[-1]<=$axisEnd);
   return @tickList;
}

# niceAxis
# takes minimum value, maximum value and number of desired ticks;
# returns nice axis start, axis end and gap between ticks
sub niceAxis{   
   my ($axisStart,$axisEnd,$nTicks)=@_;
   $nTicks//=5;
   my $axisWidth=$axisEnd-$axisStart;
   return undef unless $axisWidth>0;  # error is start >= end 
   
   my $niceRange=niceNumber($axisWidth,0);
   my $niceTick =niceNumber($niceRange/($nTicks-1) , 1);  
   $axisStart=floor($axisStart/$niceTick)*$niceTick;
   $axisEnd = ceil($axisEnd/$niceTick)*$niceTick;
   return ($axisStart,$axisEnd,$niceTick)  
}

#
sub niceNumber{
  my ($value,$round)=@_;
 
  my $exp= floor(log($value)/log(10));
  my $fraction=$value/(10**$exp);
  
	if ($round){
	   for ($fraction){
		 $_ < 1.5  && return  1*(10**$exp);
		 $_ < 3.0  && return  2*(10**$exp);
		 $_ < 7.0  && return  5*(10**$exp);
		 return  10*(10**$exp);
	   }
	}
	else{
	   for ($fraction){
		 $_ < 1  && return  1*(10**$exp);
		 $_ < 2  && return  2*(10**$exp);
		 $_ < 4  && return  4*(10**$exp);
		 return  10*(10**$exp);
	   }
	}
}


# saves having to use POSIX
sub floor{
  my $v=shift;
  return int($v)-($v<0?1:0);
}

# saves having to use POSIX
sub ceil{
  my $v=shift;
  return int($v)+ ($v==int($v)?0:1);
}



	
1;	
	

