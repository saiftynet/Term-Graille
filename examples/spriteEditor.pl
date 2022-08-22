#! /usr/bin/env perl

use strict; use warnings;
use utf8;
use lib "../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::IO;
use Term::Graille::Menu;
use Time::HiRes qw/sleep/;
use Data::Dumper;

my $canvas;
my $width=45;
my $height=40;
my $spriteBank={};
my $dir=".";
$spriteBank->{empty}=loadSprite("empty");
my $sprite=$spriteBank->{empty};

drawEditor();

sub drawEditor{
	my ($SpWidth,$SpHeight)=(2*scalar @{$sprite->[0]},4*scalar @{$sprite});
	$canvas = Term::Graille->new(
		width  => $width,
		height => $height,
		top=>4,
		left=>8,
		borderStyle => "double",
		title=>"$SpWidth x $SpHeight",
	  );
}

my @colours=qw/red blue green yellow cyan magenta white/;
my $setPix=[['⡀','⠄','⠂','⠁'],['⢀','⠠','⠐','⠈']];
my $unsetPix=[['⢿','⣻','⣽','⣾'],['⡿','⣟','⣯','⣷']];

my $cursor=[5,5];

flashCursor($sprite,$cursor);
my $menu=new Term::Graille::Menu(
          menu=>[["File","New Sprite Bank","Save Sprite Bank","Load Sprite Bank","Quit"],
                 ["Sprites","New Sprite","Edit Sprite","Copy Sprite","Delete Sprite","Import Sprite","Export Sprite"],
                 ["Edit","Clear","MirrorX","MirrorY","Rotate+","Rotate-",["Reformat","2x4","4x4"],["Scroll","left","right","up","down"]],
                 "About"],
          redraw=>\&main::refreshScreen,
          callback=>\&main::menuActions,
          );


my $io=Term::Graille::IO->new();
$io->addMenu($menu);

