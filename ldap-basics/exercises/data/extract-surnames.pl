#!/usr/bin/perl -w
#
# extract.pl
#
# Extract surnames from list of names

for (<>) {
	my @names;
	chomp;
	@names = split;

	my $last = $#names;
	if ($names[$last] =~ /../) {
		print $names[$last], "\n";
	}
}
