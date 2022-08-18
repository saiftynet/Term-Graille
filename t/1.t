#!/usr/bin/perl
use strict;use warnings;
use Test::More tests => 5;
BEGIN {
  use_ok( 'Algorithm::Line::Bresenham 0.15');
  use_ok( 'Term::Graille', qw/colour paint printAt clearScreen border  block2braille pixelAt/);
  use_ok( 'Term::Graille::Font', qw/convertDG saveGrf loadGrf fontWrite/);
  use_ok( 'Term::Graille::IO');
  use_ok( 'Term::Graille::Menu');
}
