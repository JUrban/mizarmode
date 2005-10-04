#!/usr/bin/perl

# SYNOPSIS:

# mizf text/card_1.miz
# Consider.pl text/card_1.xml | grep line

# This script prints the last propositions in "consider" items,
# which are immediately referenced.

use XML::LibXML;
use strict;
my $parser = XML::LibXML->new();
my $doc = $parser->parse_file($ARGV[0]);

# For understanding the XPath expressions, see the up-to-date
# Mizar RELAX NG doc in the Mizar distro, or at
# http://lipa.ms.mff.cuni.cz/~urban/Mizar.html (a bit outdated).

my @result = $doc->findnodes('//Consider/Proposition[(position()=last()) 
and (position() > 1) 
and (../following-sibling::*[1][(name()="Proposition")]) 
and (@nr = ../following-sibling::*[2][(name()="By")
     ]/Ref[not(@articlenr)]/@nr)]');

push @result, $doc->findnodes('//Consider/Proposition[(position()=last()) 
and (position() > 1) 
and (@nr = ../following-sibling::*[1][(name()="Conclusion") 
     or (name()="Reconsider") or (name()="Consider"
     )]/By/Ref[not(@articlenr)]/@nr)]');

foreach my $res (@result) { print $res->toString, "\n"; }
