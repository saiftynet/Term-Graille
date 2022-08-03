# Term-Graille
Braille Characters for Terminal Graphical Applications

![termgraille](https://user-images.githubusercontent.com/34284663/180637940-01b583a0-1a71-4a5d-a29b-394a940ce46f.gif)


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

## Importing images

Graille does not have the resolution for fancy graphics.  Having said that, images converted into mono with appropriate dithering can be surpisingly recognisable at the low resolution oferred.  The `image2grl.pl` script in the examples folder uses Image Magick to perform the transromation down to a Graille canvas's resolutions, and plotted on to the canvas pixel by pixel.  Graille offers the option to import or export `.grl` files.

![grailleimage](https://user-images.githubusercontent.com/34284663/179080305-c24ab071-505b-485b-bff5-cb44ed76c27c.png)

## Animation Demo

The animation demo uses Image::Magick to convert a folder of frames into monochrome images, which are then converted to bitmap plots on a canvas. These bitmap plots are displayed sequentially creating an animation. 

This is an animation derived from a sprite sheet at [Adobe stock photos](https://stock.adobe.com/uk/images/cheetah-run-cycle-animation-sprite-sheet-silhouette-animation-frames-running-chasing/183196184) which do a 30 day free trial.

![animate](https://user-images.githubusercontent.com/34284663/177872104-57463dc3-f7f7-47a8-a9ef-3c85b4dd923f.gif)

## Fonts

In the initial demo above a Turtle script was used to produce a drawing of text.  This is rather combersome.  Fortunately bitmap fonts exist, and can be easily converted to Braille.  [DamienG](https://damieng.com/typography/zx-origins/) has produced a series of 8X8 fonts which can translated into 4X2 braille characters.  The fonts are consistently coded, so `font2grf.pl` in the example folders converts the Z80 assembly data into `.grf` files for importing into Graille.  Fonts are not the only thing that can be transformed, and one imagines potential for sprites or tilemaps to be similarly encoded.

![fonts](https://user-images.githubusercontent.com/34284663/179078012-69f9f535-8d41-46b0-ba68-0a5dbe613cd9.gif)

## Variable thickness Lines


[Herbert Breuning](https://metacpan.org/author/LICHTKIND) had made this suggestion.  There are many examples of thick line algorithms on the net.  [Alan Murphy](http://homepages.enterprise.net/murphy/thickline/index.html) gives the classic version, which has been [improved](http://kt8216.unixcab.org/murphy/index.html) and it is this code that has been ported to Perl and used in Algorth::Line::Bresenham v0.151.  INtegrating these into Graille was in v0.08.

![Screenshot from 2022-08-02 18-32-01](https://user-images.githubusercontent.com/34284663/182438208-793f8c7a-6861-4f2c-b414-86c66ceb92b9.png)


