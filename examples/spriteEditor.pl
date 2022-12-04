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
my $currentSprite="";
my $sprite;
my $keyMode="editor";   # whether keys are using the editor or the chooser

my $spriteBankName="default";
my $spriteBank=loadSpriteBank($spriteBankName);
$spriteBank={NewSprite=>[map {[("⠀")x8]}(0..3)]} unless (keys %$spriteBank);
$currentSprite=(sort keys %$spriteBank)[0];
$sprite=$spriteBank->{$currentSprite};
makeCanvas();
my $chooser; # container for choosers
my $chooserAction="";
#bankChooser();
my $dialog;  # container for dialogs#
my $result;

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

my @colours=qw/red blue green yellow cyan magenta white/;
my $setPix=[['⡀','⠄','⠂','⠁'],['⢀','⠠','⠐','⠈']];
my $unsetPix=[['⢿','⣻','⣽','⣾'],['⡿','⣟','⣯','⣷']];

my $cursor=[5,5];

refreshScreen();

my $io=Term::Graille::Interact->new();
# setup keyboard short cuts

$io->addAction(undef,"redraw",{note=>"RedrawScreen ",proc=>sub{
	   &main::refreshScreen();}}   );
$io->addAction(undef,"[A",{note=>"up arrow: cursor up ",proc=>sub{
	   $cursor->[1]++ unless $cursor->[1]>=4*@{$sprite}-1;
	   &main::refreshScreen(1);}}  );
$io->addAction(undef,"[B",{note=>"down arrow: cursor down ",proc=>sub{
	   $cursor->[1]-- unless $cursor->[1]<=0;
	   &main::refreshScreen(1);}}  );
$io->addAction(undef,"[C",{note=>"right arrow: cursor right ",proc=>sub{
	   $cursor->[0]++ unless $cursor->[0]>=2*@{$sprite->[0]}-1;
	   &main::refreshScreen(1);}}  );
$io->addAction(undef,"[D",{note=>"left arrow: cursor left ",proc=>sub{
	   $cursor->[0]-- unless $cursor->[0]<=0;
	   &main::refreshScreen(1);}}  );
$io->addAction(undef,"#",{note=>"# key",proc=>sub{
	   &main::set($sprite,$cursor->[0],$cursor->[1],1);
	   &main::refreshScreen(1);}}  );
$io->addAction(undef," ",{note=>"space key",proc=>sub{
	   &main::set($sprite,$cursor->[0],$cursor->[1],0);
	   &main::refreshScreen(1);}}  );
$io->addAction(undef,"s",{note=>"s key",proc=>sub{
	   &main::saveSprite($sprite);
	   &main::refreshScreen();
	   &main::restoreIO();},}  );		
$io->addAction(undef,"l",{note=>"l key",proc=>sub{
	   &main::loadSprite(); },}  );	
$io->addAction(undef,"shifttab",{note=>"Shift Tab key",proc=>sub{
	   &main::prev();
	   &main::restoreIO(); },}  );
$io->addAction(undef,"tab",{note=>"Tab key",proc=>sub{
	   &main::next();
	   &main::restoreIO(); },}  );
$io->addAction(undef,"enter",{note=>"Enter key",proc=>sub{
	   &main::select();
	   &main::restoreIO(); },}  );
$io->addAction(undef,"c",{note=>"c key",proc=>sub{
	   &main::cancel();
	   &main::restoreIO(); },}  );	  


my $menu=new Term::Graille::Menu(
          menu=>[["File","New Sprite Bank","Save Sprite Bank","Save Bank As","Load Sprite Bank","Delete Sprite","Import Sprite","Export Sprite","Quit"],
                 ["Sprites",["New Sprite","From Current","From Empty"],"Rename Sprite","Remove Sprite","Copy Sprite","Animate"],
                 ["Edit","Clear",["Mirror","X","Y"],["Rotate","CW","CCW"]
                 ,["Reformat","2x4","4x4"],["Scroll","Left","Right","Up","Down"]],
                 ["test","Death","Message","Input","Selector"],
                 "About"],
          redraw=>\&main::refreshScreen,
          callback=>\&main::menuActions,
          );
          
$io->addObject(object => $menu,trigger=>"m");

restoreIO();	 
$io->run();

