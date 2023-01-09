#! /usr/bin/env perl
use strict; use warnings;
use utf8;
use lib "../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact ;
use Term::Graille::Sprite;
use Term::Graille::Audio;
use Term::Graille::Font  qw/loadGrf fontWrite/;
use Time::HiRes qw/sleep/;

my $beep=Term::Graille::Audio->new();    # TERM::Graille's Audio module
my $grf=loadGrf("./fonts/ZX Times.grf");
my $stopUpdates=0;
my $canvas = Term::Graille->new(
		width  => 148,
		height => 60,
		top=>3,
		left=>4,
		borderStyle => "double",
		title=>"Breakout",
	  );
my $lives=3;
my $score=0;
my $level=1;
my $spriteBank=Term::Graille::SpriteBank->new();
my $dir="./sprites/";
foreach my $colour(qw/red yellow green magenta cyan white blue/){
	$spriteBank->addShape($colour."brick",[[colour($colour)."█","█","█","▌".colour("reset")]]);
}

my $bat=new Term::Graille::Sprite(data=>[[("█") x 6]],pos=>[20,0],bounds=>[1,14,60,0]);
my $ball=new Term::Graille::Sprite(pos=>[20,3],vel=>[1,1],bounds=>[1,14,70,-1],skip=>6);
$spriteBank->addSprite("player",$bat);
$spriteBank->addSprite("ball",$ball);

my $help={};

newWall();
$spriteBank->drawAll($canvas);
sleep 5;
my $io=Term::Graille::Interact->new();
$io->{debugCursor}=[22,45];

$io->addAction(undef,"[D",{note=>"Move Left ",proc=>sub{
	$bat->blank($canvas);
	$bat->move([-1,0]) unless  $bat->{pos}->[0] <= 2  }} );
$io->addAction(undef,"[C",{note=>"Move Right ",proc=>sub{
	$bat->blank($canvas);
	$bat->move([1,0]) unless $bat->{pos}->[0] >= 68  }} );
$io->addAction(undef,"p",{note=>"PaUSE ",     proc=>sub{
     $stopUpdates=$stopUpdates?0:1;}}    );

$io->updateAction(\&update);
$io->run();	

sub update{
	missed() unless  @{$spriteBank->{groups}->{ball}};
	foreach my $bll (@{$spriteBank->{groups}->{ball}}){
		my ($edge,$dir)=$bll->edge();

		if  ($bll->collide($bat)){
			$bll->{vel}->[1]=abs ($bll->{vel}->[1]);
			my $batside=4*($bll->{pos}->[0]-$bat->{pos}->[0]+1)/($bat->{geometry}->[0]+2);
			$bll->{vel}->[0]=(-2,-1,1,2)[$batside];
			$beep->playSound(undef,"B1") if ($bll->{skipped}==$bll->{skip});
		#	printAt(20,25,($bll->{pos}->[0]-$bat->{pos}->[0]+1)."   " );
		}
		elsif ($edge ne ""){
			if ($edge =~ "Bot"){
				$bll->{destroyed}=1;
			} 
			$bll->{vel}->[1]=abs($bll->{vel}->[1])*$dir->[1] if ($dir->[1]);
			$bll->{vel}->[0]=abs($bll->{vel}->[0])*$dir->[0] if ($dir->[0]);;
			# printAt(20,15,$edge." ".$bll->{vel}->[1]);
		}
		else{
			nextLevel() unless @{$spriteBank->{groups}->{wall}};
			foreach my $brk (@{$spriteBank->{groups}->{wall}}){
				if ($bll->collide($brk)){
					$beep->playSound(undef,"A#1");
					$score+=$brk->{etc}->{points};
					special($brk,$bll);
					if ($bll->{pos}->[1] ==$brk->{pos}->[1]){ # if hitting side of brick
						$bll->{vel}->[0]=($bll->{pos}->[0] <=$brk->{pos}->[0])?-abs ($bll->{vel}->[0]):abs ($bll->{vel}->[0]);
					} 
					else {
						$bll->{vel}->[1]=($bll->{pos}->[1] >$brk->{pos}->[1])?abs ($bll->{vel}->[1]):-abs ($bll->{vel}->[1]);
					}
					$bll->move();
					$bll->blankPrev($canvas);
				}
			}
		}
	}
	$spriteBank->update($canvas);
	$canvas->draw();
	#printAt(20,10,$ball->{pos}->[0]." ".$ball->{pos}->[1]);
    printAt(2,40,"Score: $score Level: $level, Lives ".colour("red")."♥ "x$lives.colour("reset") );
}

