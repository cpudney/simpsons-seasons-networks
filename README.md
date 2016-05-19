# The Simpsons Seasons Networks

These graphs visualize the co-appearance networks of each season of The Simpsons. Each vertex represents a character, edges connect the vertices of pairs of characters who appear together in an episode. Each edge carries a weight whose value is the number of episodes in the season in which the connected characters co-appear. The size of a vertex encodes the number of episodes in which a character appears in a given season. This value is also encoded in the vertex's colour.

The graphs have some common features. The largest nodes at the centre of each graph are the core Simpsons family unit: Homer, Marge, Bart, Lisa and Maggie. Occasionally, Maggie is absent from a few episodes and in these seasons her vertex is slightly smaller than those of the rest of the family.

Surrounding the central family vertices are secondary characters who make frequent appearances although not in every episode. These include Abe Simpson (Grandpa), bartender Moe Szyslak, Homer's colleagues Carl Carlson and Lenny Leonard, Bart's school chum Milhouse Van Houten, and many more.

Further from the centre we find characters who make fewer appearances, and on the periphery are clusters of vertices representing characters who appear together in single episodes.

The graphs become larger and more complex with the progression of the seasons. Season 1's graph has 240 character vertices. This rises to 600 characters in season 26.

## The Data

I obtained the data from [Wikisimpsons](https://simpsonswiki.com). I wrote a PERL script to fetch and parse the characters appearing in each season's episodes. As is often the case sourcing and cleansing the data took considerable effort. Fortunately, Wikisimpsons is a wiki so I could correct some errors at source. Others require hacks and workarounds in the script. Even after this there are still some issues with the data that require attention.

This work assumes Wikisimpsons is 100% complete, consistent and correct. It isn't, so if you spot any problems then please contribute to this excellent wiki by fixing what you can.

## The Graphs

My PERL script generates two files for each season: nodes.csv (vertices) and edges.csv (edges). I import these into Gephi and then layout the resulting graph. I used Gephi's force-directed algorithm [ForceAtlas2](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0098679). It attempts to layout the vertices such that those connected by edges are close together (the larger the edge weight, the shorter the edge) and those not connected by edges are kept separate.

ForceAtlas2 also has a parameter that tweaks the layout so that vertex overlap is avoided. I enabled this parameter once the layout had stabilized.

Gephi also supports manual layout. So once ForceAtlas2 had settled down I made some manual adjustments to bring outlying clusters closer to the main graph so as to produce a more compact layout.

The final graphs were exported from Gephi as SVG, converted to PNG images using Inkscape and labelled using ImageMagick.

## Tools

+ [Gephi](http://gephi.org) for graph layout
+ [PERL](http://www.perl.org) for data scraping
+ [Inkscape](http://inkscape.org) for SVG to PNG conversion
+ [ImageMagick](http://www.imagemagick.com) for image labeling