sub menuActions{
	my $action=shift;
	if ($action){
		# just report menu item selected for debugging;	
		
		$io->close();
		for($action){
			/Import Sprite/ && do{
				my $tmp=loadSprite();
				last;
			};
			/Export Sprite/ && do{
				saveSprite();
				last;
			};	
			/Delete Sprite/ && do{
				deleteSprite();
				last;
			};	
			/Remove Sprite/ && do{
				delete $spriteBank->{$currentSprite};
				unless(keys %$spriteBank){$spriteBank={NewSprite=>[map {[("⠀")x8]}(0..3)]}};
				bankChooser();
				last;
			};	
			/Load Sprite Bank/ && do{
				loadSpriteBank();
				last;
			};
			/Save Sprite Bank/ && do{
				saveSpriteBank();
				last;
			};		
			/Save Bank As/ && do{
				saveSpriteBankAs();
				last;
			};			
			/From Current/ && do{
				newFromCurrent();
				last;
			};			
			/Death/ && do{
				open (my $fh,"<","non/existant/file") or deathSentence($!);
				last;
			};				
			/Message/ && do{
				message("error","test error message",[qw/ok cancel/]);
				last;
			};			
			/Right|Left|Up|Down/ && do{
				scroll($_);
				last;
			};					
			/Animate/ && do{
				my @animation=sort keys %$spriteBank;
				foreach (0..20){
					foreach(@animation){
						makeCurrent($_);
						sleep .05	;
					}			
				}
				last;
			};
			
		# menu actions not captured are reported transiently on the screen
		printAt(2,52,"Menu returns $action"); 
		sleep 1;
		}
		refreshScreen() if ($io->{mode} eq "main");
	}
	
	restoreIO();  # once menu has done its bit, control goes back to main application
}

sub refreshScreen{
	# generally refreshes the whole screen, but if a true value is passed
	# clearScreen is not executed to prevent flicker.
    clearScreen() unless shift;  
    return unless $canvas;
    $canvas->clear();
    drawBigSprite($sprite);
    $canvas->blockBlit($sprite, 6,4);
    $canvas->draw();
    flashCursor($sprite,$cursor);  # draw the cursor;
  #  $chooser->draw();
  #  printSelectList($spriteBankName,$currentSprite,0,[sort keys %$spriteBank]);
}

sub flashCursor{ 
	# puts the cursor at the desired location on the "BigSprite"
	my ($chX,$chY,$r,$c)=locate(@$cursor);
	printAt (5+4*$#{$sprite}-$cursor->[1],35+$cursor->[0], # overwrite the block
	        paint("*",getValue($sprite,@$cursor)?          # at cursor position
	        "black on_white":"white on_black"));           # with a "*", retaining 
}

sub newFromCurrent{
	my $index=1;
	my $newSpriteName=$currentSprite;
	$newSpriteName=~s/\d+$//g;
	$index++ while ($  spriteBank->{$newSpriteName.$index});
	$spriteBank->{$newSpriteName.$index}=$spriteBank->{$currentSprite};
	makeCurrent($newSpriteName.$index);
	bankChooser();
}

# after interrupting IO capture restore key actions back to main applications;
sub restoreIO{
	$io->close();
	#$io->run($io,$canvas,$sprite,$cursor);
};
	
sub input{	
	my ($prompt,$width)=@_;
	$width//=40;
	$io->stop();   # stop IO capture of key strokes;
    border(18,4,19,4+$width,"thick","blue",$prompt,"yellow");
	print cursorAt(19,7);
	my $inp=<STDIN>;
	chomp $inp;
	return $inp;
}

sub message{
	my ($icon,$text,$options)=@_;
	$width//=40;
	$dialog=Term::Graille::Dialog->new(message=>$text,callback=>\&dialogCallback,buttons=>$options,icon=>$icon);
	$io->start($dialog);
}

sub dialogCallback{
	$result=shift;
	my @stuff=@_;
}


sub listFiles{
	my $ext=shift;
	opendir(my $DIR, $dir) || die "Can't open directory $dir: $!";
	my @files = sort(grep {(/\.$ext$/) && -f "$dir/$_" } readdir($DIR));
	closedir $DIR;
	return \@files;
}

sub bankChooser{
	my $selected=shift;
	$chooser=Term::Graille::Selector->new(
	   options=>[sort keys %$spriteBank],
	   selected=>[0],
	   title =>$spriteBankName,
	   pos   =>[3,54],
	);	
	if ($selected){
		$chooser->setSelected($selected);
	}
}