$io->addAction("redraw",{note=>"RedrawScreen ",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   &main::refreshScreen();}}   );
$io->addAction("Am",{note=>"up arrow: cursor up ",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   $cursor->[1]++ unless $cursor->[1]>=4*@{$sprite}-1;
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction("Bm",{note=>"down arrow: cursor down ",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   $cursor->[1]-- unless $cursor->[1]<=0;
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction("Cm",{note=>"right arrow: cursor right ",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   $cursor->[0]++ unless $cursor->[0]>=2*@{$sprite->[0]}-1;
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction("Dm",{note=>"left arrow: cursor left ",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   $cursor->[0]-- unless $cursor->[0]<=0;
	   &main::flashCursor($sprite,$cursor);}}   );;
$io->addAction("#",{note=>"# key",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   &main::set($sprite,$cursor->[0],$cursor->[1],1);
	   &main::flashCursor($sprite,$cursor);}}   );
$io->addAction(" ",{note=>"space key",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   &main::set($sprite,$cursor->[0],$cursor->[1],0);
	   &main::flashCursor($sprite,$cursor);}}   );	
$io->addAction("s",{note=>"s key",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   &main::saveSprite($sprite);
	   &main::flashCursor($sprite,$cursor);
	   &main::restoreIO();},}  );		
$io->addAction("l",{note=>"l key",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_;
	   my $tmp=&main::loadSprite();
	   $sprite=[@$tmp] if ($tmp);
	   &main::flashCursor($sprite,$cursor);
	   &main::restoreIO(); },}  );
	   
restoreIO();

sub refreshScreen{
	clearScreen();  
    $canvas->clear();
    drawBigSprite($sprite);
    $canvas->blockBlit($sprite, 6,4);
    $canvas->draw();
    flashCursor($sprite,$cursor);
}

sub menuActions{
	my $action=shift;
	if ($action){
		printAt(2,52,"Menu returns $action");
		for($action){
			/Import Sprite/ && do{
				$menu->closeMenu(1);
				my $tmp=loadSprite();
				$sprite=[@$tmp] if ($tmp);
				flashCursor($sprite,$cursor);
				restoreIO();
				last;
			};
			/Export Sprite/ && do{
				$menu->closeMenu(1);
				saveSprite($sprite);
				restoreIO();
				last;
			};	
			/Delete Sprite/ && do{
				$menu->closeMenu(1);
				deleteSprite();
				refreshScreen();
				restoreIO();
				last;
			};			
			
			
		}
		
	}
	else{
		restoreIO();
	}
}

sub flashCursor{
	my $spr=shift;
	$sprite=$spr;
	my $cursor=shift;
	my ($chX,$chY,$r,$c)=locate(@$cursor);
	drawBigSprite($sprite);     # draw the sprite as blocks for editting
	printAt (5+4*$#{$sprite}-$cursor->[1],35+$cursor->[0], # overwrite the block
	        paint("*",getValue($sprite,@$cursor)?         # at cursor position
	        "black on_white":"white on_black"));          # with a "*", retaining 
	$canvas->blockBlit($sprite, 6,4);
	$canvas->draw();
}

sub restoreIO{
	$io->{mode}="free";
	$io->run($io,$canvas,$sprite,$cursor);
};
	
sub input{	
	my $prompt=shift;
	$io->stop();   # stop IO capture of key strokes;
    border(18,4,19,40,"thick","blue",$prompt,"yellow");
    printSelectList("files",0,0,listFiles());
	print cursorAt(19,7);
	my $inp=<STDIN>;
	chomp $inp;
	return $inp;
}

sub errorMessage{
	my ($err,$width)=shift;
	$width//=40;
	border(18,4,19,4+$width,"thick","blue","ERROR!","red");
	printAt(19,7,$err);
	
}

sub listFiles{
	opendir(my $DIR, $dir) || die "Can't open directory $dir: $!";
	my @files = grep {(/\.sp[rb]$/) && -f "$dir/$_" } readdir($DIR);
	closedir $DIR;
	return \@files;
}

sub printSelectList{
	my ($listName,$selected,$start,$list)=@_;
	border(5,54,19,75,"thick","blue",$listName,"yellow");
	foreach (0..14){
		printAt(7+$_,56,$list->[$_]) if ($_<@$list);
	}
}

sub saveSprite{
	my $sprite=shift;
	my $fname=shift // input("Enter sprite name to save");
	clearScreen();
	$fname=~s/.spr$//i;
	return unless validSpriteName($fname);

	my $output=Dumper([$sprite]);	
   $output=~ s/\\x\{([0-9a-f]{2,})\}/chr hex $1/ge;
   $output=~s/^\$VAR1 = \[\n\s+|        \];\n?$//g;
   $output=~s/\[\n\s+\[/\[\[/g;
   $output=~s/\n\s+([^\s])/$1/g;
   $output=~s/\]\],/\]\],\n/g;
   
   open my $dat,">:utf8","$fname.spr" or errorMessage( "Unable to save spritefile $fname.spr") && return;;  
   print $dat $output;
   close $dat;
}

sub loadSprite{
	my $fname=shift // input("Enter sprite name to load");
	clearScreen();
	$fname=~s/.spr$//i;	
	open my $grf,"<:utf8",$fname.".spr"  or do {
		errorMessage( "Unable to load spritefile $fname.spr");
		return;
	};
	my $data="";
	$data.=$_ while(<$grf>);
	close $grf;
	my $g=eval($data) or do {
		printAt(21,5, "unable to load external data from $fname.spr $!");
		return;
	} ;
	return  $g;	
}

sub deleteSprite{
	my $fname=shift // input("Enter sprite name to delete");
	clearScreen();
	$fname=~s/.spr$//i;	
	unlink $fname.".spr";
}

sub drawBigSprite{
	my $sprite=shift;
	for my $c(0..$#{$sprite->[0]}){
	  for my $r (0..$#{$sprite}){
		printAt (2+$r*4,35+$c*2,chr2blk($sprite->[$r]->[$c],"black","white"));
	  }
    }
}
 
sub getValue{
	my ($sprite,$x,$y)=@_;
	printAt(22,20,"$x,$y");
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $contents=$sprite->[$#{$sprite}-$chY]->[$chX];
	my $bChr=chop($contents);
	my $orOp=(ord($unsetPix->[$c]->[$r]) | ord($bChr));
	#printAt(22,20,"$x,$y ".$unsetPix->[$c]->[$r]." ".$sprite->[$#{$sprite}-$chY]->[$chX]);
	return chr($orOp) eq '⣿'?1:0;
}

sub set{
	my ($sprite,$x,$y,$value)=@_;
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $chHeight=scalar @{$sprite};
	my $contents=$sprite->[$#{$sprite}-$chY]->[$chX];	
	my $bChr=chop($contents);
	if ($value=~/^[a-z]/){$contents=colour($value);}
	elsif ($value=~/^\033\[/){$contents=$value;}
	else {$contents=""};
	# ensure character is a braille character to start with
	$bChr='⠀' if (ord($bChr)&0x2800 !=0x2800); 
	
	$sprite->[$#{$sprite}-$chY]->[$chX]=$contents.$value?         # if $value is false, unset, or else set pixel
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


sub validSpriteName{
	return $_[0]=~/^[a-zA-Z0-9]+$/
}



