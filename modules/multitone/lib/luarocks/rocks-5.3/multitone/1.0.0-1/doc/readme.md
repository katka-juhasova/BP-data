[Multitone](https://github.com/darkwiiplayer/multitone)
=========

Improved version of my duotone script. It generates an SVG element with a svg-filter that can be applied to any other HTML element. When called with two colours, it generates a duotone effect. More colours can be used as well.

- Ported to [moonxml](https//github.com/darkwiiplayer/moonxml)
- Extended to support more than two colors (thus renamed duotone -> multitone)
- Parsing of colors removed *because useless*™

Here's a showcase of the effect: [codepen.io/darkwiiplayer/details/vaEKNQ](https://codepen.io/darkwiiplayer/details/vaEKNQ/)

Usage
-----

	require'multitone'.generate(print, {20, 10, 10}, {200, 100, 100}, {80, 100, 200})

`generate` accepts a list of colours (sequences of 3 or more values) and an
options table. Color values must range from 0 to 255 and an alpha value may be
supplied as the fourth element.

Valid options are:

id: the id of the filter element [multitone]

class: the class of the svg element [multitone]

alpha: controls whether alpha channel treated like a color [false]

Exposes a single function that takes an output function followed by an arbitrary number of RGB colors represented by 3-tuples (Sequences of length 3). Colour values are interpreted in 0...255 and are clamped to that range.
Any table of size 0 is treated as an options table. So far the only recognized option is 'id', for the ID of the filter.

License: [The Unlicense](license.md)
