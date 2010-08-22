#!/usr/bin/perl
# extract Go code and compile it
use strict;
use warnings;

sub removeremark(@) {
    my @go;
    foreach(@_) {
	s/\|\\coderemark.*?\|//;
	s/\|\\longremark.*?\|//;
	push @go, $_;
    }
    @go;
}

sub nl(@) {
    my $i = 0;
    foreach(@_) {
	print ++$i, "\t", $_;
    }
}

sub gofmt(@) {
    open FMT, "|-", "gofmt > /dev/null";
	foreach(@_) {
	    print FMT  $_;
	}
    close FMT;
    $?;
}

my $inlisting = 0;
my @listing;
my ($snip, $func);
my (@func, @snip);
while(<>) {
    if (m|\\begin{lstlisting}|) {
	    $inlisting = 1;
	    next;
    }
    if (m|\\end{lstlisting}|) {
	    $inlisting = 0;
	    
	    @listing = removeremark(@listing);

	    if ( grep { /package main/ } @listing ) {
		print "// Full program\n";
	    } elsif ( grep { /func .*?\(/ } @listing ) {
		push @func, "// Function " . ++$func . "\n";
		@func = (@func, @listing);
	    } else {
		push @snip, "// Snippet " . ++$snip . "\n";
		@snip = (@snip, @listing);
	    }
	    @listing = ();
	    next;
    }
    if ($inlisting == 1) {
	push @listing, $_;
    }
}
# snippets
unshift @snip, <<EOF;
package main

import (
    "fmt"
)

func main() {	// START

EOF
push @snip, "}   // END\n";
unshift @func, <<EOF;
package main

func main () { }
EOF

print "SNIP SNIP SNIP\n";

if (gofmt(@snip) != 0) {
    nl @snip;
    print "NOT OK\n";
} else {
    print "OK\n";
}

print "FUNC FUNC FUNC\n";

if (gofmt(@func) != 0) {
    nl @func;
    print "NOT OK\n";
} else {
    print "OK\n";
}
