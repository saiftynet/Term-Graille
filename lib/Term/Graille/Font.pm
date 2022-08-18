package Term::Graille::Font;
use strict; use warnings;
use utf8;
use Data::Dumper;
use Term::Graille  qw/block2braille/;
use base 'Exporter';
our @EXPORT_OK = qw/convertDG saveGrf loadGrf fontWrite/;
use open ":std", ":encoding(UTF-8)";

our $VERSION="0.09";


=head1 NAME

Term::Graille::Font - convert and use ZX Spectrum fonts in Term::Graille
 
=head1 SYNOPSIS

    use Term::Graille::Font  qw/convertDG saveGrf fontWrite/;
	my $grf=convertDG("$fontName.z80.asm");
	$canvas->blockBlit($grf->{A},$gridX,$gridY); # old method single character
	fontWrite($canvas,$grf,$gridX,$gridY,$text); # new method text string
	saveGrf($grf,"$fontName.grf");
	
=head1 DESCRIPTION

This allows the creation, saving and usage of Braille Character to form
Bitmap 8x8 font.  It currently only accepts DameinGuards z80.asm files 
as found in damieng.com/typography/zx-origins/ where there a couple of
hundred fonts available.

=begin html

<img src="https://user-images.githubusercontent.com/34284663/179078012-69f9f535-8d41-46b0-ba68-0a5dbe613cd9.gif">

=end html


=head1 FUNCTIONS

=cut

=head3 C<my $grf=convertDG("$fontName.z80.asm");>

Reads an ASM file as on Damien Guard's typography pages and returns a hashref
containing the extracted 8x8 fonts converted into 4x2 Braille characters.

=cut

sub convertDG{
	my $file=shift;
	my $font="";
	open my $zxFont,"<:utf8",$file or die "Unable to open fontfile $file $!;\n";
	$font.=$_ while(<$zxFont>);
	close $zxFont;
	
	$font=~s/^[\s\t]?;([^\n]+)/{/g;
	my $info=$1;
	$font=~s/defb &/[[0x/g;
	$font=~s/,&/],[0x/g;
	$font=~s/ ; /]],# /g;
	$font=~s/\s([^#\s]*)#\s(.)/  '$2'=>$1/g;
	$font=~s/\'\'\'/\"\'\"/g;
	$font=~s/\'\\\'/\'\\\\\'/g;
	$font.="\n}\n";
	#	print $font;
	my $binFont=eval($font);
	my $grlFont={};
	for (keys %$binFont){
		use utf8;
		$grlFont->{$_}=block2braille($binFont->{$_}) ;
	}
	$grlFont->{info}=$info||"";
	return $grlFont;
}

=head3 C<saveGrf($font,$file);>

Uses Data::Dumper to produce convert a font hashref into a file that can
be read using loadGrf

=cut

sub saveGrf{
   my ($grf,$file)=@_;
   my $output=Dumper([$grf]);
   $output=~ s/\\x\{([0-9a-f]{2,})\}/chr hex $1/ge;
   $output=~s/^\$VAR1 = \[\n\s+|        \];\n?$//g;
   $output=~s/\[\n\s+\[/\[\[/g;
   $output=~s/\n\s+([^\s])/$1/g;
   $output=~s/\]\],/\]\],\n/g;
   die "Conversion failed\n" if (length $output <100);
   open my $dat,">:utf8","$file" or die "Unable to save fontfile $file $!;\n";
   print $dat $output;
   close $dat;
}


=head3 C<my $font=loadGrf($file);>

Loads a font hashref from a file.  The hashRef indexes 4x2 braille character
blocks by character they represent;  This may be used to represent any kind of
character block, including tilemaps, sprites etc.

=cut

#loads a hashfile representing a 2D Array ref blocks of data
#can be used to load fonts or other graphical blocks
sub loadGrf{
	my $file=shift;
	open my $grf,"<:utf8",$file  or 
	      die "Unable to open file $file $!;\n" ;
	my $data="";
	$data.=$_ while(<$grf>);
	close $grf;
	my $g=eval($data) or die "unable to load external data from $file $!";;
	return  $g;
}


=head3 C<$fontWrite($canvas,$font,$gridX,$gridY,$text);>

Writes a C<$text> string using a loaded font into a particular grid
location in a C<$canvas>

=cut

sub fontWrite{
	my ($canvas,$font,$gridX,$gridY,$text)=@_;
	for my $chPos(0..(length $text)-1){
		$canvas->blockBlit($font->{substr($text,$chPos, 1)},$gridX+4*$chPos, $gridY)
	}
}

1;
