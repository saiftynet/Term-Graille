=head1 NAME
Term::Graille::Textarea

Text editting area

=head1 SYNOPSIS
 
    use Term::Graille::Interact;
    use Term::Graille::Textarea ;   
    
    my $editor=new Term::Graille::Textarea(
          geometry=>[60,30],  #  [$Width, $Height]
          position=>[2,2],    #  [$row, $column] 
          );


=head1 DESCRIPTION

Allows an area for multiline text to be entered and editted.

=head1 FUNCTIONS

=cut

package  Term::Graille::Textarea;
use lib "../lib";
use strict;use warnings;
use Term::Graille qw/colour printAt clearScreen border/;
use utf8;

=head3 C<my $menu=Term::Graille::Menu-E<gt>new(%params)>

Creates a new Textarea; params are
C<menu> The menu tree as an Array ref containing strings and arrayrefs.
Branches are Array refs, and end nodes are strings. See above example to
visualise structure.  
C<redraw> This is a function that needs to be supplied to redraw the
application screen. The menu will overwrite parts of the application screen,
and this function needs to be provided to restore the screen.
C<callback> The menu does not call any functions, instead returns the
leaf string selected.  It is upto the main application to use this string to 
in a dispatch routine (the callback function supplied)
C<pos> Optional. The default position is [2,2], but setting this parameter allows 
the menu to be placed elsewhere
C<highlightColour> Optional. The selected item is highlighted default "black on_white"
C<normalColour> Optional. The normal colour of menu items "white on_black"


=cut


sub new{
    my ($class,%params) = @_;  
    my $self={};
    bless $self,$class;
    $self->{geometry}=$params{geometry}//[72,14];  # to do fugure out resize
    $self->{position}=$params{position}//[4,6];    # function to redraw application
    $self->{cursor}=[0,0],
	$self->{text}=$params{text}//[""];
	$self->{windowStart}=$params{windowStart}//0;
	$self->{highlighted}=$params{highlighthed}//[[0,0],[0,0]];;
	$self->{keyAction}={
		"[A"       =>sub{$self->upArrow()},
		"[B"       =>sub{$self->downArrow()},
		"[C"       =>sub{$self->rightArrow()},
		"[D"       =>sub{$self->leftArrow()},
		"enter"    =>sub{$self->newline()},
		"esc"      =>sub{$self->exit()},          # this required for all interaction objects
		"delete"   =>sub{$self->deleteChar()},
		"backspace"=>sub{$self->backspace()},
		others =>sub{my ($obj,$pressed,$gV)=@_;$self->addChar($pressed)},
	};
	
	$self->{border}=$params{border}//{style=>"double"};
	$self->{title}=$params{title}//"Untitled";

	
	
	return $self;
}

