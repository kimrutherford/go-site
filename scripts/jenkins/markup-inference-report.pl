#!/usr/bin/perl
use strict;

# Usage:
#  curl -L http://purl.obolibrary.org/obo/go/editors/go_inferences_difflog.txt | ./markup-inference-report.pl
#
#  See: https://github.com/geneontology/go-ontology/issues/12485

my $today = `date +%Y-%m-%d`;
chomp $today;

print "Report for: $today\n";
my @lines = ();
my $in = 0;

my @blocks = ();

while(<>) {
    chomp;
    if (m@^r(\S+) \| (\S+) \| (\S+)\s+(.*)@) {
        my ($rev,$person,$date, $info) = ($1,$2,$3,$4);
        if ($date eq $today) {
            $in = 1;
            my $block = {
                rev => $rev,
                person => $person,
                date => $date,
                info => $info,
                lines => [],
                terms => [],
                n_adds => 0,
                n_dels => 0,
                line_no => scalar(@lines)
            };
            push(@blocks, $block);
                                          
        }
        if ($date lt $today) {
            last;
        }
    }
    
    if ($in) {
        my $block = $blocks[-1];
        push(@{$block->{lines}}, $_);
        if (m@^\+is_a@) {
            $block->{n_adds}++;
        }
        if (m@^\-is_a@) {
            $block->{n_dels}++;
        }
        if (m@id: (\S+) \! (.*)@) {
            push(@{$block->{terms}}, "$1 $2");
        }
        push(@lines, $_);
    }
}

foreach my $block (@blocks) {
    my $terms = $block->{terms};
    my $N = scalar(@$terms);
    my $rev = $block->{rev};
    my $summary = "$block->{person} ADD: $block->{n_adds} DEL: $block->{n_dels} terms: $N";
    $block->{summary} = $summary;
    print "<li><a href=\"#r$rev\">$rev</a> $summary</li>\n";
}

foreach my $block (@blocks) {
    my $rev = $block->{rev};
    print "<a name=\"r$rev\"/><h2>$rev: $block->{summary}</h2>\n";

    print "<pre>\n";
    foreach my $line (@{$block->{lines}}) {
        print "$line\n";
    }
    print "</pre>\n";
}

print "<hr/>\n";
print "<pre>\n";
print "Generated by: $0\n";
print "Generated for date: $today\n";
print "Generated on : ".`date`;
print "Questions : cjmungall AT lbl DOT gov";
print "</pre>\n";

exit 0;