sub saveSprite{
	my $fname=shift // input("Enter Sprite Name to save");
	if (!$fname){
		printSelectList("files",$currentSprite.".spr",0,listFiles("spr"));
		return;
	}	
	$fname=~s/.spr$//i;
	if (-e $dir.$fname.".spr") {
		message("warn","you are about to over-write a file",["Ok","Cancel"]);
	}
	message("error","Sprite name not valid")  unless validSpriteName($fname);
	$spriteBank->{$fname}=$sprite;
	clearScreen();
	bankChooser();
   my $output=spriteDump($sprite);
   
   open my $dat,">:utf8",$dir.$fname.".spr" or return errorMessage( "Unable to save spritefile $fname.spr") ;  
   print $dat $output;
   close $dat;
	bankChooser($fname);
	refreshScreen();
}

sub loadSprite{
	my $fname=shift ;
	if (!$fname){
		printSelectList("files",$currentSprite.".spr","loadSprite",listFiles("spr"));
		return;
	}
	else{
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
	}
	bankChooser($fname);
	refreshScreen();
}


# these are the functions related to the chooser
#that allow chooser widget in mainwindow
sub next{	
	my $sp=$chooser->nextItem();
	$chooser->draw();
}

sub prev{	
	my $sp=$chooser->prevItem();
	$chooser->draw();
}

sub select{
	makeCurrent($chooser->selectItem());
}

sub makeCurrent{
	my $sp=shift;
	if ($spriteBank->{$sp}){
		$sprite=$spriteBank->{$sp};	
	    $currentSprite=$sp;	
	}
	refreshScreen(1);
}

sub deleteSprite{
	my $fname=shift;
	if (!$fname){
		printSelectList("files",$currentSprite.".spr",0,listFiles("spr"));
		return;
	}
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


sub validSpriteName{
	return $_[0]=~/^[a-zA-Z0-9]+$/
}

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


sub spriteBankDump{
	my $bOut="{\n";
	for my $s (keys %$spriteBank){
		$bOut.="$s=>".spriteDump($spriteBank->{$s});
		$bOut=~s/\n$/,\n/;
	}
	$bOut.="}\n";
	return $bOut;
}

sub loadSpriteBank{
	my $fname=shift ;
	if (!$fname){
		printSelectList("files",$spriteBankName.".spb",0,listFiles("spb"));
		bankChooser();
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
	bankChooser();
	makeCurrent((sort keys %$g)[0]);
	return $g;
};

sub saveSpriteBank{
	my $fname=$spriteBankName;
	clearScreen();
	$fname=~s/.spb$//i;
	return errorMessage("Sprite bank name not valid")  unless validSpriteName($fname);
	
	my $output=spriteBankDump();

   open my $dat,">:utf8",$dir.$fname.".spb" or return errorMessage( "Unable to save sprite bank $fname.spb") ;  
   print $dat $output;	
   close $dat;
}

sub saveSpriteBankAs{
	my $fname=shift // input("Enter sprite Bank Name to save");
	if (!$fname){
		printSelectList("files",$currentSprite.".spb",0,listFiles("spb"));
	}
	$fname=~s/.spb$//i;
	if (-e $dir.$fname.".spb"){
		message("error","file with same name exists; are you sure you want to overwrite this files",[qw/Over-write Cancel/]);
	}
	saveSpriteBank($fname);
}

sub printSelectList{
	my ($listName,$selected,$action,$list)=@_;
	$chooser=Term::Graille::Selector->new(
	   options=>$list,
	   selected=>$selected,
	   redraw=>\&refreshScreen,
	   title =>$listName,
	   param=>{action=>$action},
	   pos   =>[3,54],
	   callback =>\&main::chooserCallback,
	);
	my $ch=$io->addObject(object=>$chooser);
	$io->start($ch);
}

# choosers may called in many contexts
sub chooserCallback{ 
	my ($param)=@_;
	$param//="no params";
	if (ref $param && $param->{action}){
		for ($param->{action}){
			/saveSpriteBankAs/ && do {saveSpriteBankAs ($param->{selected});    last;};
			/saveSprite/ && do {saveSprite ($param->{selected});    last;};
			/loadSpriteBank/  && do {loadSpriteBank($param->{selected}); last;};
			/loadSprite/     && do {loadSprite ($param->{selected});    last;};
			/deleteSprite/     && do {deleteSprite ($param->{selected});    last;};
		}
	}
	restoreIO();
	return $param->{selected};
}

sub errorMessage{
	my $msg=shift;
	die $msg;
	printAt(1,60,$msg);
}
