#!/usr/env perl
############### PulsAudio Utils #####################
#https://wiki.archlinux.org/title/PulseAudio/Examples#
use strict; use warnings;
use lib "../lib/";

use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact;
use Term::Graille::Menu; 
use Term::Graille::Font  qw/loadGrf fontWrite/;

our $VERSION=0.01;

my $canvas = Term::Graille->new(
    width  => 140,
    height => 60,
    top=>4,
    left=>4,
    borderStyle => "double",
    borderColour => "blue",
    title => " PulseAudio ",
    titleColour => "red",
  );
  
splashScreen();

my $paList=paCtl();
my ($listMenu,$itemToObject)=makeListMenu();

my $io=Term::Graille::Interact->new();   # For interactions menu and keyboard
$io->{debugCursor}=[22,45];              # Put key presses detected ny Interact on the screen

my $menu=new Term::Graille::Menu(
          menu=>[["Global","Reset","Dump","Exit"],
          $listMenu,
          ["Sound","Record","Playback"],
          "About"],
          redraw=>\&refreshScreen,
          dispatcher=>\&menuActions,
          );

my %actions=(
     Reset=>sub{	
	 },
     Stop=>sub{
	 },
	 About=>sub{
		 splashScreen($canvas);
	 }
);

sub menuActions{
	my ($action,$bc)=@_;
	return unless $action;
	if (exists $actions{$action}){
		$actions{$action}->()
	}
	else{
		if ($bc->[0] == 1){  # View Items
			my $mGroup=$bc->[1];
			my $mIndex=$bc->[2];
				#ie "$mGroup  $mIndex $itemToObject";
			objectDescribe(@{$itemToObject->[$mGroup]->[$mIndex]})
		};
	}
};

$io->addObject(object => $menu,trigger=>"m");
$canvas->draw();
$io->run();	
	
sub splashScreen{
	$canvas->clear();
	my $grf=loadGrf("./fonts/ZX Times.grf");
	fontWrite($canvas,$grf,3,13,"PulseAudio Utils");
	fontWrite($canvas,$grf,1,10,"Tool to Play with");
	fontWrite($canvas,$grf,13,7,"Linux Audio");
	$canvas->textAt(30,20,"An interactive shell for pacat pacmd pactl","green italic");
	$canvas->textAt(38,16,"(parec paplay pamon padsp etc)","yellow italic");
	$canvas->textAt(40,12,"Version $VERSION (GRAILLE ".$Term::Graille::VERSION.")","yellow italic");
	$canvas->textAt(40,8,"(m key brings up the menu)","cyan bold");
	$canvas->draw();
}

sub refreshScreen{
	clearScreen() unless (shift);
	$canvas->draw();
}

sub paCtl{
	my $paList={};
	my $currentType;my $index;my $currentKey;
	foreach my $line (`pactl list`){
		chomp $line;
		if ($line=~/^([A-Z][a-z]+) #(\d+)/){
			$currentType=$1; $index=$2;
			$paList->{$currentType}//=[];
			$paList->{$currentType}->[$index]={};
			$currentKey="";
		}
		next unless defined $index;
		if($line=~/^\t([A-Z\sa-z]+): (.+)/){
			$currentKey=$1;
			$paList->{$currentType}->[$index]->{$1}=$2;
		}
		elsif($line=~/^\t([A-Z\sa-z]+):(\s)*$/){
			$currentKey=$1;
		}
		elsif($line=~/^\t\t([A-Z\._a-z]+) = "(.+)"/){
			$paList->{$currentType}->[$index]->{$currentKey}//={};
			$paList->{$currentType}->[$index]->{$currentKey}->{$1}=$2;
		}
		elsif($line=~/^\t\t([A-Z\sa-z]+): (.+)/){
			$paList->{$currentType}->[$index]->{$currentKey}//=[];
			push @{$paList->{$currentType}->[$index]->{$currentKey}},{$1=>$2};
		}
		else{
			$paList->{$currentType}->[$index]->{$currentKey}.="\n".$line unless ref $paList->{$currentType}->[$index]->{$currentKey}
		}
	}
	return $paList
}

