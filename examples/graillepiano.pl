use strict; use warnings;
use lib "../lib";

use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact;
use Term::Graille::Menu; 
use Term::Graille::Audio;
use Term::Graille::Font  qw/loadGrf fontWrite/;

my $beep=Term::Graille::Audio->new();    # TERM::Graille's Audio module
my $io=Term::Graille::Interact->new();   # capture keyboard actions
our $VERSION=0.01;

my $canvas = Term::Graille->new(
    width  => 140,
    height => 60,
    top=>4,
    left=>4,
    borderStyle => "double",
    borderColour => "blue",
    title => " A Graille Piano ",
    titleColour => "red",
  );
  
splashScreen();
$canvas->clear();
my ($keyboard,$key2note)=$beep->makeKeyboard;
$beep->setupKeyboard($canvas);
$beep->drawKeyboard();
$canvas->draw();
my $lastKey;

$io->addAction("MAIN","others",{proc=>sub{
      my ($pressed,$GV)=@_;
      if (exists $key2note->{$pressed}){
		  $beep->drawKey($lastKey);
		  $beep->playSound(undef, $key2note->{$pressed});
		  $beep->drawKey($pressed,"red on_green");
		  $lastKey=$pressed;
		  $canvas->draw();
	  };
    }
  }
);

$io->addAction("MAIN","esc",{proc=>sub{
      exit 1;
    }
  }
);

$io->run();

sub splashScreen{
	$canvas->clear();
	my $grf=loadGrf("./fonts/ZX Times.grf");
	fontWrite($canvas,$grf,3,13,"Monophonic Piano");
	fontWrite($canvas,$grf,3,10,"A simple demo of");
	fontWrite($canvas,$grf,2,7,"Interactive Audio");
	$canvas->textAt(30,20,"Press Esc then m to get menu; Enter to start","green");
	$canvas->draw();
}
