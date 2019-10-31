#!/usr/bin/perl -w
#
# extract-given.pl
#
# Extract given names from list of names

for (<>) {
	my @names;
	chomp;
	@names = split;

	if ($names[0] =~ /../) {
		print $names[0], "\n";
	}
}
