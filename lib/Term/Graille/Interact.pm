=head1 NAME

Term::Graille::Interact

Allows user interaction in Graille Applications (or perhaps on any
pterminal application).  Depends on Term::ReadKey and Time::HiRes;
When integrated with Term::Graille::Menu allows a modal drop down menu
that can be navigated using key presses.

=head1 SYNOPSIS

     my $io=Term::Graille::Interact->new();
     $io->addAction(                             # add action for key press
                    "Am",                        # Am is returned for up arrow
                   {note=>"up arrow:cursor up ", # For drawing a menu
                    proc=>sub{my $self,@args)=@_ ...}  # the action
                    } ); 	
                   
     $io->run($io,@args);                        # start trapping keypresses
     ...
     $io->stop();                                # stop
                    
=cut

package Term::Graille::Interact;

our $VERSION=0.10;

use strict; use warnings;
use lib "../lib";
use Time::HiRes ("sleep");      # allow fractional sleeps 
use utf8;                       # allow utf characters in print
binmode STDOUT, ":utf8";
use Term::ReadKey;              # allow reading from keyboard
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border/;



  my $namedKeys={
	  10 =>"enter",
	  9  =>"tab",
	  "[Z"  =>"shifttab",
	  "[2~"=>"insert",
	  "[3~"=>"delete",
	  "[H"=>"home",
	  "[F"=>"end",
	  "[5~"=>"pgup",
	  "[6~"=>"pgdn",
	  127=>"backspace",
  };

=head1 FUNCTIONS

=cut

=head3 C<my $io=Term::Graille::Interact-E<gt>new(%params)>

Creates a new IO object for user interaction.
C<"Main">, is default interaction profile, each active widget
declkares its own interaction profile (responses to key presses)

=cut

sub new{
    my $class = shift;     #  
    my $self={};
    $self->{refreshRate}=20;
    $self->{key}="";
    $self->{objects}={}; # hash containing objects that need userIO
    $self->{activeObject}=""; # active object
    ($self->{terminalWidth},$self->{terminalHeight},$self->{terminalXPixels},$self->{terminalYPixels})=GetTerminalSize;
    $self->{cursor}=[0,0];
    $self->{debug}=1;
    $self->{debugCursor}=[20,45];
    $self->{keyBuffer}="";
    $self->{gV}={}; #contains global variables that are accessible from one object to next
    bless $self,$class;
    return $self;
}

=head3 C<my $io-E<gt>addObject($menu,%params)>

Adds a user interaction object.  params are:-

objectId:Id of the object if not set this is automatically generated

object:  the reference to object REQUIRED 

actions:  The key-press actions for this object when it is active

trigger: 

 
=cut

sub addObject{
	my ($self,%params)=@_;
	my ($objectId,$object,$actions,$trigger)=@params{qw/objectId object actions trigger/};
	$objectId//=$self->newId();
	$self->{objects}->{$objectId}=$object;
	$self->{objects}->{$objectId}->{objectId}//=$objectId;
	$self->{objects}->{$objectId}->{actions}=$actions//{};
	$self->{triggers}->{$trigger}=$objectId if $trigger;
	return $objectId;
}

=head3 C<$io-E<gt>addAction($objectId,$key,$actionData)>

Determines what happens when a key is pressed for a specific object. Functions in the
users scripts have to be "fully qualified" e.g. C<&main::function()>

    $io->addAction("menu","s",{note=>"s key saves sprite",proc=>sub{
	   my ($self,$canvas,$sprite,$cursor)=@_; # these are the objects passed as parameters
	   &main::saveSprite($sprite);  
	   &main::flashCursor($sprite,$cursor);
	   &main::restoreIO();},}  );	
 

=cut

sub addAction{
  my ($self,$objectId,$key,$actionData)=@_;
  my %args=%$actionData;
  if ($objectId  && $self->{objects}->{$objectId}){
	  foreach my $k (keys %args){
		$self->{objects}->{$objectId}->{actions}->{$key}->{$k}=$args{$k};
	  }
  }
  else{
	  foreach my $k (keys %args){
		$self->{actions}->{$key}->{$k}=$args{$k};
	  }
  }
  
}


=head3 C<my $io-E<gt>updateAction($menu,$action)>

Adds a routine that is executed every interaction cycle
e.g for animations

=cut

sub updateAction{
  my ($self,$action)=@_;
  $self->{actions}->{update}=$action;	
}

sub stopUpdates{
  my ($self,)=@_;
  delete $self->{actions}->{update};
	
}

sub newId{
	my $self=shift;
	my $index=0;
	$index++ while (exists $self->{objects}->{"o$index"});
	return "o$index";
}

=head3 C<$io-E<gt>addActionSet(<ObjectID>,$actionSet)>

