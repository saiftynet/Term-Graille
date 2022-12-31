#! /usr/bin/env perl
use strict; use warnings;
use utf8;
use lib "../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact ;
use Term::Graille::Audio;
use Term::Graille::Font  qw/loadGrf fontWrite/;

my $beep=Term::Graille::Audio->new();    # TERM::Graille's Audio module
my $grf=loadGrf("./fonts/ZX Times.grf");

my $spriteBank={};
my $dir="./sprites/";
my $scroll="left";

loadSprites(qw/alien1 alien2 alien3 defender spaceship/);
$spriteBank->{patriot}=[[colour("blue")."↑".colour("reset")]];
$spriteBank->{bomb}=[[colour("red")."↧".colour("reset")]];
$spriteBank->{shield}=[[colour("yellow")."⢕".colour("reset")]];
my (@aliens,@missiles,@shields,@spaceships);
my $defender={sprite=>"defender",x=>40,y=>1,};
my ($maxAlienX,$minAlienX,$alienDx,$alienDy,$alienMoveSkipStart,
    $alienSkipAccelerate,$aliensLanded,$stopUpdates,$alienMoveSkip,
    $level, $score, $lives, $highscore);

my $canvas = Term::Graille->new(
		width  => 150,
		height => 60,
		top=>4,
		left=>4,
		borderStyle => "double",
		title=>"Space Invaders",
	  );

initialise();

my $io=Term::Graille::Interact->new();
$io->{debugCursor}=[22,45];

$io->addAction(undef,"[D",{note=>"Move Left ",proc=>sub{
	$defender->{x}=$defender->{x}>=1?$defender->{x}-1:1    }} );
$io->addAction(undef,"[C",{note=>"Move Right ",proc=>sub{
	$defender->{x}=$defender->{x}<=65?$defender->{x}+1:65  }} );
$io->addAction(undef,"[A",{note=>"Fire      ",     proc=>sub{
	push @missiles,{sprite=>"patriot",x=>$defender->{x}+4,y=>1,dy=>1};;
	$beep->playSound(undef,"A#1");}}    );
$io->addAction(undef,"p",{note=>"PaUSE ",     proc=>sub{
     $stopUpdates=$stopUpdates?0:1;}}    );
	
$io->updateAction(\&update);
$io->run();

sub update	{  
	victory() unless scalar @aliens;
	defeat("Aliens Landed") if $aliensLanded;
	return if $stopUpdates;
	updateScreen();
	updateSprites();
}

#draw all sprites and redraw screen
sub updateScreen{
	$canvas->clear();
	@aliens=grep($_->{sprite},@aliens);
	@missiles=grep($_->{sprite},@missiles);	
	@shields=grep($_->{sprite},@shields);	
	@spaceships=grep($_->{sprite},@spaceships);	
	foreach (@aliens,@missiles,$defender,@shields,@spaceships){
      next unless defined $_->{sprite};
      my ($spr,$x,$y)=@$_{qw/sprite x y/};
      $canvas->blockBlit($spriteBank->{$spr},$x,$y);
         if ($spr=~/^a/){ #collect data for aliens closest to edges
			 $maxAlienX=$x if $x>$maxAlienX;
			 $minAlienX=$x if $x<$minAlienX;
		 }
      }	  
      push @missiles,{sprite=>"bomb",x=>2+rand()*70,y=>16,dy=>-1} if rand()<0.01;
      push @spaceships,{sprite=>"spaceship",x=>3,y=>15,dx=>1} if rand()<0.005;
      $canvas->draw();
      printAt(3,40,"Score: $score Level: $level, Lives ".colour("red")."♥ "x$lives.colour("reset") );
      printAt(16,0," ");
}

sub updateSprites{
	$alienMoveSkip--;
	unless ($alienMoveSkip>=0){
		$alienDy=0;
		if ($maxAlienX>=67){$alienDx=-1;$alienDy=-1;$maxAlienX=0};
		if ($minAlienX<=1){$alienDx=1;$alienDy=-1;$minAlienX=1000};
		foreach (@aliens){
			$_->{x}+=$alienDx;
			$_->{y}+=$alienDy;
			$aliensLanded=1 if  $_->{y}<=2
		}
		$alienMoveSkipStart-=0.1;
		$alienMoveSkip=$alienMoveSkipStart;
	}
	foreach (@spaceships){
			$_->{x}+=$_->{dx};
			$_ ={} if  $_->{x} >=67;
			push @missiles,{sprite=>"bomb",x=>$_->{x}+2,y=>16,dy=>-1}  if ((rand()<0.5) and ($_->{x}==$defender->{x}));
			$_ ={} if  $_->{x} >=67;
	}
	foreach my $missile (@missiles){
		next unless $missile->{y};
		$missile->{y}+=$missile->{dy};
		if ($missile->{y}>=16|| $missile->{y}<=1){
			$missile={};
		};
		next unless defined $missile->{sprite};
		foreach my $alien (@aliens,@spaceships){
			if ($missile->{sprite}&& $missile->{sprite} eq "patriot"&&(collide($missile,$alien))){
				$score+=($alien->{sprite} eq "spaceship")?1000:10;
				$missile=$alien={};
				$beep->playSound(undef,"D#1");
			}
		}
		foreach my $shield (@shields){
			if ($missile->{sprite}&&(collide($missile,$shield))){
				$missile=$shield={};
				$beep->playSound(undef,"c#1");
			}
		}
		if ($missile->{sprite} && $missile->{sprite} eq "bomb"){
			defeat("Defender Died") if collide($missile,$defender)
		}
	}
}

