#! /usr/bin/env perl

use strict; use warnings;
use utf8;
use lib "../lib";
use open ":std", ":encoding(UTF-8)";
use Term::Graille  qw/colour paint printAt cursorAt clearScreen border blockBlit block2braille pixelAt/;
use Term::Graille::Interact ;
use Term::Graille::Menu;
use Term::Graille::Textarea;
use Term::Graille::Selector;
use Term::Graille::Dialog ;
use Time::HiRes qw/sleep/;
use Data::Dumper;

my $io=Term::Graille::Interact->new();
$io->{debugCursor}=[22,45];

my @colours=qw/red blue green yellow cyan magenta white/;

# setup keyboard short cuts

my $menu=new Term::Graille::Menu(  # no object offered so id will be o0 
          menu=>[["File","New","Load","Insert","Save","Quit"],
                 ["Edit",["Select","All","Start","End"],["Selection","Copy","Cut","Paste"],"Search","Replace"],
                 ["Run","Logo","Perl","Python"],
                 ["test","Death","Message","Input","Selector"],
                 "About"],
          redraw=>\&refreshScreen,
          dispatcher=>\&menuActions,
          );

# in this case the dispatcher directs to subroutines based on name of  
my %actions = ( New  => sub{new()},
                Load => sub{ load()},
                Save => sub{ save() },
                Insert => sub{ load(undef,undef,1) },
                Editor=>sub{mode("Editor")},
                Viewer=>sub{mode("Viewer")},
                Message=>sub{message("Test Message")},
                "Logo"=>sub{logo()},
              );
              
sub menuActions{ # dispatcher for menu
	my ($action,$gV)=@_;
	if (exists $actions{$action}){
		$actions{$action}->($gV)
	}
	else{
		printAt(2,60,$action)
	}
};

my $currentFile="";

my $textarea=new Term::Graille::Textarea();   # no objectId offered so id will be o0

my $canvas=	Term::Graille->new(
		width  => 80,
		height => 50,
		top=>4,
		left=>8,
		borderStyle => "double",
		title=>"Running $currentFile",
	  );
          
$io->addObject(object => $menu,trigger=>"m");
$io->addObject(object => $textarea,trigger=>"e");
$io->start("o1");
$io->run("o1");
refreshScreen();

sub refreshScreen{
	clearScreen() unless (shift);
	$textarea->draw();
}

sub new{
	$textarea->{text}=[""];
	$textarea->{title}="Untitled";
	$textarea->{cursor}=[0,0];
	refreshScreen(1);
	$io->start("o1");
	
}

sub load{
	my ($dir,$filters,$insert)=@_;
	$dir//=".";
	$filters//="\.txt|\.pl|\.logo\$";
	opendir(my $DIR, $dir) || die "Can't open directory $dir: $!";
	my @files = sort(grep {(/$filters/i) && -f "$dir/$_" } readdir($DIR));
	closedir $DIR;
	my $selector=new Term::Graille::Selector(
          redraw=>\&refreshScreen,
          callback=>\&confirmLoad,
          options=>[@files],
          transient=>1,
          title=>"Load File",
          );
    my $selId=$io->addObject(object => $selector);
    $io->start($selId);
	
}		

sub confirmLoad{  # if about to overwrite warn
	my ($param)=@_;
	my $file=$param->{selected};
	my $dialog=new Term::Graille::Dialog(
          redraw=>\&refreshScreen,
          callback=>\&loadFile,
          message=>"Are you sure you want to load this file? You will lose current work",
          param=>{file=>$file,action=>"load"},
          icon=>"info",
          title=>"Confirm Load",
          buttons=>[qw/Load Cancel/],
   );
    my $dialogId=$io->addObject(object => $dialog);
    $io->start($dialogId);
	
}



sub loadFile{
	my $param=shift;
	if ($param->{button} && $param->{button} eq "Cancel"){
		$io->close();
		$io->start("o1");
		return;
		};
	my $file=$param->{file};
	open(my $fh, "<", "$file") or die("Can't open file $file:$! ");
	chomp(my @lines = <$fh>);
	close($fh);
	$textarea->{text}=[@lines];
	$io->close();
	$textarea->{title}=$file;
	$textarea->{cursor}=[0,0];
	$currentFile=$file;
	$io->start("o1");
}

sub save{
	my ($dir,$filters)=@_;
	$dir//=".";
	$filters//="\.txt|\.pl|\.logo\$";
	opendir(my $DIR, $dir) || die "Can't open directory $dir: $!";
	my @files = sort(grep {(/$filters/i) && -f "$dir/$_" } readdir($DIR));
	closedir $DIR;
	my $selector=new Term::Graille::Selector(
          redraw=>\&refreshScreen,
          #callback=>\&saveFile,
          callback=>\&confirmSave,
          options=>[@files],
          transient=>1,
          selected =>$currentFile,
          title=>"Save File",
          );
    my $selId=$io->addObject(object => $selector);
    $io->start($selId);
	
}		

sub confirmSave{  # if about to overwrite warn
	my ($param)=@_;
	my $file=$param->{selected};
	if (-e $file){
		my $dialog=new Term::Graille::Dialog(
			  redraw=>\&refreshScreen,
			  callback=>\&saveFile,
			  message=>"Are you sure you want to save this file? it will overwrite $file",
			  param=>{file=>$file,action=>"save"},
			  icon=>"info",
			  title=>"Confirm Save",
			  buttons=>[qw/Overwrite Cancel/]
	   );
		my $dialogId=$io->addObject(object => $dialog);
		$io->start($dialogId);
	}
	else{
		saveFile({file=>$file});
	}
	
}

sub saveFile{
	my ($param)=@_;
	$io->close();
	if ($param->{button} && $param->{button} eq "Cancel"){
		$io->start("o1");
		return;
		};
	my $file=$param->{file};
	open(my $fh, ">", "$file") or die("Can't open file $file:$! ");
	print $fh join("\n",@{$textarea->{text}});
	close($fh);
	$textarea->{title}=$file;
	$currentFile=$file;
	$io->start("o1");
}

sub message{
	my ($message,$input)=@_;
	my $dialog=new Term::Graille::Dialog(
          redraw=>\&refreshScreen,
          callback=>\&messageReturn,
          message=>$message,
          icon=>"info",
          title=>"Test Message",
          );
    $dialog->mode("ync");
    my $dialogId=$io->addObject(object => $dialog);
    $io->start($dialogId);
}

sub messageReturn{
	my ($ret,$params)=@_;
	$ret||="nothing" ;
	$params="" unless (defined $params);
	$io->close();
	if ($ret){ printAt(2,50,"$ret $params returned") }
	
}

sub logo{
	$canvas->logo(join (";",@{$textarea->{text}}));
	$canvas->{title}="Running $currentFile";
	$canvas-> draw();
}

