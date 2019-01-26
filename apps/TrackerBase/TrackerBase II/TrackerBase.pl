#!/boot/home/config/bin/perl -w

use strict;
use TrackerBase;

# I tried using these subroutines for sorting but the use of the %tips hash
# caused problems.
#sub bytitle { $tips{$a}->{'title'} cmp $tips{$b}->{'title'}; }
sub byname { $a cmp $b; }
sub byreversenum { $b cmp $a; }

my ($base,$inputPath,$dataPath,$exportPath,$partPath,$bin,$extension,$mimeType,
	$index,$linkingAttribute,$runType,$dircount,$update,$adkey);
my ($line,$tmp,$attr,$tip,$cat);
my (%tips,%ads,%html,%cats,%hash);
my (@files,@catlist,@tmpar,@newtips,@catips);

$| = 1; # turn off buffering

# set defaults
$base = '/boot/apps/TrackerBase/projects/tipserver';
$inputPath = "$base/data";
$dataPath = '\\/boot\\/apps\\/TrackerBase\\/projects\\/tipserver\\/data\\/';
$exportPath = '/boot/home/betips';
$partPath = "$base/parts";
$bin = 'archive';
$extension = '.html';
$mimeType = 'text/html';
$index = 'index.html';
$linkingAttribute = 'category';

# bring in defaults from the packages:

%html = &TrackerBase::HTML($partPath);
%cats = &TrackerBase::Categories();

# set this var
$runType = $1;

# get a dir listing
opendir DIR, $inputPath;
@files = grep !/^\.+$/, readdir DIR;
closedir DIR;

# now that we have all of the files, let's get all of the attributes that we
# care about and put them into a hash

chdir $inputPath;
foreach $attr ('title',$linkingAttribute,'new')
{
	open CMD, "catattr \"TBASE:$attr\" @files |";
	while ($line = <CMD>)
	{
		chomp $line;
		@tmpar = split / : /, $line;
		$tips{$tmpar[0]}->{$attr} = $tmpar[2];

		$attr =~ 'category' and $hash{$tmpar[2]}++;
	}
	close CMD;
}

# Now we have all of the info we will ever need about the tips, and we don't
# have to do any more file accesses.  Yay!
# Since we already have all the info we care about, we shouldn't have to
# do any queries, either, right?

# this gives the length of the @ar array
$dircount = @files;

# get the date
$update = qx|date +%D|;

## Now, begin the actual work

# Here we get the actual category names from the files
#open CATS, "catattr \"TBASE:$linkingAttribute\" @files |";
#while ($line = <CATS>)
#{
#	chomp $line;
#	(undef,undef,$tmp) = split / : /, $line;
#	$hash{$tmp}++;
#}
#close CATS;

# now we have a category list; sort it
@catlist = sort byname keys %hash;

# do some printing...
print "\nBuilding index page ... this may take a minute ...\n";

# Now begin writing the page:
open INDEX, "> $exportPath/$index";
select INDEX; # this makes INDEX the default filehandle for printing
$| = 1;  # this turns of buffered writes

print $html{'indexhead2'};
print
"<FONT FACE=\"Arial, Helvetica\" SIZE=\"2\">
<!--#include virtual=\"/misc/todlink.txt\" -->
</font>\n";

print $html{'indexheadb2'};
print
"<font size=\"2\">Last updated: <B>$update</B> Current tip count: <B>$dircount</B></font>\n";
print $html{'indexpost'};

# Table for recent tips only
# this can probably be optimized, but I didn't feel like it...
# you could probably even use the Be::Attribute package
#open QUERY, "query \"((TBASE:new!='n')&&(TBASE:project=='tipserver')&&(BEOS:TYPE=='text/x-trackerbase'))\" | sed /Trash/d | sed s/$dataPath// | sort -r";
#while (<QUERY)
#{
#	push @newtips, $_;
#}
#close QUERY;
#@newlist = qx[query "((TBASE:new!='n')&&(TBASE:project=='tipserver')&&(BEOS:TYPE=='text/x-trackerbase'))" | sed /Trash/d | sed s/$dataPath// | sort -r];

foreach $tip (keys %tips)
{
	if (exists $tips{$tip}->{'new'} && $tips{$tip}->{'new'} !~ /n/)
	{
		push @newtips, $tip;
	}
}

# uncomment this if you want them alphabetical
@newtips = sort byreversenum @newtips;

# uncomment these four lines if you want them sorted by date
#chdir $dataPath;
#$tmp = qx|ls -t @newtips|;
#chomp $tmp;
#@newtips = split /\s/, $tmp;

# this prints the table of new tips
foreach $tip (@newtips)
{
	print "<A HREF=\"/cgi-bin/chunga.pl?ID=$tip\">$tips{$tip}->{'title'}</A>\n<BR>\n";
}

print "<P>\n";
print $html{'indexfoot1a'};
print $html{'navmap2'};
print "<blockquote>\n";
print $html{'indexfoot2'};

select STDOUT;
close INDEX;

print "Created index file at: $exportPath/$index\n";

# Now it is time to make the category pages...

# we already have a comment list
foreach $cat (@catlist)
{


	print "Creating menu page for $cat\n";

	# mmm, error checking...
	if (! exists $cats{$cat})
	{
		print "No info for category $cat\n";
		next;
	}

	# open the menu file for writing
	open CATFILE, "> $exportPath/$cats{$cat}->{'menu'}.html";
	select CATFILE;
	$| = 1;

	# write the headers
	print $html{'tip_head'};
	print "<title>The BeOS Tip Server: $cat</title>\n";
	print $html{'category_post_title2'};

	# put the ad into place
	print $html{'flycast_code'};
	print "<P>";
	
	# print the logo
	print "$cats{$cat}->{'LogoKey'}\n";
	print "<blockquote>\n";

	# now write all of the tips
	undef @catips;

	# I love hashes
	# the funky block causes sorting by title...
	foreach $tip (sort { $tips{$a}->{'title'} cmp $tips{$b}->{'title'} } keys %tips)
	{
		# if the cat matches, print it
		if ($tips{$tip}->{'category'} !~ $cat)
		{
			next; # skip any tip not in this category
		}

		# print the tip line
		print "<A HREF=\"/cgi-bin/chunga.pl?ID=$tip\">$tips{$tip}->{'title'}</A>\n";

		# see if it is new or updated; if so, print that
		for ($tips{$tip}->{'new'})
		{
			/y/ and do
			{
				print "<B>New</B>\n";
				next;
			};

			/u/ and do
			{
				print "<B>Updated</B>\n";
				next;
			};
		}

		print "<BR>\n";
	}

	# now print the footers
	print "$cats{$cat}->{'DiscussionKey'}\n";
	print $html{'category_post_list'};
	print $html{'navmap2'};
	print $html{'indexfoot2'};

	# close our file, and reselect STDOUT
	select STDOUT;
	close CATFILE;

	# add our attribute
	qx|addattr BEOS:TYPE $mimeType $exportPath/$cats{$cat}->{'menu'}.html|;
}

# yay, we are done
print "\nDone.  Your database export is at $exportPath.\n";

qx|alert "Tip Server menu pages have been updated"|;

