#!/usr/bin/perl
use Test::More tests => 2;

BEGIN {
  use_ok( 'Algorithm::Line::Bresenham', qw(line circle quad_bezier ellipse_rect polyline) );
  use_ok( 'Term::Graille', qw(line circle quad_bezier ellipse_rect polyline) );}
