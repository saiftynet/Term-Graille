#! /usr/bin/env perl
package Term::Graille::SpriteBank;

use strict; use warnings;
use utf8;
use lib "../../../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::IO;
use Time::HiRes qw/sleep/;
use Data::Dumper;

sub new{
    my ($class,%params) = @_;     # 
    my $self={};
    $self->spriteBank={};
    bless $self,$class;
    loadFile($params{file}) if (exists $params{file});
    return $self;
}

sub spriteExists{
	my ($self,$spriteId)=@_;
	return exists $self->{spriteBank}{spriteId};
}

my $width=40;
my $height=40;

my $canvas = Term::Graille->new(
    width  => $width,
    height => $height,
    top=>4,
    left=>10,
    borderStyle => "double",
    title=>"Sprite",
  );
my @colours=qw/red blue green yellow cyan magenta white/;
clearScreen();  
$canvas->clear();


my $setPix=[['⡀','⠄','⠂','⠁'],['⢀','⠠','⠐','⠈']];
my $unsetPix=[['⢿','⣻','⣽','⣾'],['⡿','⣟','⣯','⣷']];

my $sprite=[["⠡","⠢","⠣","⠤","⠥","⠦","⠧","⠨"],
            ["⠩","⠪","⠫","⠬","⠭","⠮","⠯","⠠"],
            ["⡰","⡱","⡲","⡳","⡴","⡵","⡶","⡷"],
            ["⡸","⡹","⡺","⡻","⡼","⡽","⡾","⡿"]];

$canvas->blockBlit($sprite, 6,4);
$canvas->draw();
my $cursor=[5,5];



flashCursor($sprite,$cursor);


my $io=Term::Graille::IO->new();
$io->addAction(65,{note=>"up arrow",proc=>sub{
	   my ($canvas,$sprite,$cursor)=@_;
	   $cursor->[1]++ unless $cursor->[1]>=4*@{$sprite}-1;
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction(66,{note=>"down arrow",proc=>sub{
	   my ($canvas,$sprite,$cursor)=@_;
	   $cursor->[1]-- unless $cursor->[1]<=0;
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction(67,{note=>"right arrow",proc=>sub{
	   my ($canvas,$sprite,$cursor)=@_;
	   $cursor->[0]++ unless $cursor->[0]>=2*@{$sprite->[0]}-1;
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction(68,{note=>"left arrow",proc=>sub{
	   my ($canvas,$sprite,$cursor)=@_;
	   $cursor->[0]-- unless $cursor->[0]<=0;
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction(68,{note=>"left arrow",proc=>sub{
	   my ($canvas,$sprite,$cursor)=@_;
	   $cursor->[0]--;
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction(115,{note=>"s key",proc=>sub{
	   my ($canvas,$sprite,$cursor)=@_;
	   &main::set($sprite,$cursor->[0],$cursor->[1],1);
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction(117,{note=>"u key",proc=>sub{
	   my ($canvas,$sprite,$cursor)=@_;
	   &main::set($sprite,$cursor->[0],$cursor->[1],0);
	   &main::flashCursor($sprite,$cursor);}}   );	
$io->addAction(117,{note=>"f key",proc=>sub{
	   my ($canvas,$sprite,$cursor)=@_;
	   $io->stop();
	   &main::saveSprite($sprite);
	   &main::flashCursor($sprite,$cursor);}}   );		
	   	   	   	   	   
$io->run($canvas,$sprite,$cursor);

sub flashCursor{
	my $sprite=shift;
	my $cursor=shift;
	my ($chX,$chY,$r,$c)=locate(@$cursor);
#	printAt (21,20, "$sprite->[$#{$sprite}-$chY]->[$chX],$setPix->[$c]->[$r] ".
#	                "chX=$chX, chY=$chY, r=$r, c=$c, ".
#	                "x=$cursor->[0],y=$cursor->[1]= ".
#	                getValue($sprite,@$cursor)."   ");
	drawBigSprite($sprite);
	printAt(4+4*$#{$sprite}-$cursor->[1],35+$cursor->[0],"*");
	$canvas->blockBlit($sprite, 6,4);
	$canvas->draw();
}

sub saveSprite{
	my $sprite=shift;
	my $output=Dumper([$sprite]);
	printAt(5,21, "enter fileName\n");
	
	
	
}

sub drawBigSprite{
	my $sprite=shift;
	for my $c(0..$#{$sprite->[0]}){
	  for my $r (0..$#{$sprite}){
		drawCharBlock($c,$r,$sprite->[$r]->[$c]);
	  }
    }
}
 
sub getValue{
	my ($sprite,$x,$y)=@_;
	printAt(22,20,"$x,$y");
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $orOp=(ord($unsetPix->[$c]->[$r]) | ord($sprite->[$#{$sprite}-$chY]->[$chX]));
	#printAt(22,20,"$x,$y ".$unsetPix->[$c]->[$r]." ".$sprite->[$#{$sprite}-$chY]->[$chX]);
	return chr($orOp) eq '⣿'?1:0;
}

 
sub set{
	my ($sprite,$x,$y,$value)=@_;
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $chHeight=scalar @{$sprite};
	
	my $bChr=chop($sprite->[$#{$sprite}-$chY]->[$chX]);
	if ($value=~/^[a-z]/){$sprite->[$#{$sprite}-$chY]->[$chX]=colour($value);}
	elsif ($value=~/^\033\[/){$sprite->[$#{$sprite}-$chY]->[$chX]=$value;}
	# ensure character is a braille character to start with
	$bChr='⠀' if (ord($bChr)&0x2800 !=0x2800); 
	
	$sprite->[$#{$sprite}-$chY]->[$chX].=$value?         # if $value is false, unset, or else set pixel
	   (chr( ord($setPix-> [$c]->[$r]) | ord($bChr) ) ):
	   (chr( ord($unsetPix-> [$c]->[$r]) & ord($bChr)));
}

sub locate{
	my ($x,$y)=@_;
	my $chX=int($x/2);my $c=$x-2*$chX;
	my $chY=int($y/4);my $r=$y-4*$chY;
	return ($chX,$chY,$r,$c);
}
 
sub chr2blk{
	my ($chr,$bg,$fg)=@_;
	my $b=colour($bg)."▮".colour("reset");
	my $f=colour($fg)."▮".colour("reset");
	return [((chr(ord($chr)|ord('⠁'))eq$chr)?$f:$b).((chr(ord($chr)|ord('⠈'))eq$chr)?$f:$b),
	        ((chr(ord($chr)|ord('⠂'))eq$chr)?$f:$b).((chr(ord($chr)|ord('⠐'))eq$chr)?$f:$b),
            ((chr(ord($chr)|ord('⠄'))eq$chr)?$f:$b).((chr(ord($chr)|ord('⠠'))eq$chr)?$f:$b),
            ((chr(ord($chr)|ord('⡀'))eq$chr)?$f:$b).((chr(ord($chr)|ord('⢀'))eq$chr)?$f:$b)];
}



sub drawCharBlock{
	my ($x,$y,$char)=@_;
	printAt (1+$y*4,35+$x*2,chr2blk($char,"black","white")	);
}

sub pixelToLocation{
	
	
}

sub braille2Block{
	
	
}
