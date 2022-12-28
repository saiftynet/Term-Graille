#! /usr/bin/env perl

use strict; use warnings;
use utf8;
use lib "../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact ;
use Term::Graille::Menu;
use Term::Graille::Textarea;
use Term::Graille::Selector;
use Term::Graille::Dialog ;
use Time::HiRes qw/sleep/;
use Data::Dumper;

my $canvas;
my $width=45;
my $height=40;
my $dir="./sprites/";
my $currentFile="";
my $currentSprite="";
my $sprite;
my $keyMode="editor";   # whether keys are using the editor or the chooser

my $spriteBankName="default";
my $spriteBank=loadSpriteBank($spriteBankName);
$spriteBank={NewSprite=>[map {[("⠀")x8]}(0..3)]} unless (keys %$spriteBank);
$currentSprite=(sort keys %$spriteBank)[0];
$sprite=$spriteBank->{$currentSprite};
makeCanvas();
#bankChooser();
my $dialog;  # container for dialogs#


my $io=Term::Graille::Interact->new();
$io->{debugCursor}=[22,45];


# setup keyboard short cuts

my $menu=new Term::Graille::Menu(  # no object offered so id will be o0 
          menu=>[["File","New","Load","Save","Save As","Delete","Remove","Quit"],
                 ["Edit","Clear",["Scroll","Left","Right","Up","Down"],["Rotate","CW (90)","(180)","CCW (270)"],["Flip","RL Diagonal","LR Diagonal","Vertical","Horizontal"],],
                 ["Sprites",sort keys %$spriteBank],
                 "About"],
          redraw=>\&refreshScreen,
          dispatcher=>\&menuActions,
          );

# in this case the dispatcher directs to subroutines based on name of  
my %actions = ( New  => sub{new()},
                Load => sub{ load($dir)},
                Save => sub{ save($dir) },
              );
              
sub menuActions{ # dispatcher for menu
	my ($action,$bCrumbs)=@_;
	if ($bCrumbs->[0] ==2){
		makeCurrent($action);
		printAt(2,60,"SPRITE $action")
	}
	elsif ($action=~/^Left|Right|Up|Down$/){
	     scroll($action);
	}
	elsif ($action=~/(90|180|270|RL Diag|LR Diag|Horiz|Vert)/){
	     rotate($sprite, $1);
	}
	elsif (exists $actions{$action}){
		$actions{$action}->()
	}
	else{
		printAt(2,60,$action)
	}
};

my $chooser=new Term::Graille::Selector(
          redraw=>\&refreshScreen,
          options=>[qw/ apples bananas oranges pears/],
          transient=>1,
          title=>"not defined",
          );
my @colours=qw/red blue green yellow cyan magenta white/;
my $setPix=[['⡀','⠄','⠂','⠁'],['⢀','⠠','⠐','⠈']];
my $unsetPix=[['⢿','⣻','⣽','⣾'],['⡿','⣟','⣯','⣷']];

