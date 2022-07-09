# Term-Graille
Braille Characters for Terminal Graphical Applications

![termgraille](https://user-images.githubusercontent.com/34284663/177032294-55dfda02-c24d-45c8-92ab-8c07ad39df66.gif)


Drawille is a method of using Braille characters as a mechanism for graphical display in a terminal.  Ports of the original by [asciimoo](https://github.com/asciimoo/drawille) exist inmultiple other languages including [Perl](https://metacpan.org/dist/Term-Drawille), [Java](https://github.com/null93/drawille), [Rust](https://crates.io/crates/drawille), [NodeJS](https://www.npmjs.com/package/drawille), and others.  The [Perl version](https://github.com/hoelzro/term-drawille) was initially produced by [@hoelzro](https://hoelz.ro/), but not much changed since about 8 years ago.

This is another Perl version, targeting ANSI compatible consoles. It delivers significantly higher performance and extends Term::Drawille by including features like:- 

* Integrated Turtle-like drawing
* Built-in drawing primitives including line and curve, circle, ellipse, polyline more on the way
* Scrolling with or without wrapping
* Some frame border manipulation
* Text overlays

Tools in other languages have been used in publications, system monitoring tools and for games. Term::Graille allows Perl programmers access to a expanding set of features for developing simple general purpose graphics, graphing applications, games etc from the console.

Assocoiated with Term::Graille is Algorithm::Line::Bresenham. The plotting primitives in the latter are used in Graille

Features to be included are colors, sprites, maps, and more on user request.

Version 0.06

## Animation Demo

This is an animation derived from a sprite sheet at [Adobe stock photos](https://stock.adobe.com/uk/images/cheetah-run-cycle-animation-sprite-sheet-silhouette-animation-frames-running-chasing/183196184) which do a 30 day free trial.

![animate](https://user-images.githubusercontent.com/34284663/177872104-57463dc3-f7f7-47a8-a9ef-3c85b4dd923f.gif)


