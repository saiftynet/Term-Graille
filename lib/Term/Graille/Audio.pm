=head1 NAME
Term::Graille::Audio

Modal hierarchical Menu system

=head1 SYNOPSIS
 
    use Term::Graille::Audio;            # TERM::Graille's Audio module
    
    my $beep=Term::Graille::Audio->new();# create object;    
    $beep->playSound(undef, "A#1");      # use built-in samples to play a note



=head1 DESCRIPTION

Developed to use Audio in Braille Applications.  Again the empahsis
to try and avoid external libraries.  It does neeed some things to connect
with sound hardware though.  Linux systems need pulseaudio utilities
Winodws is as yet untested.  Windows systems need Win32::Sound


=begin html

<img src="https://user-images.githubusercontent.com/34284663/185751328-f5b67fa4-c77d-40b0-ac3a-0c6c93239fae.gif">

=end html


=head1 FUNCTIONS

=cut


package Term::Graille::Audio;

use strict; use warnings;
use IO::File; 
use Time::HiRes ("sleep");      # allow fractional sleeps
use if $^O eq 'MSWin32', "Win32::Sound";
use Storable;
use utf8;

our $VERSION= 0.01;

our $dsp;

=head3 C<my $beep=Term::Graille::Audio-E<gt>new(%params)>

Creates a new audio interface object; params are
C<samples> samples stored in external files may be loaded allowing 
different sounds to be played back.  These are stored and retrieved
as Storable files.  This is optional, an if not supplied,
Term::Graille::Audio gnerates its own sinwave sample.

=cut


sub new{
	my ($class,%params)=@_;
	my $self={};
	our $dsp;
	bless $self, $class;
	$self->{samples}={};
	if ($params{samples}){
		my @files=ref $params{samples}?@{$params{samples}}:($params{samples});
		foreach my $file (@files){
			my $name=$file; $name =~ s{^.*[/\\]|\.[^\.]+$}{}g;
			$self->{samples}->{$name}=retrieve($file) if (-e $file)
		}
	}
	else{
		 $self->makeSampleSet();
		};
	return $self;
}

sub start{
	my $self=shift;
	if ($^O eq 'MSWin32'){
	   our $dsp = new Win32::Sound::WaveOut(8000, 8, 1);
	} 
	else{
	   open(our $dsp,"|padsp tee /dev/dsp > /dev/null") or warn "DSP can not be intiated $!";
    }	 
}

