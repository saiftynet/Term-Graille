use strict; use warnings;
use lib "../lib";
use Term::Graille::Audio;

my $beep=Term::Graille::Audio->new();    # TERM::Graille's Audio module
$beep->playSound(undef, "A#1");