my $cursor=[5,5];
          
          
sub makeCanvas{
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

 
$io->addAction(undef,"redraw",{note=>"RedrawScreen ",proc=>sub{
	   &main::refreshScreen();}}   );
$io->addAction(undef,"[A",{note=>"up arrow: cursor up ",proc=>sub{
	   $cursor->[1]++ unless $cursor->[1]>=4*@{$sprite}-1;
	   refreshScreen(1);}}  );
$io->addAction(undef,"[B",{note=>"down arrow: cursor down ",proc=>sub{
	   $cursor->[1]-- unless $cursor->[1]<=0;
	   refreshScreen(1);}}  );
$io->addAction(undef,"[C",{note=>"right arrow: cursor right ",proc=>sub{
	   $cursor->[0]++ unless $cursor->[0]>=2*@{$sprite->[0]}-1;
	   refreshScreen(1);}}  );
$io->addAction(undef,"[D",{note=>"left arrow: cursor left ",proc=>sub{
	   $cursor->[0]-- unless $cursor->[0]<=0;
	   refreshScreen(1);}}  );
$io->addAction(undef,"#",{note=>"# key sets pixel  ",proc=>sub{
	   set($sprite,$cursor->[0],$cursor->[1],1);
	   refreshScreen(1);}}  );
$io->addAction(undef," ",{note=>"space key blanks pixel  ",proc=>sub{
	   set($sprite,$cursor->[0],$cursor->[1],0);
	   refreshScreen(1);}}  );
$io->addAction(undef,"s",{note=>"s key",proc=>sub{
	   saveSprite($sprite);
	   refreshScreen();
	   restoreIO();},}  );		
$io->addAction(undef,"l",{note=>"l key",proc=>sub{
	   load($dir); },}  );	
$io->addAction(undef,"shifttab",{note=>"Shift Tab key",proc=>sub{
	   prev();
	   restoreIO(); },}  );
$io->addAction(undef,"tab",{note=>"Tab key",proc=>sub{
	   nxt();
	   restoreIO(); },}  );
$io->addAction(undef,"c",{note=>"c key",proc=>sub{
	  cancel();
	  restoreIO(); },}  );	  
 
refreshScreen();
$io->addObject(object => $menu,trigger=>"m");
$io->run();

sub refreshScreen{
	clearScreen() unless (shift);
    $canvas->blockBlit($sprite, 8,7);
	$canvas->draw();
	drawBigSprite($sprite);
}

sub load{
	my ($dir,$filters)=@_;
	$dir//=".";
	$filters//="\.spr|\.spb\$";
	opendir(my $DIR, $dir) || die "Can't open directory $dir: $!";
	my @files = sort(grep {(/$filters/i) && -f "$dir/$_" } readdir($DIR));
	closedir $DIR;
	my $selector=new Term::Graille::Selector(
          redraw=>\&refreshScreen,
          callback=>\&confirmLoad,
          options=>[@files],
          transient=>1,
          title=>"Load File",
          );
    $io->addObject(object => $selector, objectId=>"selector");
    $io->start("selector");
}		

sub confirmLoad{  # if about to overwrite warn
	my ($param)=@_;
	my $file=$param->{selected};
	my $dialog=new Term::Graille::Dialog(
          redraw=>\&refreshScreen,
          callback=>\&loadFile,
          message=>"Are you sure you want to load this file? You will lose current work",
          param=>{file=>$file,action=>"load"},
          icon=>"info",
          title=>"Confirm Load",
          buttons=>[qw/Load Cancel/],
   );
    $io->addObject(object => $dialog, objectId=>"dialog");
    $io->start("dialog");
}

sub loadFile{
	my $param=shift;
	$io->close();
	if ($param->{button} && $param->{button} eq "Cancel"){
		return;
		};
	my $fname=$param->{file};
	clearScreen();
	$fname=~s/.spr$//i;	
	return errorMessage("Sprite $dir/$fname.spr not found")  unless (-e $dir.$fname.".spr");
	open my $grf,"<:utf8",$dir.$fname.".spr"  or do {
		errorMessage( "Unable to load spritefile $fname.spr");
		return;
		};
	my $data="";
	$data.=$_ while(<$grf>);
	close $grf;
	my $g=eval($data) or return errorMessage("unable to load sprite $fname.spr\n $!");
	$spriteBank->{$fname}=$g;
	makeCurrent($fname);
	$menu->{menu}->[2]=["Sprites",sort keys %$spriteBank];
}

sub save{
	my ($dir,$filters)=@_;
	$dir//=".";
	$filters//="\.spr|\.spb\$";
	opendir(my $DIR, $dir) || die "Can't open directory $dir: $!";
	my @files = sort(grep {(/$filters/i) && -f "$dir/$_" } readdir($DIR));
	closedir $DIR;
	my $selector=new Term::Graille::Selector(
          redraw=>\&refreshScreen,
          callback=>\&confirmSave,
          options=>[@files],
          transient=>1,
          selected =>$currentFile,
          title=>"Save File",
          );
    $io->addObject(object => $selector, objectId=>"selector");
    $io->start("selector");
}		

sub confirmSave{  # if about to overwrite warn
	my ($param)=@_;
	my $file=$param->{selected};
	if (-e $file){
		my $dialog=new Term::Graille::Dialog(
			  redraw=>\&refreshScreen,
			  callback=>\&saveFile,
			  message=>"Are you sure you want to save this file? it will overwrite $file",
			  param=>{file=>$file,action=>"save"},
			  icon=>"warn",
			  title=>"Confirm Save",
			  buttons=>[qw/Overwrite Cancel/]
	   );
	   $io->addObject(object => $dialog, objectId=>"dialog");
	   $io->start("dialog");
	}
	else{
		saveFile({file=>$file});
	}
}

sub saveFile{
	my ($param)=@_;
	$io->close();   
	if ($param->{button} && $param->{button} eq "Cancel"){
		return;
	};
	my $file=$param->{file};
    my $output=spriteDump($sprite);
	open(my $fh, ">", "$dir$file.spr") or die("Can't open file $file:$! ");
    print $fh $output;
	close($fh);
	$currentFile=$file;
}

sub drawBigSprite{
	my $sprite=shift;
	for my $c(0..$#{$sprite->[0]}){
	  for my $r (0..$#{$sprite}){
		printAt (2+$r*4,35+$c*2,chr2blk($sprite->[$r]->[$c],"black","white"));
	  }
    }
	# puts the cursor at the desired location on the "BigSprite"
	my ($chX,$chY,$r,$c)=locate(@$cursor);
	printAt (5+4*$#{$sprite}-$cursor->[1],35+$cursor->[0], # overwrite the block
	        paint("*",getValue($sprite,@$cursor)?          # at cursor position
	        "black on_white":"white on_black"));           # with a "*", retaining 
}
 
sub scroll{
	my $dir=shift;
	my @yList=my @xList=(0..15);
	my $dx=my $dy=0;
	if    ($dir=~/L/){	pop   @xList;	$dx=+1;	}
	elsif ($dir=~/R/){  shift @xList;	$dx=-1;	}
	elsif ($dir=~/D/){  pop   @yList;	$dy=+1;	}
	elsif ($dir=~/U/){  shift @yList;	$dy=-1;	}
	
	my $newSp=[map {[("⠀")x@{$sprite->[0]}]}(0..$#{$sprite})];
	
	foreach my $y1(@yList){
		foreach my $x1(@xList){
			set($newSp,$x1,$y1, getValue($sprite,$x1+$dx,$y1+$dy));
		}
	}
	$sprite=$newSp;
	$spriteBank->{$currentSprite}=$newSp;
	refreshScreen();
}

sub rotate{
	my ($spr,$rot)=@_;
	my $newSprite=[map {[("⠀")x8]}(0..3)];
	if ($rot eq "RL Diag"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,15-$d,15-$c))
			}
		}
	}
	elsif ($rot eq "LR Diag"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,$d,$c))
			}
		}
	}
	elsif ($rot eq "Horiz"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,15-$c,$d))
			}
		}
	}
	elsif ($rot eq "Vert"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,$c,15-$d))
			}
		}
	}
	elsif ($rot eq "270"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,$d,15-$c))
			}
		}
	}
	elsif ($rot eq "90"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,15-$d,$c))
			}
		}
	}
	elsif ($rot eq "180"){
		for my $c (0..15){
			for my $d(0..15){
				set($newSprite,$c,$d,getValue($spr,15-$c,15-$d))
			}
		}
	}
	else{
		return
	}
	$sprite=$newSprite;
	$spriteBank->{$currentSprite}=$newSprite;
	refreshScreen();
}
 
