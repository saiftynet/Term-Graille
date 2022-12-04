#!/usr/env perl
########## Audio Analyser ###########
use strict; use warnings;
use lib "../lib/";

use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact;
use Term::Graille::Menu; 
use Term::Graille::Font  qw/loadGrf fontWrite/;

my $io=Term::Graille::Interact->new();   # For interactions menu and keyboard
$io->{debugCursor}=[22,45];              # Put key presses detected ny Interact on the screen

my ($source,$recorder,$fh,$buffer,@data);

my $canvas = Term::Graille->new(
    width  => 120,
    height => 60,
    top=>4,
    left=>10,
    borderStyle => "double",
    borderColour => "blue",
    title => "Audio-Analyser",
    titleColour => "red",
  );

# draw the initial screen
my $grf=loadGrf("./fonts/ZX Times.grf");
fontWrite($canvas,$grf,11,13,"Mic Input");
fontWrite($canvas,$grf,13,10,"Waveform");
fontWrite($canvas,$grf,13,7,"Analyser");
$canvas->textAt(15,20,"A  not-so-realtime visual audio analyser for","green italic");
$canvas->textAt(40,16,"Microphone inputs","yellow italic");
$canvas->textAt(16,8,"  ");
$canvas->textAt(24,4,"  ");

my @listCaptures=`arecord -l`;
my %devices=map{ /card (\d+):[^\[]+(\[[^\]]+\]), device (\d+)/ ;$2 =>"hw:$1,$3" }
            grep /card (\d+):[^\[]+(\[[^\]]+\]), device (\d+)/ , @listCaptures;   

my $menu=new Term::Graille::Menu(
          menu=>[["Monitor","Start","Stop"],
                 ["Source",keys %devices],
                 ["Play","Raw",["Filters","HiPass","LowPass"]],
                 "About"],
          redraw=>\&refreshScreen,
          dispatcher=>\&menuActions,
          );

my %actions=(
     Start=>sub{		 
		 $io->{refreshRate}=1;
		 $io->updateAction(sub {recordDisplay()	}	);		
	 },
     Stop=>sub{
		 $io->{refreshRate}=20;
		 close $fh if $fh;;
		 kill $recorder if $recorder;
		 $io->stopUpdates();
	 },
);

sub recordDisplay{
	   return unless $source;
	   my ($cmd,$rawData);
	   
	   # using arecord...not sure in arecord can record fractional seconds
	   $cmd =  "arecord -D $source -c 1 -d 1 -q";
	   $rawData = '';
	   $recorder = open ($fh, '-|:raw', $cmd )or die "Couldn't launch [$cmd] $!"; 
	   
	   while (1) {
		my $success = read $fh, $rawData , 100, length($rawData);
		die $! if not defined $success;
		last if not $success;
	  }
	  
	  @data= unpack 'C*', $rawData ;
	  close $fh;
	  kill $recorder;
	  printAt(2,60,scalar @data);
	  #$canvas->clear();
	  $canvas->scroll("l",undef,10);
	  for my $pt (40..$#data){
			next unless $pt%2;
			my $d=$data[$pt];
			my $c=(qw/white cyan blue green yellow yellow magenta red/)[abs ($d-128)/16];
			my $l=60*$d/2**8;$l+=$l>30?-30:30;
			$canvas->set(99+(20*$pt/(@data-40)),$l,colour($c));
		}
		$canvas->draw();
}


foreach my $dev(keys %devices){
	$actions{$dev}=sub{
		kill $recorder if $recorder;
		$recorder=undef;
		$source=$devices{$dev};
	}
} 
   
sub menuActions{
	my ($action)=@_;
	if (exists $actions{$action}){
		$actions{$action}->($io->{gV})
	}
};

$io->addObject(object => $menu,trigger=>"m");
$canvas->draw();
$io->run();

sub refreshScreen{
	clearScreen() unless (shift);
	$canvas->draw();
}