sub makeListMenu{
	my $lM=["List"];
	my $i2O=[];my $menuTypePosition=0;
	for my $type (reverse sort keys %$paList){
		 my @list=@{$paList->{$type}};
		 my $n=0;my $ind=0; my $splitList=0;my $start=0;my $end=0;my $typeList=[];
		 while ($ind<=$#list){
			 $i2O->[$menuTypePosition]//=[];
			 my $i=object2listItem($type,$ind);
			 if ($i){
				 push @$typeList, $i;
				 push @{$i2O->[$menuTypePosition]},[$type,$ind];
			 }
			 if (@$typeList>=10){ # list is full so populate and start new list
				 $splitList=1;
				 $end=$ind;
				 push @$lM, ["$type $start-$end",@$typeList];
				 $start=$end+1;
				 $typeList=[];
				 $menuTypePosition++;
			 }
			 $ind++;
		 }
		 if ($splitList && @$typeList){ # list is split so needs new list
				 $end=$ind;
				 push @$lM, ["$type $start-$end",@$typeList];
		 }
		 elsif(@$typeList){ # list is not split so submit as is
			  push @$lM, [$type,@$typeList];
		 }	 
		 else{   # list is empty so discard
			 $menuTypePosition--
		 }
		 $menuTypePosition++;
	}
		return $lM,$i2O;
}

sub object2listItem{
	my ($type,$index)=@_;
	return undef unless $paList->{$type}->[$index];
	return ($type eq "Client") ?
	       substr($paList->{$type}->[$index]->{Properties}->{'application.name'},0,30):
	       $paList->{$type}->[$index]->{Name};
	
}

sub objectDescribe{
	my ($type,$index)=@_;
	my $target= $paList->{$type}->[$index];
	my ($x,$y)=(15,56);
	$canvas->clear();
	$canvas->textAt($x,$y,object2listItem($type,$index),"green bold"); $y-=4;
	if ($type =~/^Sink|Source$/){
		my @volume =split(/[,\n]\s+/,$target->{'Volume'});
		$canvas->textAt($x,$y,"Description   : ".$target->{Properties}->{'device.description'},"cyan"); $y-=4;
		$canvas->textAt($x,$y,"Device String : ".$target->{Properties}->{'device.string'},"cyan"); $y-=4;
		$canvas->textAt($x,$y,"Specification : ".$target->{'Sample Specification'},"cyan"); $y-=4;
		for (0..$#volume){
		  $canvas->textAt($x,$y,"Volume        : ".$volume[$_],"cyan"); $y-=4;
	    }
		$canvas->textAt($x,$y,"Card          : ".$target->{Properties}->{'alsa.card_name'},"cyan"); $y-=4;
	}
	elsif ($type =~/^Module$/){
		$canvas->textAt($x,$y,"Description     : ".$target->{Properties}->{'module.description'},"cyan"); $y-=4;
		if ($target->{'Argument'}){
		  my @argument =split(/\s+/,$target->{'Argument'});
		  for (0..$#argument){
			   $canvas->textAt($x,$y,"Argument        : ".$argument[$_],"cyan"); $y-=4;
		  }
	    }
	}
	elsif ($type =~/^Client$/){
		$canvas->textAt($x,$y,"Driver     : ".$target->{'Driver'},"cyan"); $y-=4;
		if ($target->{Properties}->{'application.process.id'}){
			$canvas->textAt($x,$y,"Binary     : ".$target->{Properties}->{'application.process.binary'},"cyan"); $y-=4;
			$canvas->textAt($x,$y,"PID        : ".$target->{Properties}->{'application.process.id'},"cyan"); $y-=4;
		}
	}	
	elsif ($type =~/^Sample$/){
		$canvas->textAt($x,$y,"Duration : ".$target->{'Duration'},"cyan"); $y-=4;
		$canvas->textAt($x,$y,"Size     : ".$target->{'Size'},"cyan"); $y-=4;
		$canvas->textAt($x,$y,"Spec     : ".$target->{'Sample Specification'},"cyan"); $y-=4;
		my $filename=$target->{Properties}->{'media.filename'}//$target->{'Filename'};
		if ($filename){
			$canvas->textAt($x,$y,"Filename : ".$filename,"cyan"); $y-=4;
		}
		if ($target->{Properties}->{'application.process.id'}){
			$canvas->textAt($x,$y,"Binary   : ".$target->{Properties}->{'application.process.binary'},"cyan"); $y-=4;
			$canvas->textAt($x,$y,"PID      : ".$target->{Properties}->{'application.process.id'},"cyan"); $y-=4;
		}
	}
	elsif ($type =~/^Card$/){
		
		$canvas->textAt($x,$y,"Active Profile : ".$target->{'Active Profile'},"cyan"); $y-=4;
		for (["device.description" ,"Description    : "],
		     ["alsa.long_card_name","Card Name      : "],
		     ["device.bus"         ,"Device Bus     : "],
		     ["device.vendor.name" ,"Vendor Name    : "],
		     ["device.product.name","Product Name   : "],){
				 $canvas->textAt($x,$y,$_->[1].$target->{Properties}->{$_->[0]},"cyan"); $y-=4;
				 
		}
	}
	$canvas->draw();
	
}