allows multiple $key actions to be set/changed as a set. 
For example tyhe arrow keys may have one purpose navigating a menu and 
another set of actions in the game.  Toggling between the game and menu
would need the keys to be mapped to different actions, and this alows
the actions to be swapped byu bundling the actions into sets.

   my $actionSet=[["s",{note=>"s key saves sprite",proc=>sub{
					   my ($self,$canvas,$sprite,$cursor)=@_;
					   &main::saveSprite($sprite);  
					   &main::flashCursor($sprite,$cursor);
					   &main::restoreIO();},} ],
				#  [$key2, $actionData2], etc
				 ]

=cut


sub addActionSet{
  my ($self,$objectId,$actionSet)=@_;
  foreach my $actionPair (@$actionSet){ # pair of keymap and action;
	 $self->addAction($objectId,@$actionPair)
  }
}

=head3 C<$io-E<gt>run()>

Initiating the capture of the key presses that may trigger actions.

=cut

sub run{
  my ($self,$objectId)=@_;
  $self->{activeObject}=$objectId//"";
  ReadMode 'cbreak';
  
  while($self->{activeObject} ne "stop"){   # setting $io->{activeObject} to "stop" exits loop
	  sleep 1/$self->{refreshRate};
	  $self->{key} = ReadKey(-1);                # -1 means non-blocking read
	  my $pressed="";
	  if (defined $self->{key}){
		my $esc="";  
		my $OrdKey = ord($self->{key});
		if ($OrdKey ==27){$esc=get_escape_sequence()//"esc"};
		if (exists $namedKeys->{$OrdKey}){$pressed=$namedKeys->{$OrdKey}}
		elsif (exists $namedKeys->{$esc}){$pressed=$namedKeys->{$esc}}
		else{$pressed= ($esc ne "")?$esc:chr($OrdKey);};
			
		if ($self->{activeObject} ne ""){   # mode is widget;
		$self->debugMessage("key pressed=$OrdKey $pressed ".$self->{activeObject}."       ");
			if (defined $self->{objects}->{$self->{activeObject}}->{keyAction}->{$pressed}){ #  pre defined key actions
				$self->{objects}->{$self->{activeObject}}->{keyAction}->{$pressed}->($self->{activeObject},$self->{gV});
			}
			elsif($self->{objects}->{$self->{activeObject}}->{keyAction}->{others}){ #  if an action for undefined keys exists 
				$self->{objects}->{$self->{activeObject}}->{keyAction}->{others}->($self->{objects}->{$self->{activeObject}},$pressed,$self->{gV});
			}
			else {   # otherwise collect the keys pressed in a buffer
				$self->{objects}->{activeObject}->{keyBuffer}.=$pressed
			}
		}	
		else {  # if mode is main
			my $mode="(MAIN)";
			if (defined $self->{actions}->{$pressed}->{proc}){
				$self->{actions}->{$pressed}->{proc}->($self->{gV})
			}
			elsif(exists $self->{triggers}->{$pressed}){
			    $mode="($self->{triggers}->{$pressed})";
				$self->start($self->{triggers}->{$pressed});
			}
			elsif(exists $self->{actions}->{others}){
				$self->{actions}->{others}->{proc}->($pressed,$self->{gV});
			}
			else {   # otherwise collect the keys pressed in a buffer
				$self->{keyBuffer}.=$pressed;
			}
			
			$self->debugMessage("key pressed=$OrdKey $pressed $mode  ");
		}
	  }
	  
	  $self->{actions}->{update}->() if $self->{actions}->{update};
  }  
  ReadMode 'normal';  
}  

sub debugMessage{
	my ($self,$msg)=@_;
	printAt (@{$self->{debugCursor}},$msg) if ($self->{debug})
}

sub get_escape_sequence {
    my $esc;
    while ( my $key = ReadKey(-1) ) {
        $esc .= $key;
        last if ( $key =~ /[a-z~]/i );
    }
    return $esc;
}


=head3 C<$io-E<gt>start($objectId,$params)>

Starts an object that consumes keypresses. $params is a hash ref that is
passed to the object to allow customusation

 
=cut

sub start{
	my ($self,$objectId,$params)=@_;
	close($self->{activeObject}) if $self->{activeObject};
	$self->{activeObject}=$objectId;
	$self->{objects}->{$objectId}->{params}=$params if defined $params;
	my $closer=sub{$self->close()};
	$self->{objects}->{$objectId}->{close}=$closer;   # closer function to object
	$self->{objects}->{$objectId}->draw();
}


=head3 C<$io-E<gt>close()>

closes currently active actually by calling Term::Graile::Interacts close(),
this has been set during s Term::Graile::Interacts start($objectId)
 
=cut

sub close{
	my ($self)=@_;
	$self->{objects}->{$self->{activeObject}}->close() # if the object has own close function
	    if ( $self->{objects}->{$self->{activeObject}}&& (ref $self->{objects}->{$self->{activeObject}} ne "HASH") && $self->{objects}->{$self->{activeObject}}->can("close"));
	delete $self->{objects}->{$self->{activeObject}} if ($self->{objects}->{$self->{activeObject}}->{transient});
	$self->{activeObject}="";
}

sub stop{
	my $self=shift;
	$self->{mode}="stop";
	ReadMode 'normal';
}
