#!/usr/bin/perl -w

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use Text::Table;
use LWP::Simple;

sub parseCharacters($)
{
    my $doc = shift;
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($doc);
 
    my $toc_table = Text::Table->new('Entry', 'Link');
    my @toc = $tree->findnodes('//ul[1][@class="gallery mw-gallery-traditional"]/li[@class="gallerybox"]//p/a');
    my @characters = ();
    for my $el ( @toc ) {
	my $character = $el->as_trimmed_text;
	push @characters, $character;
	$toc_table->add(
	    $character,
	    $el->attr('href'),
	    );
	print $character . "\t";
    }
    print "\n";
 
    return @characters;    
}

sub parseEpisodes($)
{
    my $doc = shift;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($doc);
 
    my $toc_table = Text::Table->new('Entry', 'Link');
    my @toc = $tree->findnodes('//table//p//a');
    my @episodes = ();
    for my $el ( @toc ) {
	my $ref = $el->attr('href');
	push @episodes, $ref;
	$toc_table->add(
	    $el->as_trimmed_text,
	    $ref);
    }
 
    return @episodes;
}

# Command-line.
my $num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "\nUsage: parseSimpsonsWiki.pl season_number\n";
    exit;
}

my $url = 'http://simpsonswiki.com/wiki/Season_' . $ARGV[0];
my @episodes = parseEpisodes(get($url));
print @episodes;
die "Supicious episode count: " . scalar @episodes if (@episodes > 30 || @episodes < 10);


my %nodes = ();
my %edges = ();
my $index = 1;

# Loop through episodes.
for my $url ( @episodes ) {

    print $url . "\n";

    # Get character appearances.
    my @characters = parseCharacters(get('http://simpsonswiki.com' . $url . '/Appearances'));
    print "Warning: too few characters: " . scalar @characters . "\n" if (@characters < 10);

    my @indices = ();

    # Loop through characters.
    for my $c ( @characters ) {

	# New character node?
	if (exists $nodes{$c}) {

	    # Existing: increment count.
	    my $node = $nodes{$c};
	    $node->{'count'}++;	    
	}
	else {

	    # New: create hash.
	    $nodes{$c} = { 'label' => $c, 'index' => $index++, 'count' => 1 };
	}

	# Get node index.
	my $ix = $nodes{$c}->{'index'};

	# Loop through previous indices.
	for my $i ( @indices ) {

	    # Assign edge source and target.
	    my ($source, $target);
	    if ($i < $ix) {
		($source, $target) = ($i, $ix);
	    }
	    else {
		($source, $target) = ($ix, $i);
	    }

	    # Existing edge?
	    my $key = "$source -> $target";
	    if (exists $edges{$key}) {

		# Existing: increment count;
		my $edge = $edges{$key};
		$edge->{'weight'}++;
	    }
	    else {

		# New: create hash.
		$edges{$key} = { 'source' => $source, 'target' => $target, 'weight' => 1 };
	    }
	}

	push @indices, $ix;	# Add index to indices.
    }
}

# List nodes.
open(my $nfh, '>', 'nodes.csv');
print $nfh "Label\tSize\n";
for my $k (sort { $nodes{$a}->{'index'} <=> $nodes{$b}->{'index'} } keys %nodes ) {
    
    my $node = $nodes{$k};
    print $nfh $node->{'label'} . "\t" . $node->{'count'} . "\n";
}
close $nfh;

# List edges.
open(my $efh, '>', 'edges.csv');
print $efh "Source\tTarget\tWeight\tType\n";
for my $k (keys %edges ) {

    my $edge = $edges{$k};
    print $efh $edge->{'source'} . "\t" . $edge->{'target'} . "\t" . $edge->{'weight'} . "\tUndirected\n";
}
close $efh;

1;
