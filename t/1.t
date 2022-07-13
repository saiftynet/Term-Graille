#!/usr/bin/perl
use Test::More tests => 2;

BEGIN {
  use_ok( 'Algorithm::Line::Bresenham');
  use_ok( 'Term::Graille', qw/colour paint printAt clearScreen border  block2braille pixelAt loadGrf/);
}
