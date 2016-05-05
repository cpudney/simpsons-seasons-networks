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
    my %characters;

    $tree->parse($doc); 
    my $toc_table = Text::Table->new('Entry', 'Link');

    # Default.
    my @toc = $tree->findnodes('//h2[*="Characters"]/following-sibling::ul[1]/li//a');

    # Try nested, e.g. Treehouse episodes.
    @toc = $tree->findnodes('//h3[*="Characters"]/following-sibling::ul[1]/li//a') unless @toc;

    for my $el ( @toc ) {
	my $character = $el->as_trimmed_text;
        $characters{$character} = 1 if $character;
	$toc_table->add(
	    $character,
	    $el->attr('href'),
	    );
	print "character: " . $character . "\n" if $character;
    }
    print "\n";

    return keys %characters;
}

sub parseEpisodes($$)
{
    my ($doc, $season) = @_;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($doc);
 
    my $toc_table = Text::Table->new('Entry', 'Link');
    my @toc = $tree->findnodes('//div[@id="mw-content-text"]//table[' . $season . ']//table//td/b/a');
#    my @toc = $tree->findnodes('//h2[*="Season ' . $season . '"]/following-sibling::div[@id="mw-content-text"]//table//td/b/a');
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

my $url = 'http://simpsonswiki.com/wiki/List_of_episodes';
my @episodes = parseEpisodes(get($url), $ARGV[0]);
#my $url = 'http://simpsonswiki.com/wiki/Season_' . $ARGV[0];
#my @episodes = parseEpisodes(get($url));

die "Too many episodes: " . scalar @episodes if (@episodes > 30);

my %nodes = ();
my %edges = ();
my $index = 1;

# Loop through episodes.
for my $url ( @episodes ) {

    # Corrections.
    $url = '/wiki/The_Strong_Arms_of_the_Ma' if $url eq '/wiki/Strong_Arms_of_the_Ma';
    $url = '/wiki/Sleeping_with_the_Enemy' if $url eq '/wiki/Sleeping_With_the_Enemy';
    $url = '/wiki/Stop_or_My_Dog_Will_Shoot!' if $url eq '/wiki/Stop_or_My_Dog_Will_Shoot';
    $url = '/wiki/To_Surveil_With_Love' if $url eq '/wiki/To_Surveil_with_Love';

    print $url . "\n";

    # Get character appearances.
    my @characters = parseCharacters(get('http://simpsonswiki.com' . $url . '/Appearances'));
    print "Warning: too few characters: " . scalar @characters . "\n" if (@characters < 10);

    my @indices = ();

    # Loop through characters.
    for my $c ( @characters ) {

	# Create character key.
	my $key = uc($c);
	$key =~ s/\W+/_/g;

	# New character node?
	if (exists $nodes{$key}) {

	    # Existing: increment count.
	    my $node = $nodes{$key};
	    $node->{'count'}++;
	}
	else {

	    # New: create hash.
	    $nodes{$key} = { 'label' => $c, 'index' => $index++, 'count' => 1 };
	}

	# Get node index.
	my $ix = $nodes{$key}->{'index'};

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
print $nfh "Id\tLabel\tSize\n";
for my $k (sort { $nodes{$a}->{'index'} <=> $nodes{$b}->{'index'} } keys %nodes ) {
    
    my $node = $nodes{$k};
    print $nfh $node->{'index'} . "\t" . $node->{'label'} . "\t" . $node->{'count'} . "\n";
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
