=head1 NAME
Term::Graille::Menu - Simple modal menuing system for Graille
=head1 SYNOPSIS
 
    my $menu=new Term::Graille::Menu(
          menu=>[["File","New","Save","Load","Quit"],["Edit","Clear",["Reformat","2x4","4x4"],["Scroll","left","right","up","down"]],"About"],
          redraw=>\&main::refreshScreen, # function to redraw the application screen 
          callback=>\&main::menuActions, # Items that are selected are passed as a string to a dispatcher
          );


=head1 DESCRIPTION

This menuing system allows intuitive user interaction modelled on a typical top menubar found in many appluication.
The key for this module is simplicity in use, allowing rapid creation and deployment.  The menuing system itself requires a
=begin html
<img src="https://user-images.githubusercontent.com/34284663/180637940-01b583a0-1a71-4a5d-a29b-394a940ce46f.gif">
=end html
=head1 FUNCTIONS

package  Term::Graille::Menu;

our $VERSION=0.09;

use strict;use warnings;
use Storable qw(dclone);
use Term::Graille qw/colour printAt clearScreen/;

sub new{
    my ($class,%params) = @_;  
    my $self={};
    bless $self,$class;
    $self->{menu}=$params{menu}//[];
    $self->{redraw}=$params{redraw} if (exists $params{redraw});        # function to redraw application
    $self->{callback}=$params{callback} if (exists $params{callback});  # function to call after menu item selected 
	$self->{breadCrumbs}=[0];
	$self->{pos}=$params{pos}//[2,2];
	$self->{highlightColour}=$params{highlightColour}//"black on_white";
	$self->{normalColour}=$params{normalColour}//"white on_black";
	return $self;
}

sub setMenu{
	my ($self,$menu)=@_;
	$self->{menu}=$menu;
}

sub redraw{
	my $self=shift;
	$self->{redraw}->();
	
}
	
sub nextItem{
	my $self=shift;
	$self->{breadCrumbs}->[-1]++ ;
	$self->{breadCrumbs}->[-1]-- if ($self->drillDown() == 0);
	$self->drawMenu();
}

sub prevItem{
	my $self=shift;
	$self->{breadCrumbs}->[-1]-- unless $self->{breadCrumbs}->[-1]==0;
	$self->drawMenu();
}

sub closeItem{
	my $self=shift;
	if ($self->depth()>1){
		pop @{$self->{breadCrumbs}};
	    $self->drawMenu();
	}
	else{  # if at top level close menu;
		$self->redraw() if defined $self->redraw() ;
		$self->{callback}->(undef) if $self->{callback};;
	}
}

sub openItem{# enter submemnu if one exists, or "open" the item;
	my $self=shift;
    my ($label,$submenu)=@{$self->drillDown()};
    if ($submenu) {
		$self->{breadCrumbs}=[@{$self->{breadCrumbs}},0];
		$self->drawMenu();
	}
    else{
		$self->{callback}->($label) if $self->{callback};
	} 		
}

sub upArrow{
	my $self=shift;
	if ($self->depth()==1){
		$self->closeItem();
	}
	else{
		$self->prevItem
	}
}

sub downArrow{
	my $self=shift;
	if ($self->depth()==1){
		$self->openItem();
	}
	else{
		$self->nextItem();
	}
}

sub leftArrow{
	my $self=shift;
	if ($self->depth()==1){
		$self->nextItem();
	}
	else{
		$self->openItem();
	}
}

sub rightArrow{
	my $self=shift;
	if ($self->depth()==1){
		$self->prevItem();
	}
	else{
		$self->closeItem();
		$self->{redraw}->();
		$self->drawMenu();
	}
}


sub drillDown{ # return curent item, and whether it has children;
	my $self=shift;
	my $tmp=dclone($self->{menu});
	foreach  my $level (0..$#{$self->{breadCrumbs}}){
		return 0 unless $tmp->[$self->{breadCrumbs}->[$level]];
		shift @{$tmp} unless ($level==0);
		$tmp=$tmp->[$self->{breadCrumbs}->[$level]];
	}
	return ref $tmp?[$tmp->[0],1]:[$tmp,0];
}

sub drawMenu{
	my $self=shift;
	my $pos=[@{$self->{pos}}]; # get a copy of contents of $self->{pos}
	foreach my $level (0..$#{$self->{breadCrumbs}}){
		$pos = $self->drawLevel($level,$self->{breadCrumbs}->[$level],$pos)
	}
}

sub drawLevel{
	my ($self,$level,$ai,$pos)=@_;
	my $nextPos=$pos;
	if (!$level){
		foreach my $mi (0..$#{$self->{menu}}){
			my $label=((ref $self->{menu}->[$mi])?$self->{menu}->[$mi]->[0]:$self->{menu}->[$mi]);
			my $active=($ai == $mi?1:0);
			if ($active){$nextPos=[$nextPos->[0]+1,$pos->[1]]}
			printAt(@$pos,$self->highlight($label,$active). " ");
			$pos->[1]+=(1+length $label);
		}
		print "\n";
	}
	else{
		my $tmp=dclone($self->{menu});
		my $l=0;
		while ($l<$level){  # walk down the tree until level to be printed
			$tmp=$tmp->[$self->{breadCrumbs}->[$l]];
			shift @{$tmp} ;
			$l++
		}
		my $longest=-1;
		foreach(@$tmp){
			my $il=length(ref $_?$_->[0]:$_);
			$longest=$il if ($longest<$il);
			};
		
		my $hOffset= " " x $pos->[1];
		foreach my $mi (0..$#{$tmp}){ # skip first item which is label for list 
			my $label=((ref $tmp->[$mi])?$tmp->[$mi]->[0]:$tmp->[$mi]);
			my $active=(($ai) == $mi?1:0);
			if ($active){$nextPos=[$pos->[0],$pos->[1]+$longest]}
			printAt(@$pos,$self->highlight($label,$active,$longest));
			$pos->[0]+=1;
		}
	}
	return $nextPos;
}

sub depth{
	my $self=shift;
	return scalar @{$self->{breadCrumbs}};
}

sub highlight{
	my ($self,$str,$hl,$padding)=@_;
	my $space=$padding?(" "x($padding-length $str)):"";
	return colour($hl?$self->{highlightColour}:$self->{normalColour}).$str.$space.colour("reset");;
}

1;
