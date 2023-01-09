package  Term::Graille::Sprite;

use strict;use warnings;
use lib "../../../lib";
use Term::Graille qw/colour printAt clearScreen border cursorAt wrapText/;
use utf8;

our $VERSION=0.11;

our $setPix=[['⡀','⠄','⠂','⠁'],['⢀','⠠','⠐','⠈']];
our $unsetPix=[['⢿','⣻','⣽','⣾'],['⡿','⣟','⣯','⣷']];

=head3 C<my $sprite=Term::Graille::Sprite-E<gt>new(%parama)>

Creates a new dialog box; params are
C<options> the possible options that may be selected  
C<redraw> This is a function to redraws the application screen.
The dialog box may overwrite parts of the application screen, and this 
function needs to be provided to restore the screen.
C<callback> The dialog does not call any functions itself, instead returns the
button value pressed. if the $dialog->{entry} is set this is also sent.  In
prompts, the entry is populated by user.  It is upto the main application
to use this data (the callback function supplied)
C<pos> Optional. The default position is [2,2], but setting this parameter allows 
the dialog to be placed elsewhere
C<highlightColour> Optional. The selected item is highlighted default "black on_white"
C<normalColour> Optional. The normal colour of text items "white on_black"

=cut

sub new{
    my ($class,%params) = @_;  
    my $self={};
    bless $self,$class;
	$self->{pos}=$params{pos}//[0,0]; # x,y position of top left corner of sprite
	$self->{prevPos}=[@{$self->{pos}}]; # x,y position of top left corner of sprite
    if ($params{shape}){   # if shapename  specified, a shape name
		                   # must be in conjuction with a sprite bank 
		$self->{data}=$params{shape}; # is used as an index for the shape data
	}
	elsif ($params{file}){     # if file specified, a shape loaded from file
		$self->load($params{file});
	}
	else{                      # data maybe defined directly, or a single @ character used
		$self->{data}=$params{data}// [["⬤"]];  
	}
	if (ref $self->{data}){
		$self->{geometry}=[scalar @{$self->{data}->[0]},scalar @{$self->{data}}];
	};
	if (exists $params{etc}){
		$self->{etc}=$params{etc};
	};
	$self->{bounds}=$params{bounds}//[0,0,60,60];# boundary of sprites
	if (exists $params{vel}){$self->{vel}=$params{vel}}; # dx,dy  displacement vector
	$self->{skip}=$params{skip}//0;             # skip this many cycles for each move
	$self->{skipped}=0;                         # this many skipped so far
	$self->{destroyed}=0;
	$self->{active}=1;
	$self->{animationPosition}=0;             # skip this many cycles for each move
	$self->{animationSequence}=[];            # this many skipped so far
	$self->{dataBuffer}={};            # buffer containing animations and rotations etc
	return $self;	
}

=head3 C<$sprite-E<gt>scroll(Direction)>

=cut

sub scroll{
	my ($self,$dir)=@_;
	my @yList=my @xList=(0..15);
	my $dx=my $dy=0;
	if    ($dir=~/L/){	pop   @xList;	$dx=+1;	}
	elsif ($dir=~/R/){  shift @xList;	$dx=-1;	}
	elsif ($dir=~/D/){  pop   @yList;	$dy=+1;	}
	elsif ($dir=~/U/){  shift @yList;	$dy=-1;	}
	
	my $newSp=[map {[("⠀")x@{$self->{data}->[0]}]}(0..$#{$self->{data}})];
	
	foreach my $y1(@yList){
		foreach my $x1(@xList){
			set($newSp,$x1,$y1, $self->getValue($self,$x1+$dx,$y1+$dy));
		}
	}
	$self->{data}=$newSp;
}


=head3 C<$sprite-E<gt>rotate(Direction)>

=cut

sub rotate{  
	my ($self,$rot)=@_;
	my $newSprite=[map {[("⠀")x8]}(0..3)];
	if ($rot eq "RL Diag"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($self,15-$d,15-$c))
			}
		}
	}
	elsif ($rot eq "LR Diag"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($self,$d,$c))
			}
		}
	}
	elsif ($rot eq "Horiz"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($self,15-$c,$d))
			}
		}
	}
	elsif ($rot eq "Vert"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($self,$c,15-$d))
			}
		}
	}
	elsif ($rot eq "270"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($self,$d,15-$c))
			}
		}
	}
	elsif ($rot eq "90"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($self,15-$d,$c))
			}
		}
	}
	elsif ($rot eq "180"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($self,15-$c,15-$d))
			}
		}
	}
	else{
		return
	}
	$self->{data}=$newSprite;
}


=head3 C<$sprite-E<gt>getValue($x,$y)>
    Get Pixel value at $x ,$y of sprite, 0,0 is bottom left of sprite
=cut