sub insertText{
	my ($self,@text,$clear)=@_;
	my @newText=();
	foreach (@text){
			push @newText,(ref $_ eq "ARRAY")?@$_ :$_;
	}
	if ($clear){$self->{text}=[@newText]}
	else{
		my @oldText=@{$self->{text}};
		$self->{text}=[@oldText[0..$self->{cursor}->[0]],@newText,@oldText[$self->{cursor}->[0]..$#oldText]];
	}
}

sub cursorMove{
	my ($self,$movement)=@_;
	$self->{cursor}->[0]+=$movement->[0];
	$self->{cursor}->[1]+=$movement->[1];
	$self->{cursor}->[0]=0 if $self->{cursor}->[0] <0;
	$self->{cursor}->[0]=$#{$self->{text}} if ($#{$self->{text}} < $self->{cursor}->[0]);
	$self->{cursor}->[1]=0 if $self->{cursor}->[1] <0;
	$self->{cursor}->[1]=(length $self->{text}->[$self->{cursor}->[0]]) if ((length $self->{text}->[$self->{cursor}->[0]]) < $self->{cursor}->[1]);
	$self->{windowStart} = $self->{cursor}->[0] if ($self->{cursor}->[0] < $self->{windowStart});
	$self->{windowStart} = $self->{cursor}->[0]-$self->{geometry}->[1] if ($self->{cursor}->[0]-$self->{geometry}->[1] > $self->{windowStart});
	$self->draw();
	my $winEnd=$self->{windowStart}+$self->{geometry}->[1];
	if (@{$self->{text}}<$winEnd){$winEnd=@{$self->{text}}} ;
	printAt($self->{position}->[0]+$self->{geometry}->[1]+1,$self->{position}->[1]+$self->{geometry}->[0]-50,
	           " Lines: $self->{windowStart}-$winEnd/".@{$self->{text}}." Curs: $self->{cursor}->[0],$self->{cursor}->[1] ". $self->charAt()." ");
}

sub draw{
	my ($self)=@_;
	
	border($self->{position}->[0]-1,$self->{position}->[1]-1,
	       $self->{position}->[0]+$self->{geometry}->[1],$self->{position}->[1]+$self->{geometry}->[0],
	       $self->{border}->{style}//"double",$self->{border}->{colour}//"white",$self->{title},$self->{titleColour}//"white") if $self->{border};
	for my $l ($self->{windowStart}..$self->{windowStart}+$self->{geometry}->[1]){
	    $self->drawLine($l)
	}
}

sub drawLine{
	my ($self,$line)=@_;
	my ($row,$col)=@{$self->{position}}; # the position of the top left corner of textarea
	my $rowOffset=$row+$line-$self->{windowStart};
	my $lineText=$self->{text}->[$line]//"";
	my $rowScroll=$self->{cursor}->[1]-$self->{geometry}->[0];
	$rowScroll=0 if ($rowScroll<0);
	$lineText=(length $lineText > $rowScroll) ? substr($lineText,$rowScroll,($self->{geometry}->[0]+1)):"";
	printAt($rowOffset,$col," "x($self->{geometry}->[0]+1));
	if ($line!=$self->{cursor}->[0]){
		 printAt($rowOffset,$col,$lineText);
	}
	else {
		# empty line= just blink character
		if (length $lineText<=1){ printAt($rowOffset,$col,colour("blink invert")." ".colour("reset"))}
		# end of line= line+blinkcharacter
		elsif (length $lineText==($self->{cursor}->[1]-$rowScroll)){  printAt($rowOffset,$col,$lineText.colour("blink invert")." ".colour("reset")) }
		else {substr ($lineText, $self->{cursor}->[1]+1-$rowScroll, 0)= colour("reset");substr ($lineText,  $self->{cursor}->[1]-$rowScroll, 0)= colour("blink invert") ;
			 printAt($rowOffset,$col,$lineText);
			};
	}
}

sub upArrow{
	my $self=shift;
	$self->cursorMove([-1,0]);
}

sub leftArrow{
	my $self=shift;
	$self->cursorMove([0,-1]);
}


sub charAt{
	my ($self,$pos)=@_;
	$pos//=$self->{cursor};
	return "" if (length $self->{text}->[$pos->[0]] eq $pos->[1]);
	return substr($self->{text}->[$pos->[0]], $pos->[1], 1);
	
}

sub rightArrow{
	my $self=shift;
	$self->cursorMove([0,1]);
}

sub downArrow{
	my $self=shift;
	$self->cursorMove([1,0]);
}

sub getLine{
	my ($self,$line)=@_;
	$line=$self->{cursor}->[0] unless defined $line;
	return $self->{text}->[$line];
}

sub newline{
	my ($self)=@_;
	my @textBefore=$self->{cursor}->[0]?(@{$self->{text}}[0..$self->{cursor}->[0]-1]):();
	my @textAfter=($self->{cursor}->[0]<(scalar @{$self->{text}}))?@{$self->{text}}[$self->{cursor}->[0]+1..$#{$self->{text}}]:();
	my $textAt=$self->{text}->[$self->{cursor}->[0]];
	my @splitText= (substr($textAt, 0, $self->{cursor}->[1]), substr($textAt, $self->{cursor}->[1]));
	$self->{text}=[@textBefore,@splitText,@textAfter];           
	$self->cursorMove([1,-100]);
}

sub addChar{
	my ($self,$ch)=@_;
	return unless defined $ch && (length $ch==1);
	my $line=$self->{text}->[$self->{cursor}->[0]]//"";
	if ($line){	substr($line, $self->{cursor}->[1], 0)=$ch;}
	else{ $line=$ch};
	$self->{text}->[$self->{cursor}->[0]]=$line;
	$self->cursorMove([0,1]);
	
}

sub deleteChar{
	my ($self)=@_;
	# delete character if not end of line
	if ($self->{cursor}->[1]<((length $self->{text}->[$self->{cursor}->[0]])-1)){
		substr($self->{text}->[$self->{cursor}->[0]], $self->{cursor}->[1],1)="";
	}
	# skip if no more lines at all
	elsif ($self->{cursor}->[0] == @{$self->{text}}-1){
		
	}
	#get the next line  and merge it with current line
	else{
		$self->{text}->[$self->{cursor}->[0]].= $self->{text}->[$self->{cursor}->[0]+1];
        splice(  @{$self->{text}}, $self->{cursor}->[0]+1, 1 );
	}
	$self->cursorMove([0,0]);
}

sub backspace{
	my ($self)=@_;
	if ($self->{cursor}->[1]>0){
		substr( $self->{text}->[$self->{cursor}->[0]], $self->{cursor}->[1]-1,1)="";
	    $self->cursorMove([0,-1]);
	}
	else{
		return unless $self->{cursor}->[0];  # backspace at position[0,0]
		my $disp=length $self->{text}->[$self->{cursor}->[0]-1];
		$self->{text}->[$self->{cursor}->[0]-1].= $self->{text}->[$self->{cursor}->[0]];
        splice(  @{$self->{text}}, $self->{cursor}->[0], 1 );
	    $self->cursorMove([-1,-100]);
	    $self->cursorMove([0,$disp]);
	}
}

sub exit{
	my $self=shift;
	$self->{close}->();
}

sub text{
	my $self=shift;
	return Join("\n",@{$self->{text}});
}

1;
