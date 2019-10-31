#!/usr/bin/perl -w
#
# generate random names for testing directory systems
#
# usage: generate.pl [-P] [number] [orgDN] [maildomain]
#
# -P adds Posix account data to LDIF file
# -g adds Posix group data to LDIF file (implies -P)
#
# Creates files:
#	names
#	names.ldif
#	names.passwd

########################################################################
# Operating parameters defaults
########################################################################
my $howmany = 10;
my $PosixLDIF = 0;
my $PosixGroups = 0;
my $OrgDN = "dc=example,dc=org";
my $MailDomain = "example.org";
########################################################################
# Output filenames
########################################################################
my $LDIFfile = "names.ldif";
my $NAMESfile = "names";
my $PASSWDfile = "names.passwd";
my $SEARCHfile = "names.search";
########################################################################

if ($ARGV[0] and ($ARGV[0] eq "-P")) {
	shift;
	$PosixLDIF = 1;
}

if ($ARGV[0] and ($ARGV[0] eq "-g")) {
	shift;
	$PosixLDIF = 1;
	$PosixGroups = 1;
}

if (defined($ARGV[0])) {
	$howmany = $ARGV[0];
}
if (defined($ARGV[1])) {
	$OrgDN = $ARGV[1];
}
if (defined($ARGV[2])) {
	$MailDomain = $ARGV[2];
}

my $PeopleDN = "dc=people,$OrgDN";
my $GroupsDN = "dc=groups,$OrgDN";

my @given;
open(GIVEN, "given-names") || die("Can't open given-names file");
my $ng = 0;
while (<GIVEN>) {
	chomp;
	$given[$ng++] = $_;
}
close(GIVEN);

my @surnames;
open(SURNAMES, "surnames") || die("Can't open surnames file");
my $ns = 0;
while (<SURNAMES>) {
	chomp;
	$surnames[$ns++] = $_;
}
close(SURNAMES);

# Create output files
open (NAMES, ">$NAMESfile") or die( "Cannot create $NAMESfile\n" );
open (LDIF, ">$LDIFfile") or die( "Cannot create $LDIFfile\n" );
open (PASSWD, ">$PASSWDfile") or die( "Cannot create $PASSWDfile\n" );
open (SEARCHES, ">$SEARCHfile") or die( "Cannot create $SEARCHfile\n" );

# print "Given: $ng Surname: $ns\n";

for ($count=1;$count<=$howmany;$count++) {
	my $s = int (rand $ns);
	my $g = int (rand $ng);
	my $uid = sprintf "u%06d", $count;
	my $groupName = sprintf "g%06d", $count;
	my $gecos = "$given[$g] $surnames[$s]";
	my $uidN = $count+10000;

	################################################
	# Names file
	################################################
	print NAMES $given[$g], " ", $surnames[$s], "\n";

	################################################
	# Search file
	################################################
	print SEARCHES "ldapsearch -b $PeopleDN  -s sub cn=\"", $given[$g], " ", $surnames[$s], "\"\n";

	################################################
	# LDIF file
	################################################
	printf LDIF "dn: uid=%s,%s\n", $uid,  $PeopleDN;

	print LDIF "objectclass: inetOrgPerson\n";
	if ($PosixLDIF) {
		print LDIF "objectclass: posixAccount\n";
	}
	print LDIF "displayName: ", $given[$g], " ", $surnames[$s], "\n";
	print LDIF "cn: ", $given[$g], " ", $surnames[$s], "\n";
	print LDIF "sn: ", $surnames[$s], "\n";
	print LDIF "uid: $uid\n";
	print LDIF "mail: $uid\@$MailDomain\n";
	# 01632 is allocated by OFCOM to film and TV dramas
	# 27644437 is a Bell Prime - seemed appropriate!
	printf LDIF "telephoneNumber: +44 1632 %06d\n", ($count * 27644437) % 1000000;
	if ($PosixLDIF) {
		print LDIF "userPassword: loadays\n";
		print LDIF "uidNumber: $uidN\n";
		print LDIF "gidNumber: $uidN\n";
		print LDIF "homeDirectory: /home/$uid\n";
		print LDIF "gecos: $gecos\n";
	}
	print LDIF "\n";

	# Posix group data
	if ($PosixGroups) {
		printf LDIF "dn: cn=%s,%s\n", $groupName, $GroupsDN;
		print LDIF "objectclass: posixGroup\n";
		print LDIF "cn: $groupName\n";
		print LDIF "gidNumber: $uidN\n";
		print LDIF "description: Personal group for $uid\n";
		print LDIF "\n";
	}

	################################################
	# Passwd file
	################################################
	printf PASSWD "%s:%s:%s:%s:%s:%s:%s\n",
		$uid, "UNSETPWXXXXXX",
		$uidN, $uidN,
		$gecos,
		"/home/$uid", "/bin/bash";
}
