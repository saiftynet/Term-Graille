#! /usr/bin/env perl
use strict; use warnings;
use lib "../lib/";
 use Term::Graille  qw/colour paint printAt clearScreen border/;
 use Time::HiRes "sleep";
 
  my $canvas = Term::Graille->new(
    width  => 100,
    height => 64,
    top=>3,
    left=>10,
    title=>"Interactive Turtle Demo",
    borderStyle => "double",
  );
my $q="";my @commands;
while ($q ne "quit"){
drawTurtle();
$canvas->draw();
$q=prompt();
push @commands,  $q;
clearScreen(); 
$canvas->clear(); 
$canvas->logo("ce;dir 0;");
$canvas->logo($_) foreach (@commands);

printAt (5,70,[@commands[$start..$end]])
}


sub drawTurtle{
	$canvas->logo("bk 2;lt 90;pu;fd 3;pd; pc white;rt 120;fd 6;rt 120;fd 6;rt 120;pu;fd 3;rt 90;pd");
}


sub prompt{
	printAt(20,0,"");
	print">>";
	$_=<STDIN>;
	chomp;
	return $_;
}
