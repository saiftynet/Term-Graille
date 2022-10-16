package  Term::Graille::Dialog;

use strict;use warnings;
use lib "../../../lib";
use Term::Graille qw/colour printAt clearScreen border cursorAt wrapText/;
use base 'Exporter';
our @EXPORT_OK = qw/deathSentence confirm prompt caution/;
use utf8;

=head3 C<my $dialog=Term::Graille::Dialog-E<gt>new(%params)>

Creates a new dialog box; params are
C<options> the possible options that may be selected  
C<redraw> This is a function to redraws the application screen.
The dialog box may overwrite parts of the application screen, and this 
function needs to be provided to restore the screen.
C<callback> The dialog does not call any functions itself, instead returns the
button value pressed. if the $dialog->{entry} is set this is also sent.  In
prompts, the entry is populated by user.  It is upto the main application
to use this data (the callback function supplied)
C<pos> Optional. The default position is [2,2], but setting this parameter allows 
the dialog to be placed elsewhere
C<highlightColour> Optional. The selected item is highlighted default "black on_white"
C<normalColour> Optional. The normal colour of text items "white on_black"


=cut

my %icons=(
   die=>    [[colour("red")."⢰","⠪","⣛","⠍","⠩","⣛","⠝","⡆"],
             ["⠈","⠑","⢤","⠰","⠆","⡤","⠋","⠀"],
             ["⠛","⢧","⣀","⠉","⢉","⣡","⠞","⠛"],
             ["⣤","⡴","⠚","⠋","⠙","⠓","⢤","⣤".colour("reset")]],
   info=>   [[colour("blue")."⠀","⠐","⠿","⠿","⠂","⠀","⠀","⠀"],
	         ["⠀","⠠","⢶","⣶","⠀","⠀","⠀","⠀"],
             ["⠀","⠀","⢸","⣿","⠀","⠀","⠀","⠀"],
             ["⠀","⠀","⠘","⢿","⣤","⠼","⠃","⠀".colour("reset")]],
   error=> [[colour("yellow")."⠀","⠀","⠀","⢀","⡀","⠀","⠀","⠀"],
             ["⠀","⠀","⠸","⣭","⣿","⠇","⠀","⠀"],
             ["⠀","⠀","⠀","⠸","⠇","⠀","⠀","⠀"],
             ["⠀","⠀","⠀","⢴","⡦","⠀","⠀","⠀".colour("reset")]],
   forbidden=>[[colour("red")."⠀","⠀","⢀","⣀","⣀","⡀","⠀","⠀"],
             ["⢠","⡞","⣉","⣀","⣀","⣉","⢳","⡄"],
             ["⠘","⢧","⣉","⠉","⠉","⣉","⡼","⠃"],
             ["⠀","⠀","⠈","⠉","⠉","⠁","⠀","⠀".colour("reset")]],
   query=>[[colour("green")."⠀","⠀","⠀","⣀","⡀","⠀","⠀","⠀"],
             ["⠀","⠀","⠾","⠉","⠉","⣷","⠀","⠀"],
             ["⠀","⠀","⠀","⢠","⡞","⠉","⠀","⠀"],
             ["⠀","⠀","⠀","⢨","⡅","⠀","⠀","⠀".colour("reset")]],
);


sub new{
    my ($class,%params) = @_;  
    my $self={};
    bless $self,$class;
    
    $self->{buttons}=$params{buttons}//[];
	$self->{selected}=$params{selected}//  "";                          #if a button is tob pres elected
	
	$self->{message}=$params{message}//  "No Message";   
	
    $self->{redraw}=$params{redraw} if (exists $params{redraw});        # function to redraw application
    $self->{callback}=$params{callback} if (exists $params{callback});  # function to call after menu item selected 
    $self->{transient}=$params{transient}//1;
	$self->{title}=$params{title}//"Dialog";
	$self->{normalColour}=$params{titleColour}//"yellow";
	$self->{pos}=$params{pos}//[2,2];
	$self->{geometry}=$params{geometry}//[8,40];
	$self->{param}=$params{param};    # optional parameter
	$self->{icon}=$params{icon};
	$self->{highlightColour}=$params{highlightColour}//"black on_white";
	$self->{normalColour}=$params{normalColour}//"white on_black";
	$self->{keyAction}={
		"[D"   =>sub{$self->prevItem()},
		"[C"   =>sub{$self->nextItem()},
		"enter"=>sub{$self->selectItem()},
		"esc"  =>sub{$self->{close}->()},
		others =>sub{my ($obj,$pressed,$gV)=@_;$self->addChar($pressed)},
	};
	return $self;
}

