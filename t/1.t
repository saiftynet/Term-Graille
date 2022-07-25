#!/usr/bin/perl
use Test::More tests => 2;

BEGIN {
  use_ok( 'Algorithm::Line::Bresenham');
  use_ok( 'Term::Graille', qw/colour paint printAt clearScreen border  block2braille pixelAt/);
  use_ok( 'Term::Graille::Font', qw/convertDG saveGrf loadGrf fontWrite/);
}