sub newWall{
	for my $row (0..5){
	for my $col (0..16){
		my $colour=(qw/red yellow green magenta cyan white blue/)[rand()*7];
		$spriteBank->addSprite("wall", new Term::Graille::Sprite (shape=>$colour."brick",pos=>[2+4*$col+2*($row%2),14-$row], etc=>{points=>5,type=>$colour}));
	}
}
}

sub missed{
	$lives--;
	$beep->playMusic(undef,["D1","C1","B1","A1"]);
	if ($lives){
		fontWrite($canvas,$grf,19,4,"Missed !");
		$canvas->draw();
		sleep 5;
		fontWrite($canvas,$grf,17,4,"         ");
		$ball=new Term::Graille::Sprite(pos=>[$bat->{pos}->[0],3],vel=>[1,1],bounds=>[1,14,70,-1],skip=>6);
		$spriteBank->addSprite("ball",$ball);
	}
	else{
		fontWrite($canvas,$grf,9,8,"The Wall Wins");
		
		$canvas->draw();
		$io->stop();
		exit;
	}
}

sub nextLevel{
	$beep->playMusic(undef,["A2","B2","C2","D2"]);
	fontWrite($canvas,$grf,2,4,"Wall ".$level++." Destroyed !");
	$canvas->draw();
	sleep 2;
	$canvas->clear();
	newWall();
	$spriteBank->drawAll($canvas);
}

sub special{
	my ($brick,$ball)=@_;
	$brick->{destroyed}=1;
	my $type=$brick->{etc}->{type};
	my $message=" $type brick hit ";
	if ($type eq "blue"){
		$message.="10pts Ball moves faster ";
		$score+=10;
		$ball->{skip}=4;
	}
	elsif($type eq "red"){
		$message.="100pts Ball moves slower ";
		$score+=100;
		$ball->{skip}=8;
	}
	elsif($type eq "magenta"){
		$message.="1000pts  Destroys nearby bricks ";
		$score+=1000;
		foreach my $brk (@{$spriteBank->{groups}->{wall}}){
			if ((($brk->{pos}->[0]-$ball->{pos}->[0])**2 + ($brk->{pos}->[1]-$ball->{pos}->[1])**2)<30){
				$brk->{destroyed}=1;
			}
		}
	}
	elsif($type eq "yellow"){
		$message.="500pts  Destroys entire row ";
		$score+=1000;
		foreach my $brk (@{$spriteBank->{groups}->{wall}}){
			unless ($brk->{pos}->[1]-$brick->{pos}->[1]){
				$brk->{destroyed}=1;
			}
		}
	}
	elsif($type eq "green"){
		$message.="1000pts all green bricks disappear ";
		$score+=1000;
		foreach my $brk (@{$spriteBank->{groups}->{wall}}){
			if ($brk->{etc}->{type} eq "green"){
				$brk->{destroyed}=1;
			}
		}
	}
	elsif($type eq "white"){
		$message.="100pts multiple balls";
		$score+=100;
		$spriteBank->addSprite("ball",new Term::Graille::Sprite(pos=>[@{$bat->{pos}}],vel=>[int(rand()*3)-1,1],bounds=>[1,14,70,-1],skip=>6));
		
	}
	
	unless (exists $help->{$type} && $help->{type}++>2){
		$help->{$type}//=1;
		$canvas->textAt(17,15,$message);
		$canvas->draw();
		sleep 1;
		$canvas->textAt(17,15," "x length $message,);
		$canvas->draw();
	}
	
}