sub getValue{        # pixel value at postion on sprite
	my ($self,$x,$y)=@_;
	my ($chX,$chY,$r,$c)=locate($self,$x,$y);
	my $contents=$self->{data}->[$#{$self->{data}}-$chY]->[$chX];
	my $bChr=chop($contents);
	my $orOp=(ord($unsetPix->[$c]->[$r]) | ord($bChr));
	#printAt(22,20,"$x,$y ".$unsetPix->[$c]->[$r]." ".$sprite->[$#{$sprite}-$chY]->[$chX]);
	return chr($orOp) eq '⣿'?1:0;	
}
	
sub load{
	my ($self,$fileName)=@_;
	return undef unless (-e $fileName);
	open my $grf,"<:utf8",$fileName or return undef;
	my $data="";
	$data.=$_ while(<$grf>);
	close $grf;
	$self->{data}=eval($data);
	
}

sub set{
	my ($self,$x,$y,$value)=@_;
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $chHeight=scalar @{$self->{data}};
	my $contents=$self->{data}->[$#{$self->{data}}-$chY]->[$chX];	
	my $bChr=chop($contents);
	if ($value=~/^[a-z]/){$contents=colour($value);}
	elsif ($value=~/^\033\[/){$contents=$value;}
	else {$contents=""};
	# ensure character is a braille character to start with
	$bChr='⠀' if (ord($bChr)&0x2800 !=0x2800); 
	
	$self->{data}->[$#{$self->{data}}-$chY]->[$chX]=$contents.$value?         # if $value is false, unset, or else set pixel
	   (chr( ord($setPix-> [$c]->[$r]) | ord($bChr) ) ):
	   (chr( ord($unsetPix-> [$c]->[$r]) & ord($bChr)));
}

# internal function that gets character and $row column from
# sprite coordinates (0,0)=bottem left of sprite.

sub locate{
	my ($x,$y)=@_;
	my $chX=int($x/2);my $c=$x-2*$chX;
	my $chY=int($y/4);my $r=$y-4*$chY;
	return ($chX,$chY,$r,$c);
}


=head3 C<$sprite-E<gt>move([$x,$y])>
   move sprite either using its own velocity vector
   or a velocity vector passes as an Arrayref
=cut

sub move{
	my($self,$disp)=@_;
	if ($disp) {
		$self->{prevPos}=[@{$self->{pos}}];
		$self->{pos}=[$self->{pos}->[0]+$disp->[0],$self->{pos}->[1]+$disp->[1]];
	}
	elsif (! defined $self->{vel}) {return}
	else {
		$self->{prevPos}=[@{$self->{pos}}];
		$self->{pos}=[$self->{pos}->[0]+$self->{vel}->[0],$self->{pos}->[1]+$self->{vel}->[1]];
	}
	
}

sub moveTo{
	my($self,$pos)=@_;
	$self->{pos}=$pos;
}	


sub moveBack{
	my($self,$disp)=@_;
	if ($disp) {
		$self->{prevPos}=[@{$self->{pos}}];
		$self->{pos}=[$self->{pos}->[0]-$disp->[0],$self->{pos}->[1]-$disp->[1]];
		}
	elsif (! defined $self->{vel}) {return}
	else {
		$self->{prevPos}=[@{$self->{pos}}];
		$self->{pos}=[$self->{pos}->[0]-$self->{vel}->[0],$self->{pos}->[1]-$self->{vel}->[1]];
	}
	
}

sub hasMoved{  
	my($self)=@_;
	return (($self->{pos}->[0] != $self->{prevPos}->[0] ) || ($self->{pos}->[1] != $self->{prevPos}->[1] ))
}

=head3 C<$sprite-E<gt>collide($spr)>
  detect whether sprite collides with another;
=cut

sub collide{
	my ($self,$sprB) =@_;
	#my ($blkA,$blkB)=($self->{data},$sprB->{data});
	my ($ax1,$ay1,$ax2,$ay2)=@{$self->rectangle()};
	my ($bx1,$by1,$bx2,$by2)=@{$sprB->rectangle()};
	#my ($ax1,$ay1,$bx1,$by1)=(@{$self->{pos}},@{$sprB->{pos}});
	#my ($ax2,$ay2,$bx2,$by2)=($ax1+@{$blkA->[0]},$ay1-@$blkA,$bx1+@{$blkB->[0]},$by1-@$blkB);
	return (($ax1 <= $bx2) && ($ax2 >= $bx1) && ($ay1 >= $by2) && ($ay2 <= $by1) ) ;
}

=head3 C<$sprite-E<gt>edge([$leftX,$topY,$rightX,$bottomY])>
  detect whether sprite is one edge of not; return which edge it is at
=cut

sub edge{
	my ($self,$bounds)=@_;
	$bounds//=$self->{bounds};
	my ($eLeft,$eTop,$eRight,$eBot)=@$bounds;
	my ($sLeft,$sTop,$sRight,$sBot)=@{$self->rectangle()};
	my $edge="";my $bounce=[0,0];
	if ($sTop>=$eTop){
		$edge.= "Top";
		$bounce->[1]=-1;
	}
	elsif ($sBot<=$eBot){
		$edge.= "Bot";
		$bounce->[1]=1;
	}
	if ($sRight>=$eRight){
		$edge.= "Right" ;
		$bounce->[0]=-1;
	}
	elsif ($sLeft<=$eLeft){;	
	    $edge.= "Left"  ;
		$bounce->[0]=1;
	}
	return $edge,$bounce;
}


=head3 C<$sprite-E<gt>rect()>
  return coordinates of sprites bounding rectangle as an arrayref containing
  $leftX,$topY,$rightX,$bottomY
=cut

sub rectangle{
	my ($self)=@_; 
	return [@{$self->{pos}},$self->{pos}->[0]+$self->{geometry}->[0],$self->{pos}->[1]-$self->{geometry}->[1]];
}

sub blit{
	my ($self,$canvas)=@_;
	return unless $self->{data};
	$canvas->blockBlit($self->{data},@{$self->{pos}});
}

sub blank{
	my ($self,$canvas)=@_;
	my $blank=[([(" ") x $self->{geometry}->[0]]) x $self->{geometry}->[1]];
	$canvas->blockBlit($blank,@{$self->{pos}});
}

sub blankPrev{
	my ($self,$canvas)=@_;
	my $blank=[([(" ") x $self->{geometry}->[0]]) x $self->{geometry}->[1]];
	$canvas->blockBlit($blank,@{$self->{prevPos}});
}

package Term::Graille::SpriteBank;

use strict;use warnings;
use lib "../../../lib";

our $VERSION=0.11;

sub new{
    my ($class,$groups) = @_; 
    my $self={};
    bless $self,$class;
	foreach my $group (@$groups){
		$self->{groups}->{$group}=[];
	}
	$self->{buffer}={};
	return $self;
}

=head3 C<$spriteBank-E<gt>addGroup($groupName)>
  adds group of sprites to spritebank
=cut

sub addGroup{
	my ($self,@groupNames)=@_;
	$self->{groups}->{$_}=[] foreach (@groupNames);
}

=head3 C<$spriteBank-E<gt>addSprite()>
  adds sprite to a group
=cut

sub addSprite{
	my ($self,$groupName,$sprite)=@_;
	unless (ref $sprite->{data}){   # for when sprite data is stored in the bank
		my $data=$self->{buffer}->{$sprite->{data}};
		$sprite->{geometry}=[scalar @{$data->[0]},scalar @$data];
	};
	push @{$self->{groups}->{$groupName}},$sprite;
}

=head3 C<$spriteBank-E<gt>addShape()>
  adds shape to storte of sprites to a group
=cut

sub addShape{
	my ($self,$name,$shape)=@_;
	$self->{buffer}->{$name}=$shape;
}

=head3 C<$spriteBank-E<gt>loadShape()>
  Loads a shape from a file
=cut

sub loadShape{
	my ($self,$fileName,$name)=@_;
	return undef unless (-e $fileName);
	if (!$name && $fileName=~/^[\\\/]?(.+[\\\/])?([a-z\s]+)(\.(.+))?$/i){
		$name=$2
	};
	open my $grf,"<:utf8",$fileName or return undef;
	my $data="";
	$data.=$_ while(<$grf>);
	close $grf;
	$self->{buffer}->{name}=eval($data);
}


=head3 C<$spriteBank-E<gt>drawAll()>
   draw all groups of sprites.  no need to remove or move sprites for first
   drawing of sprites; 
=cut

sub drawAll{
	my ($self,$canvas)=@_;
	foreach  my $groupName(keys %{$self->{groups}}){
		foreach my $spr (@{$self->{groups}->{$groupName}}){
			next unless $spr->{data};
			if (ref $spr->{data}){$spr->blit($canvas)}
			else {$canvas->blockBlit($self->{buffer}->{$spr->{data}},@{$spr->{pos}}) };
		}
	}
}

=head3 C<$spriteBank-E<gt>update()>
   update all groups of sprites.  remove all dsprites that need to be deleted
   update positions, and detect collisions
=cut

sub update{
	my ($self,$canvas)=@_;
	foreach  my $groupName(keys %{$self->{groups}}){
		# remove destroyed sprites
		my @list=();
		foreach my $spr (@{$self->{groups}->{$groupName}}){
			if ($spr->{destroyed}){
				$spr->blank($canvas) 
			}
			else{
				push @list,$spr;
				if ($spr->{skipped}>1){
					$spr->{skipped}-- ;
					next;
				}
				else{
					$spr->{skipped}=$spr->{skip};
					$spr->move();
					if ($spr->hasMoved()){
						$spr->blankPrev($canvas);
						if (ref $spr->{data}){$spr->blit($canvas)}
						else {$canvas->blockBlit($self->{buffer}->{$spr->{data}},@{$spr->{pos}}) };
					}
				}
			}
		}
		$self->{groups}->{$groupName}=[@list];
	}
}

1;

