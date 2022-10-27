package Term::Graille::Audio;

use strict; use warnings;
use IO::File; 
use Time::HiRes ("sleep");      # allow fractional sleeps
use Storable;
use utf8;
our $VERSION= 0.01;
our $dsp;
sub new{
	my ($class,%params)=@_;
	my $self={};
	our $dsp;
	bless $self, $class;
	$self->{samples}={};
	if ($params{samples}){
		my @files=ref $params{samples}?@{$params{samples}}:($params{samples});
		foreach my $file (@files){
			my $name=$file; $name =~ s{^.*[/\\]|\.[^.]+$}{}g;
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
	open(our $dsp,"|padsp tee /dev/dsp > /dev/null") or warn "DSP can not be intiated $!"; 
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
		$self->{samples}->{$name}->{$keys[$k-1]}=makeSound($self,$middleA,$sps,$k-58,$type);
	}
}

sub makeKeyboard{
	my $self=shift;
#  thick =>{tl=>"┏", t=>"━", tr=>"┓", l=>"┃", r=>"┃", bl=>"┗", b=>"━", br=>"┛",ts=>"┫",te=>"┣",}, 	
my $keyboard=<<EOK;


    ┏━━━━━━━ Perl Incredibly Annoying Noisy Organ ━━━━━━━┓
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
	s=>"G#4",  d=>"A#4", f=>"C#5", h=>"D#5", j=>"F#5", k=>"G#5", l=>"A#5", "'"=>"C#6",
	"\\"=>"G4", z=>"A4", x=>"B4", c=>"C5", v=> "D5", b=>"E5", n=>"F5", m=>"G5", ","=>"A5", "."=>"B5", "/"=>"C6",
};

 return ($keyboard,$key2note);
}

sub saveSampleSet{
	my ($self,$name,$directory)=@_;
	store($self->{samples}->{name}, $directory."/".$name.".spl");
}

sub makeSound{
	my ($self, $middleA, $sps, $offset, $type)=@_;
	$offset//=0;
	my $f=$middleA*2**($offset/12); 
	my $s=pack'C*',map 127*(1+sin(($_*2*3.14159267*$f)/$sps)),0..$sps-1; # generate the sample   
	return {f=>sprintf("%.2f",$f),s=>$s};
}

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
		$b= $self->{sounds}->{$seriesName}->{$soundName}->{s}
	}
	return unless $b;
	$self->start() unless $self->{dsp};
	while (length $b){$b=substr $b,syswrite $dsp,$b};
	
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