sub getValue{
	my ($spr,$x,$y)=@_;
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $contents=$spr->[$#{$spr}-$chY]->[$chX];
	my $bChr=chop($contents);
	my $orOp=(ord($unsetPix->[$c]->[$r]) | ord($bChr));
	#printAt(22,20,"$x,$y ".$unsetPix->[$c]->[$r]." ".$sprite->[$#{$sprite}-$chY]->[$chX]);
	return chr($orOp) eq '⣿'?1:0;
}

sub set{
	my ($spr,$x,$y,$value)=@_;
	my ($chX,$chY,$r,$c)=locate($x,$y);
	my $chHeight=scalar @{$spr};
	my $contents=$spr->[$#{$spr}-$chY]->[$chX];	
	my $bChr=chop($contents);
	if ($value=~/^[a-z]/){$contents=colour($value);}
	elsif ($value=~/^\033\[/){$contents=$value;}
	else {$contents=""};
	# ensure character is a braille character to start with
	$bChr='⠀' if (ord($bChr)&0x2800 !=0x2800); 
	
	$spr->[$#{$spr}-$chY]->[$chX]=$contents.$value?         # if $value is false, unset, or else set pixel
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


# convert sprite to a loadable file;
sub spriteDump{
	my $spr=shift;
	my $output=Dumper([$spr]);	
   $output=~ s/\\x\{([0-9a-f]{2,})\}/chr hex $1/ge;
   $output=~s/^\$VAR1 = \[\n\s+|        \];\n?$//g;
   $output=~s/\[\n\s+\[/\[\[/g;
   $output=~s/\n\s+([^\s])/$1/g;
   $output=~s/\]\],/\]\],\n/g;
   return $output;
}

sub loadSpriteBank{
	my $fname=shift ;
	if (!$fname){
		printSelectList("files",$spriteBankName.".spb",0,listFiles("spb"));
		return;
	}
	$fname=~s/.spb$//i;	
	return errorMessage("Sprite Bank not found")  unless (-e $dir.$fname.".spb");
	open my $grf,"<:utf8",$dir.$fname.".spb"  or do {
		errorMessage( "Unable to load spritebank $fname.spb");
		return;
	};
	my $data="";
	$data.=$_ while(<$grf>);
	close $grf;
	my $g=eval($data) or return errorMessage("unable to load sprite bank $fname.spb\n $!");
	$spriteBank=$g;
	$spriteBankName=$fname;
	return $g;
};

sub makeCurrent{
	my $sp=shift;
	if ($spriteBank->{$sp}){
		$sprite=$spriteBank->{$sp};	
	    $currentSprite=$sp;	
	}
	refreshScreen(1);
}

