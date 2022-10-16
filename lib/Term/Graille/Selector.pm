package  Term::Graille::Selector;

use strict;use warnings;
use Term::Graille qw/colour printAt clearScreen border cursorAt/;
use utf8;

=head3 C<my $selector=Term::Graille::Selector-E<gt>new(%params)>

Creates a new $chooser; params are
C<options> the possible options that may be selected  
C<redraw> This is a function to redraws the application screen.
The chooser may overwrite parts of the application screen, and this 
function needs to be provided to restore the screen.
C<callback> The chooser does not call any functions, instead returns the
selected item(s).  It is upto the main application to use this data (the
callback function supplied)
C<pos> Optional. The default position is [2,2], but setting this parameter allows 
the chooser to be placed elsewhere
C<highlightColour> Optional. The selected item is highlighted default "black on_white"
C<normalColour> Optional. The normal colour of menu items "white on_black"


=cut


sub new{
    my ($class,%params) = @_;  
    my $self={};
    bless $self,$class;
    $self->{redraw}=$params{redraw} if (exists $params{redraw});        # function to redraw application
    $self->{callback}=$params{callback} if (exists $params{callback});  # function to call after menu item selected 
    $self->{options}=$params{options}//[];
	$self->{selected}=$params{selected}//  "";
	$self->{combo}=$params{combo}// 1;                 # combo mode...experimental
	$self->{entry}=$params{selected}//  "";
	$self->{entryPos}=0;
	$self->{pointer}=0;
	$self->{param}=$params{param}//{};                  # this hashref may be passed for persistent data
	$self->{start}=$params{start}//0;
	$self->{title}=$params{title}//"Chooser";
	$self->{normalColour}=$params{titleColour}//"yellow";
	$self->{multi}=$params{multi}//0;
	$self->{pos}=$params{pos}//[2,2];
	$self->{geometry}=$params{geometry}//[13,20];
	$self->{highlightColour}=$params{highlightColour}//"black on_white";
	$self->{normalColour}=$params{normalColour}//"white on_black";
	$self->{keyAction}={
		"[A"   =>sub{$self->prevItem()},
		"[B"   =>sub{$self->nextItem()},
		"[C"   =>sub{$self->selectItem(1)},  # passes 1 if selected with right arrow
		"enter"=>sub{$self->selectItem(2)},  # passes 2 if selected with enter  (the entry box is queried)
		"esc"  =>sub{$self->{close}->()},
		others =>sub{my ($obj,$pressed,$gV)=@_;$self->addChar($pressed)},
	};
	return $self;
}

sub draw{
	my ($self)=@_;
	border($self->{pos}->[0],$self->{pos}->[1],
	       $self->{pos}->[0]+$self->{geometry}->[0],$self->{pos}->[1]+$self->{geometry}->[1],
	       "thick",$self->{focus}?$self->{focusColour}:$self->{blurColour},
	       $self->{title},$self->{titleColour});

	$self->{start}++ while ($self->{pointer}>$self->{start}+$self->{geometry}->[0]-4); # the -4  user entry space for combo mode
	$self->{start}-- while ($self->{pointer}<$self->{start});
	printAt($self->{pos}->[0]+1,$self->{pos}->[1]+1, $self->{entry}.(" "x($self->{geometry}->[1]-length $self->{entry})));  # combo mode input linethe 
	printAt($self->{pos}->[0]+2,$self->{pos}->[1]+1, "-"x$self->{geometry}->[1]);   # lower border for user entry space for combo mode

	foreach ($self->{start}..$self->{start}+$self->{geometry}->[0]-3){ 
		if ($_<@{$self->{options}}){		
			my $colour=colour(isSelected($self,$self->{options}->[$_])?"black on_white":"white");
			$colour.=colour(($_==$self->{pointer})?"underline":"");
			printAt($self->{pos}->[0]+$_+3-$self->{start},$self->{pos}->[1]+1,  #+3 is for user entry space for combo mode
			        $colour.$self->{options}->[$_].colour("reset"));
		}
	}
}

sub addChar{
	 my ($self,$ch)=@_;
	 $self->{entry}.=$ch if (length $ch ==1 );
	 chop $self->{entry}if ($ch =~/back/ );
	 $self->draw();
	 
}

sub setSelected{
	my ($self,$item)=@_;
	for my $o (0..$#{$self->{options}}){
		if ($self->{options}->[$o] eq $item){
			if ($self->{multi}==0){
				$self->{selected}=[$o]
			}
			else{
				# for multiselect
			}
		}
	}
}

sub isSelected{
	my ($self,$item)=@_;
	my $sel=ref($self->{selected})?$self->{selected}:[$self->{selected}];
	for my $s (@{$sel}){
		return 1 if ($s eq $item)
	}
	return 0	
}

sub nextItem{
	my ($self)=@_;
	$self->{pointer}++ unless ($self->{pointer} >=$#{$self->{options}});
	$self->draw();
	return $self->{options}->[$self->{pointer}];
}

sub prevItem{
	my ($self)=@_;
	$self->{pointer}-- unless ($self->{pointer} <=0);
	$self->draw();
	return $self->{options}->[$self->{pointer}];
}

sub selectItem{
	my ($self,$submitMethod)=@_;
	if ($self->{multi}==0){
		$self->{selected}=($self->{entry} and ($submitMethod == 2))?$self->{entry}:$self->{options}->[$self->{pointer}];
		$self->{redraw}->();
		$self->{callback}->({selected=>$self->{selected},method=>$submitMethod}) if $self->{callback};
		return $self->{options}->[$self->{pointer}];
	}
	else{
		#for multiselect
	}
}

sub close{  # what needs to be done before Interact de-activates widget
	my ($self)=@_;
	$self->{redraw}->();
}

1;