sub loadSprites{
	my @sprites=@_;
	foreach my $spr (@sprites){
		open my $grf,"<:utf8",$dir.$spr.".spr"  or do {
			errorMessage( "Unable to load spritefile $spr.spr");
			next;
		};
		my $data="";
		$data.=$_ while(<$grf>);
		close $grf;
		$spriteBank->{$spr}=[@{eval($data)}[0..1]] or return errorMessage("unable to load sprite $spr.spr\n $!");
		$_->[0]=colour((qw/red yellow green magenta cyan white blue/)[rand()*7]).$_->[0] foreach (@{$spriteBank->{$spr}})
	}
}

sub collide{
	my ($sprA,$sprB) =@_;
	return unless $sprA->{sprite} && $sprB->{sprite};
	my ($blkA,$blkB)=($spriteBank->{$sprA->{sprite}},$spriteBank->{$sprB->{sprite}});
	my ($ax1,$ay1,$bx1,$by1)=($sprA->{x},$sprA->{y},$sprB->{x},$sprB->{y});
	my ($ax2,$ay2,$bx2,$by2)=($ax1+@{$blkA->[0]},$ay1+@$blkA-1,$bx1+@{$blkB->[0]},$by1+@$blkB-1);
	return (($ax1 <= $bx2) && ($ax2 >= $bx1) && ($ay1 <= $by2) && ($ay2 >= $by1) ) ;
}

sub errorMessage{die $_[0];}

sub setupAliens{
	# build aliens dataset
	@aliens=();
	$alienMoveSkip=$alienMoveSkipStart;
	$aliensLanded=0;
	my $row=15;                       # start at row 15
	for my $alien(keys %$spriteBank){
		next unless $alien=~/alien/;  # use alien sprites
		for (0..5){
			push @aliens, {sprite=>$alien,x=>10+10*$_,y=>$row}
		}
		$row-=2;                       #next row down
	}
}

sub buildShields{	
	@shields=();
	for my $y (2..3){
		for my $x (0..4){
			for my $z (0..6){
				push @shields, {sprite=>"shield",x=>4+15*$x+$z,y=>$y}
			}
		}
	}
}

sub initialise{
	clearScreen();
	($maxAlienX,$minAlienX,$alienDx,$alienDy,$alienMoveSkipStart,
	$alienSkipAccelerate,$aliensLanded,$level, $score, $lives, $highscore)=
	(0,200,1,0,8,0.01,0,1,0,3, 0);
	$stopUpdates=0;
	$alienMoveSkip=$alienMoveSkipStart;
	setupAliens();
	buildShields();
	splash();
	sleep 3;
}

sub splash{
	my $mainMessage=shift//"Space Invaders";
	my $message=shift//"A Game for The PerlayStation Games Console 1";
	my $format=shift//"blue";
	$canvas->clear();
	fontWrite($canvas,$grf,10,10,$mainMessage);
	$canvas->textAt(30,20,$message,$format);
	$canvas->textAt(40,12,"Left Right Arrow keys move defender","cyan bold");
	$canvas->textAt(40,8,"Up Arrow fires missile, 'p' pauses","cyan bold");
	$canvas->draw();
	
}

sub victory{
   $level++;$score+=500;
   splash("Level clear!!","Lives $lives Score: $score","green");
   sleep 3;
   setupAliens();
}
sub defeat{
   my $fail=shift;
   $lives--;
   splash($fail,"Lives $lives Score: $score","green");
   gameover() unless $lives;
   setupAliens();
   sleep 4;
}

sub gameover{
   $highscore=$score if $score>$highscore;
   splash("  Annihilated!","Score: $score High Score: $highscore ","green");
   sleep 4;
   initialise();
}


sub quit{
   splash("Good Bye!!","Score: $score High Score: $highscore ","green");
   sleep 4;
   exit;
}