sub mode{
	my ($self,$mode,@etc)=@_;
	for ($mode){
		/okc/i && do {$self->{buttons}=[qw/OK Cancel/]; last;};
		/ok/i && do {$self->{buttons}=[qw/OK/]; last;};
		/ync/i && do {$self->{buttons}=[qw/Yes No Cancel/]; last;};
		/input/i && do {$self->{buttons}=[qw/Submit Cancel/];
			            $self->{entry}="";$self->{entryPos}=0; last};
		
	}
	
}

sub draw{ 
	my $self=shift;
	if (!ref $self->{message}){
		$self->{message}=wrapText( $self->{message},$self->{geometry}->[1]-15);
	}
	my $entryLines=(defined $self->{entry})?2:0;
	my $buttons="";
	foreach my $button (@{$self->{buttons}}){
		$buttons.=" ".colour($self->{selected} && $self->{selected} eq $button?"black on_white":"white")."[$button]".colour("reset");
	}
    border(@{$self->{pos}},$self->{pos}->[0]+max(($self->{icon}?6:0),@{$self->{message}}+$entryLines+1),
             $self->{geometry}->[1]+$self->{pos}->[1],
             "double","green",
             $self->{title},$self->{titleColour});
    printAt($self->{pos}->[0]+1,6,[@{$self->{message}},($entryLines?($self->{entry},"-"x($self->{geometry}->[1]-4)):()),$buttons]);
    
    printAt($self->{pos}->[0]+2,$self->{geometry}->[1]-5,$icons{$self->{icon}}) if $self->{icon};
    
}


sub addChar{
	 my ($self,$ch)=@_;
	 return unless exists $self->{entry};
	 $self->{entry}.=$ch if (length $ch ==1 );
	 chop $self->{entry} if ($ch =~/back/ );
	 $self->draw();
	 
}

sub selectedPos{
	my ($self)=@_;
	return 0 unless $self->{selected};
	for my $p (0..$#{$self->{buttons}}){
		return $p if ($self->{selected} eq $self->{buttons}->[$p])
	}	
	return 0;
}

sub nextItem{
	my ($self)=@_;
	my $p=$self->selectedPos();
	$p+=($p<$#{$self->{buttons}})?1:0;
	$self->{selected}= $self->{buttons}->[$p];
	#printAt(2,50, " $p $self->{selected} ".$#{$self->{buttons}}." ".join("--",@{$self->{buttons}}));
	$self->draw();
}

sub prevItem{
	my ($self)=@_;
	my $p=$self->selectedPos();
	$self->{selected}= $self->{buttons}->[$p-($p>0)?1:0];
	#printAt(2,50, " $p $self->{selected} ".$#{$self->{buttons}}." ".join("--",@{$self->{buttons}}));
	$self->draw();
}

sub selectItem{
	my ($self)=@_;
	$self->{param}->{button}=$self->{selected};
	$self->{param}->{entry}=$self->{entry};
	if (exists  $self->{callback}) {$self->{callback}->($self->{param})};
}


sub close{  # what needs to be done before Interact de-activates widget
	my ($self)=@_;
	$self->{redraw}->();
}

sub max{
	return (sort{$a <=> $b}@_)[-1]
}

sub min{
	return (sort{$a <=> $b}@_)[0]
}

sub prompt{
	
}


sub deathSentence{  # waiting to be exported
	my $str=shift;
	my @epitaphs=(
	  "'Forgive him Larry, for he knows not how to code'",
	  "'I told you I was sick'",
	  "'It is a far far better code that I do, than you have ever run'",
	  "'Your references have been counted and found wanting'", 
	  "'Goodbye old friend, may the Schwartz be with you'",
	  "'she believed she could, but she couldn\'t'",
	 );
	my $message=[@{wrapText(colour("red").$str.colour("reset"),45)},caller(),
	             @{wrapText(colour("yellow").($epitaphs[rand(@epitaphs)]).colour("reset"),45)}];
	              
    border(10,4,11+@$message,64,"double","green","RIP","yellow");
    printAt(11,6,$message);
    printAt(12,55,$icons{die});
    
    printAt(18,0,"");
    sleep 10;
    exit;
}

sub fileSelector{
	my ($dir,$filter,$callback,$redraw,$parameter)=@_;
	
	
	
}


1;