sub makeSampleSet{ # generates full from C0 t0 B8 (96 notes)
	my ($self,$name, $middleA, $sps,$type)=@_;
	$name//="default";
	$middleA//=419;
	$sps//=1024;
	my @octaves=("C","C#","D","D#","E","F","F#","G","G#","A","A#","B") x 8; # create 96 notes
	my @keys= map{$octaves[$_].(int ($_/12)) }(0..$#octaves);               # append the octave number
	$self->{samples}->{$name}={keys=>\@keys,sps=>$sps,middleA=>$middleA};
	for my $k(1..scalar @keys){
		$self->{samples}->{$name}->{$keys[$k-1]}=makeNotes($self,$middleA,$sps,$k-58,$type);
	}
}


sub record{
	my ($self,$sps)=@_;
	my ($buffer,$recording);
	open (my $rec, "< :raw :bytes","|padsp /dev/dsp") or die "Could not open for recording $!";
	binmode($rec);
	$recording.=$buffer while (read($rec, $buffer, $sps));
	close $rec;
	return $recording;
}



#A term::Graille Specific Piano Keyboard can be setup and drawn

sub setupKeyboard{
	my ($self,$canvas,$params)=@_;
	$self->{canvas}=$canvas;
	$self->{keyboard}={};
	my %default;
	@default{qw/top left vSep hSep/}=(55,20,4,8);
	foreach (qw/top left vSep hSep/){
		$self->{keyboard}->{$_}=$params->{$_}//$default{$_};
	};
	$self->{keys}={};
	no warnings qw{qw};
#	my ($top,$left,$vSep,$hSep)=(55,20,4,8);
	my @keyNotes=([[qw/1  2  3  4  5  6  7  8  9  0  - = /],
	               [qw/.  C# D# .  F# G# A# .  C# D# . F#/]],
	              [[qw/q  w  e  r  t  y  u  i  o  p  [/],
	               [qw/C  D  E  F  G  A  B  C  D  E  F/]],
	              [[qw/a  s  d  f  g  h  j  k  l  ; /],
	               [qw/G# A# .  C# D# .  F# G# A# . /]],
	              [[qw{\ z x c v b n m , . /}],
	               [qw/G A B C D E F G A B C/]],
	               );
	my @rowShift=(0,4,8,4);   
	for my $keyRow (0..$#keyNotes){
		my @keys=@{$keyNotes[$keyRow]->[0]};
		my @notes=@{$keyNotes[$keyRow]->[1]};
		foreach my $keyPos(0..$#keys){
			$self->{keys}->{$keys[$keyPos]}={
				x=>$self->{keyboard}->{hSep}*$keyPos+$self->{keyboard}->{left}+$rowShift[$keyRow],
				y=>$self->{keyboard}->{top}-3*$self->{keyboard}->{vSep}*$keyRow,
				n=>$notes[$keyPos],
				c=>$keyRow%2?"black on_white":"white on_black",
			} unless $notes[$keyPos] eq ".";						
		}
	}   
};

sub drawKeyboard{
	my ($self)=@_;
	for my $key (keys %{$self->{keys}}){
		$self->drawKey($key)
	}
}

sub drawKey{
	my ($self,$key,$colour)=@_;
	return unless $key && defined $self->{keys}->{$key};
	my ($x,$y,$n,$c)=@{$self->{keys}->{$key}}{qw/x y n c/};
	$c=$colour if $colour;
	$self->{canvas}->textAt($x,$y,$key,$c);			
	$self->{canvas}->textAt($x+4,$y," ","reset");
	$self->{canvas}->textAt($x,$y-4,$n,$c) ;		
	$self->{canvas}->textAt($x+4,$y-4," ","reset");
}

sub makeKeyboard{
	my ($self)=@_;
	
my $keyboard=<<EOK;


    ┏━━━━━━ Perl Incredibly Annoyingly Noisy Organ ━━━━━━┓
    ┃                                                    ┃
    ┃   1   2   3   4   5   6   7   8   9   0   -   =    ┃
    ┃       C#  D#      F#  G#  A#      C#  D#      F#   ┃
    ┃                                                    ┃
    ┃     q   w   e   r   t   y   u   i   o   p   [      ┃
    ┃     C   D   E   F   G   A   B   C   D   E   F      ┃
    ┃                                                    ┃
    ┃      a   s   d   f   g   h   j   k   l   ;   '     ┃
    ┃      G#  A#      C#  D#      F#  G#  A#            ┃
    ┃                                                    ┃
    ┃    \\   z   x   c   v   b   n   m   ,   .   /       ┃
    ┃    G   A   B   C   D   E   F   G   A   B   C       ┃
    ┃                                                    ┃
    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
EOK

my $key2note={
	2=>"C#3",	3=>"D#3",	5=>"F#3",	6=>"G#3",	7=>"A#3",	9=>"C#4", "0"=>"D#4", "="=>"F#4",
	q=>"C3",	w=>"D3",	e=>"E3",	r=>"F3",	t=>"G3",	y=>"A3",	u=>"B3",	i=>"C4",	o=>"D4", p=>"E4", "["=>"F4",
	s=>"G#4",  d=>"A#4", f=>"C#5", g=>"D#5", j=>"F#5", k=>"G#5", l=>"A#5", "'"=>"C#6",
	"\\"=>"G4", z=>"A4", x=>"B4", c=>"C5", v=> "D5", b=>"E5", n=>"F5", m=>"G5", ","=>"A5", "."=>"B5", "/"=>"C6",
};

 return ($keyboard,$key2note);
}



=head3 C<my $beep-E<gt>saveSampleSet($name,$path)>

Saves a sample set to file to directory (adds an extenison ".spl)

=cut

sub saveSampleSet{
	my ($self,$name,$directory)=@_;
	store($self->{samples}->{name}, $directory."/".$name.".spl");
}

=head3 C<my $beep-E<gt>saveSampleSet($name,$path)>

loads a sample set from full path, excludes the extension in the name;

=cut

sub loadSampleSet{
	my ($self,$file)=@_;
	my $name=$file; $name =~ s{^.*[/\\]|\.[^\.]+$}{}g;
	$self->{samples}->{$name}=retrieve($file) if (-e $file)
}

sub makeNotes{
	my ($self, $middleA, $sps, $offset, $type)=@_;
	$offset//=0;
	my $f=$middleA*2**($offset/12); 
	my $s=pack'C*',map 127*(1+sin(($_*2*3.14159267*$f)/$sps)),0..$sps-1; # generate the sample   
	return {f=>sprintf("%.2f",$f),s=>$s};
}


=head3 C<my $beep-E<gt>playSound($name,$soundName)>

Plays a note from the samplesset ($name).  If sampleset is undefined then
the builtin-"default" sample set is used.

=cut

sub playSound{
	my ($self, $seriesName, $soundName)=@_;
	$seriesName//="default";
	my $b;
	if (exists $self->{samples}->{$seriesName}){
		$b=$soundName=~/^\d/?
		     $self->{samples}->{$seriesName}->{$self->{samples}->{$seriesName}->{keys}->[$soundName]}->{s}:
		     $self->{samples}->{$seriesName}->{$soundName}->{s};
	}
	elsif (exists $self->{sounds}->{$seriesName}){
		$b=$soundName=~/^\d/?
		     $self->{samples}->{$seriesName}->{$self->{samples}->{$seriesName}->{items}->[$soundName]}->{s}:
		$b= $self->{sounds}->{$seriesName}->{$soundName}->{s};
	}
	return unless $b;
	#$self->start() unless $dsp;
	#while (length $b){$b=substr $b,syswrite $dsp,$b};
	$self->data2Device($b);
}

sub data2Device{
	my ($self,$data)=@_;
	$self->start() unless $dsp;
	if ($^O eq 'MSWin32'){
		   $dsp->Load($b);       # get it
		   $dsp->Write();           # hear it
	    } 
	else{
	       while (length $data){$data=substr $data,syswrite $dsp,$data};
     }
	
}

sub playMusic{
	my ($self,$seriesName,@musicnotes)=@_;
	$seriesName//="default";
	foreach(@musicnotes){
		~/P(\d+)/ && sleep("0.2");
		~/\d/ && $self->playSound($seriesName,$_);
	}
}
1;
