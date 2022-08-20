=head1 NAME
Term::Graille::Menu


=head1 SYNOPSIS
 
    my $menu=new Term::Graille::Menu(
          menu=>[["File","New","Save","Load","Quit"],
                 ["Edit","Clear",["Reformat","2x4","4x4"],["Scroll","left","right","up","down"]],
                 "About"],
          redraw=>\&main::refreshScreen,
          callback=>\&main::menuActions,
          );


=head1 DESCRIPTION

Developed to allow user interaction using a hierarchical menu in command line
applications.  The menu is activated using a key press, and navigated 
typically using arrow keys.  It does not handle or capture the key presses
directly, and in Graille is used in conjunctyion with Term::Graille::IO


=begin html

<img src="https://user-images.githubusercontent.com/34284663/185751328-f5b67fa4-c77d-40b0-ac3a-0c6c93239fae.gif">

=end html


=head1 FUNCTIONS

=cut

package  Term::Graille::Menu;

our $VERSION=0.09;

use strict;use warnings;
use Storable qw(dclone);
use Term::Graille qw/colour printAt clearScreen/;
use utf8;


=head3 C<my $menu=Term::Graille::Menu-E<gt>new(%params)>

Creates a new $menu; params are
C<menu> The menu tree as an Array ref containing strings and arrayrefs.
Branches are Array refs, and end nodes are strings. See above example to
visuialise structure.  
C<redraw> This is a function to redraws the application screen.
The menu will overwrite parts of the application screen, and this allows
function needs to be provided to restire the screen.
C<callback> The menu does not call any functions, instead returns the
leaf string selected.  It is upto the main application to use this string to 
in a dispatch routine (the callback function supplied)

=cut


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


=head3 C<$menu-E<gt>setMenu($menu,$reset)>

Changes the menu. if reset is set then the menu "pointer" is set at the first item
in menmu tree.

=cut

sub setMenu{
	my ($self,$menu,$reset)=@_;
	$self->{menu}=$menu;
	$self->{breadCrumbs} if $reset;
}


=head3 C<my $menu-E<gt>redraw()>

Calls the applications redraw function. This is required for the menu
to be overwritten with application screen.

=cut


sub redraw{
	my $self=shift;
	$self->{redraw}->() if (exists $self->{redraw});
	
}



=head3 C<my $menu-E<gt>nextItem()>, C<my $menu-E<gt>prevItem()>, 
C<my $menu-E<gt>closeItem()>, C<my $menu-E<gt>openItem()>

Navigate the menu, select items.

=cut
	
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
		$self->closeMenu();
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

=head3 C<my $menu-E<gt>closeMenu()>

Closes the menu, redraws the screen (using C<$menu->redraw();>) and sends
C<undef> to  C<$menu->{callback}>;

=cut


sub closeMenu{
	my $self=shift;
	$self->redraw() if defined $self->redraw() ;
	$self->{callback}->(undef) if $self->{callback};
}


=head3 C<my $menu-E<gt>upArrow()>, C<my $menu-E<gt>downArrow()>, 
C<my $menu-E<gt>leftArraow()>, C<my $menu-E<gt>rightArrow()>

The menu does not acpture key presses, but provides methods to allow
key presses to trigger navigation.


=cut

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
	my $tmp=dclone($self->{menu});
	if (!$level){
		foreach my $mi (0..$#$tmp){
			my $label=((ref $tmp->[$mi])?$tmp->[$mi]->[0]:$tmp->[$mi]);
			my $active=($ai == $mi?1:0);
			if ($active){$nextPos=[$nextPos->[0]+1,$pos->[1]]}
			printAt(@$pos,$self->highlight($label,$active). " ");
			$pos->[1]+=(2+length $label);
		}
		print "\n";
	}
	else{
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
		printAt(@$pos,"┌".	("─"x$longest)."┐");
		$pos->[0]+=1;
		foreach my $mi (0..$#{$tmp}){ # skip first item which is label for list 
			my $label=((ref $tmp->[$mi])?$tmp->[$mi]->[0]:$tmp->[$mi]);
			my $active=(($ai) == $mi?1:0);
			if ($active){$nextPos=[$pos->[0],$pos->[1]+$longest+2]}
			printAt(@$pos,$self->highlight($label,$active,$longest));
			$pos->[0]+=1;
		}
		printAt(@$pos,"└".	("─"x$longest)."┘");
	}
	return $nextPos;
}

sub depth{
	my $self=shift;
	return scalar @{$self->{breadCrumbs}};
}

sub highlight{
	my ($self,$str,$hl,$padding)=@_;
	my $space=$padding?(" "x($padding-length $str)):" ";
	my $b=$padding?"│":"";
	return $b.colour($hl?$self->{highlightColour}:$self->{normalColour}).$str.$space.colour("reset").$b;;
}

1;
