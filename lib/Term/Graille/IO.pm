=head1 NAME

Term::Graille::IO

Allows user interaction in Graille Applications (or perhaps on any
pterminal application).  Depends on Term::ReadKey and Time::HiRes;
When integrated with Term::Graille::Menu allows a modal drop down menu
that 

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

our $VERSION=0.09;

use strict; use warnings;
use Time::HiRes ("sleep");      # allow fractional sleeps 
use utf8;                       # allow utf characters in print
binmode STDOUT, ":utf8";
use Term::ReadKey;              # allow reading from keyboard
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border/;

sub new{
    my $class = shift;     #  
    my $self={};
    $self->{actions}={};
    $self->{refreshRate}=20;
    $self->{key}="";
    $self->{mode}="free";# one of qw/free menu entry/
    ($self->{terminalWidth},$self->{terminalHeight},$self->{terminalXPixels},$self->{terminalYPixels})=GetTerminalSize;
    bless $self,$class;
    return $self;
}

sub addMenu{
	my ($self,$menu)=@_;
	$self->{menu}=$menu;
}

sub addAction{
  my ($self,$key, $actionData)=@_;
  my %args=%$actionData;
  foreach my $k (keys %args){
    $self->{actions}->{$key}->{$k}=$args{$k};
  }
}

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
				$self->{actions}->{$pressed}->{proc}->(@objects)   
					 if defined $self->{actions}->{$pressed}->{proc};
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
				elsif ($pressed  eq"enter"){ #right arrow
					$self->{menu}->openItem()
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

sub startMenu{
	my $self=shift;
	if (exists $self->{menu}){
		$self->{mode}="menu";
		$self->{menu}->drawMenu();
	}
}

sub stopMenu{
	my $self=shift;
	$self->{mode}="free";
}

sub stop{
	my $self=shift;
	ReadMode 'normal';
}
