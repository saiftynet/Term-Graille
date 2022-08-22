=head1 NAME

Term::Graille::IO

Allows user interaction in Graille Applications (or perhaps on any
pterminal application).  Depends on Term::ReadKey and Time::HiRes;
When integrated with Term::Graille::Menu allows a modal drop down menu
that can be navigated using key presses.

=head1 SYNOPSIS

     my $io=Term::Graille::IO->new();
     $io->addAction(                             # add action for key press
                    "Am",                        # Am is returned for up arrow
                   {note=>"up arrow:cursor up ", # For drawing a menu
                    proc=>sub{my $self.@args)=@_ ...}  # the action
                    } ); 
     $io->run($io,@args);                        # start trapping keypresses
     ...
     $io->stop();                                # stop
                    
=cut

package Term::Graille::IO;

our $VERSION=0.10;

use strict; use warnings;
use Time::HiRes ("sleep");      # allow fractional sleeps 
use utf8;                       # allow utf characters in print
binmode STDOUT, ":utf8";
use Term::ReadKey;              # allow reading from keyboard
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border/;

=head1 FUNCTIONS

=cut

=head3 C<my $io=Term::Graille::IO-E<gt>new(%params)>

Creates a new IO object for user interaction.
Three modes are available; C<free>, means the key presses are captured
and not echoed, C<menu> requires the setting of C<$io-E<gt>{menu}>,
using    C<$io-E<gt>addMenu($menu)>, and C<normal> when the key presses are
read normally

=cut

sub new{
    my $class = shift;     #  
    my $self={};
    $self->{actions}={};
    $self->{refreshRate}=20;
    $self->{key}="";
    $self->{mode}="free";# one of qw/free menu normal/
    ($self->{terminalWidth},$self->{terminalHeight},$self->{terminalXPixels},$self->{terminalYPixels})=GetTerminalSize;
    bless $self,$class;
    return $self;
}

=head3 C<my $io-E<gt>addMenu($menu,$trigger)>

Uses a topbar dropdown menu of class Term::Graille::Menu. If C<$trigger> is specified
that activates or deactivates the menu; if not specified the 'm' key activates the menu.
 
=cut

sub addMenu{
	my ($self,$menu,$trigger)=@_;
	$self->{menuTrigger}=$trigger//"m";
	$self->{menu}=$menu;
}


=head3 C<my $io-E<gt>addAction($menu,$key,$actionData)>

Determines what happens when a key is pressed in C<free> mode. Functions in the
users scripts have to be "fully qualified" e.g. C<&main::function()>

    $io->addAction("s",{note=>"s key saves sprite",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_; # these are the objects passed as parameters
	   &main::saveSprite($sprite);  
	   &main::flashCursor($sprite,$cursor);
	   &main::restoreIO();},}  );	
 

=cut

sub addAction{
  my ($self,$key, $actionData)=@_;
  my %args=%$actionData;
  foreach my $k (keys %args){
    $self->{actions}->{$key}->{$k}=$args{$k};
  }
}

=head3 C<my $io-E<gt>run($io,@objects)>

Iniiating the capture of the key presses may trigger actions.  These
actions may need parameters including the $io object itself, it is useful 
to select all possible objects that may need to be passed to the anonymous 
subroutines added by C<addAction> above.

=cut

sub run{
  my ($self,@objects)=@_;
  ReadMode 'cbreak';
  my $n=0; my @modifiers=();
  while(1){
	  sleep 1/$self->{refreshRate};
	  $self->{key} = ReadKey(-1);                # -1 means non-blocking read
	  if ($self->{key}){
		my $OrdKey = ord($self->{key});
		if ($OrdKey ==27){push @modifiers, $OrdKey;}
		else{
			my $pressed=chr($OrdKey).(@modifiers?"m":"");
			$pressed="enter" if ($OrdKey==10);
			printAt (20,60,"key pressed=$OrdKey $pressed   ");
			if ($self->{mode} eq "free"){
				if (defined $self->{actions}->{$pressed}->{proc}){
					$self->{actions}->{$pressed}->{proc}->(@objects)
				}
				elsif((exists $self->{menuTrigger})&&($pressed  eq $self->{menuTrigger})){	 
					$self->startMenu();
				 }
			 }
			elsif ($self->{mode} eq "menu"){
				if ($pressed  eq"Am"){ #up arrow
					$self->{menu}->upArrow()
				}
				elsif ($pressed  eq"Bm"){ #down arrow
					$self->{menu}->downArrow()
				}
				elsif ($pressed  eq"Cm"){ #left arrow
					$self->{menu}->leftArrow()
				}
				elsif ($pressed  eq"Dm"){ #right arrow
					$self->{menu}->rightArrow()
				}				
				elsif ($pressed  eq"enter"){ #enter key
					$self->{menu}->openItem()
				}				
				elsif ($pressed  eq $self->{menuTrigger}){ #right arrow
					$self->{menu}->closeMenu()
				}							
			}				 
		}   
	  }
	  else {
		  @modifiers=();
	  }
	  $self->{actions}->{update}->(@objects) if exists $self->{actions}->{update};
	  $n++;
  }  
  ReadMode 'normal';  
}  


=head3 C<my $io-E<gt>startMenu()>

Starts a menu as described in Term::Graille::Menu.  The $io object enters a "menu" mode
when Arrow, Enter and the Trigger key (see above) are passed to the Menu object
 
=cut

sub startMenu{
	my $self=shift;
	if (exists $self->{menu}){
		$self->{mode}="menu";
		$self->{menu}->drawMenu();
	}
}

=head3 C<my $io-E<gt>stopMenu()>

Stops menu and returns to C<free> mode
 
=cut

sub stopMenu{
	my $self=shift;
	$self->{mode}="free";
}

=head3 C<my $io-E<gt>stop()>

stops capturing key presses and enters normal mode. Useful for exeample, when the 
user needs to enter data
 
=cut


sub stop{
	my $self=shift;
	ReadMode 'normal';
}
