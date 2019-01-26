#!/boot/home/config/bin/perl
#     ____      _____ _                        _
#    | __ )  __|_   _(_)_ __  ___   _ __   ___| |_
#    |  _ \ / _ \| | | | '_ \/ __| | '_ \ / _ \ __|
#    | |_) |  __/| | | | |_) \__ \_| | | |  __/ |_
#    |____/ \___||_| |_| .__/|___(_)_| |_|\___|\__|
#                      |_|
#     BeGirl's version 2.0.1

###########
## NOTES ##
###########

# - You can't use paths starting from home (e.g.: ~/file.txt)
#   in Perl since ~ is expanded by shell!
#
# The following codes may be used in the HTML file:
# !TIP!          The tip itself... inserts the text of the tip.
# !TIPID!        The number of the tip (numeric value only).
# !TITLE!        The title of the tip.
# !CATEGORY!     The category that the tip is located in.
# !AUTHOR!       The name of the tip's author.
# !URL!          The URL of the tip's author.
# !EMAIL!        The email address of the tip's author.
# !BASEURL!      The base URL of the site.


###############
## VARIABLES ##
###############

# Set root of data path
# This is where the actual TrackerBase data files are kept.
$TipRoot = "/boot/apps/TrackerBase/projects/tipserver/data";

# Location of tip HTML template.
$TipHTML = "/boot/home/betips/templates/chungatip.template";

#Set the default language ("en" or "ru")
#Don't pay any attention to it - it's for my convinience
$DefaultLang = "en";

# Base URL - Leave this blank to run locally... this will make
# images show up if it's run from the wrong server.
$BaseURL = "";


##################
## SETUP SCRIPT ##
##################

# Get the CGI library of functions.
require("cgi-lib.pl");

# Invoke the BFS perl module.
use Be::Attribute;

# First, get the CGI variables from the URL into a hash.
&ReadParse(*input);

# Here we check that ID is given
$TipID = "$input{'ID'}";
($TipID ne "") || &HTMLdie("No tip ID given!") ;	


# Compose a full path to the tip and check if there is one.
# (GetBNode returns NULL if it cannot open the file, but ReadAttr and other functions crash on NULL.)
$ThisTip = "$TipRoot/$Lang/$TipID";
( -f $ThisTip ) || &HTMLdie ("This tip doesn't exist!"); 


########################
## OBTAIN INFORMATION ##
########################

# Obtain the node of the tip file.
$TipNode = Be::Attribute::GetBNode($ThisTip) || &HTMLdie ("There was an error opening tip $ThisTip");

# Error checking to prevent a crash if the node is incorrectly set-up and ReadAttr is called.	
if ($TipNode != 0){
	# Get detailed attributes from the tip file.
	$ThisAuthor = Be::Attribute::ReadAttr($TipNode, "TBASE:author");
	$ThisCategory = Be::Attribute::ReadAttr($TipNode, "TBASE:category");
	$ThisTitle = Be::Attribute::ReadAttr($TipNode, "TBASE:title");
	$ThisURL = Be::Attribute::ReadAttr($TipNode, "TBASE:url");	
	$ThisEmail = Be::Attribute::ReadAttr($TipNode, "TBASE:email");

	# Must close the node or else things will eventually clog up and die
	Be::Attribute::CloseNode ($TipNode);

	# For later use: strip "tip" from tipid
	$BaseID = $TipID;
	$BaseID =~ s/tip//gi;
}


##################
## PROCESS DATA ##
##################

# We'll need logos for each category
if ($ThisCategory eq  "Applications" ) {
	$PageLogoName = "applications";
} elsif ($ThisCategory eq  "Audio & Video" ) {
	$PageLogoName = "audiovideo";
} elsif ($ThisCategory eq  "Hardware" ) {
	$PageLogoName = "hardware";
} elsif ($ThisCategory eq  "Interface" ) {
	$PageLogoName = "interface";
} elsif ($ThisCategory eq  "Miscellaneous" ) {
	$PageLogoName = "miscellaneous";
} elsif ($ThisCategory eq  "Networking" ) {
	$PageLogoName = "networking";
} elsif ($ThisCategory eq  "Scripting" ) {
	$PageLogoName = "scripting";
} elsif ($ThisCategory eq  "Terminal" ) {
	$PageLogoName = "terminal";
} elsif ($ThisCategory eq  "Tracker and Deskbar" ) {
	$PageLogoName = "tracker";
} elsif ($ThisCategory eq  "Warnings" ) {
	$PageLogoName = "warnings";
}

# Now convert the page logo name into a real page logo.
$PageLogo = "<img src=\"/images/${PageLogoName}.gif\" width=273 height=75 alt=\"\u${PageLogoName}\">";

# Generate information about the contributor of this tip.
if ($ThisEmail ne "") {
	$MailLine= "<A HREF=\"mailto:$ThisEmail\">$ThisAuthor</A>";
} else {
	$MailLine= "$ThisAuthor";
}

# Generate 
# Determine whether or not to include a URL link
if ($ThisURL ne " ") {
	$ThisURL = "Contributor's URL: <a href=\"$ThisURL\">$ThisURL</a>";
}
	

###################
## PRINT THE TIP ##
###################

# Print the CGI content type header.
print "Content-type: text/html\n\n" ; 

# Read the tip's HTML file.
undef $/;
open(TIPHTML, "$TipHTML") || &HTMLdie ("Cannot open tip HTML file.");
$TipPrint = <TIPHTML>;
close(TIPHTML);

# Read the current tip.
open (TIPFILE, "$ThisTip") || &HTMLdie ("Cannot open tip file ${ThisTip}.");
$TipItself = <TIPFILE>;
close TIPFILE;

# Replace codes in the file.
$TipPrint =~ s/!TIP!/$TipItself/gi;
$TipPrint =~ s/!TITLE!/$ThisTitle/gi;
$TipPrint =~ s/!CATEGORY!/$ThisCategory/gi;
$TipPrint =~ s/!BASEURL!/$BaseURL/gi;
$TipPrint =~ s/!AUTHOR!/$ThisAuthor/gi;
$TipPrint =~ s/!URL!/$ThisURL/gi;
$TipPrint =~ s/!EMAIL!/$MailLine/gi;
$TipPrint =~ s/!LOGO!/$PageLogo/gi;
$TipPrint =~ s/!TIPID!/$BaseID/gi;

# Print the tip page.
print $TipPrint;

##############
## HTML DIE ##
##############

sub HTMLdie {
	# Read in data from passed variables.
	local($msg,$title)= @_ ;
	
	# Generate a title if there is none.
	$title || ($title= "BeTips Error");

	# Print the error now.
	print "Content-type: text/html\n\n" ; 
	print <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head> 
	<title>$title</title> 
</head> 

<body bgcolor="#FFFFFF"> 
	<h1>$msg</h1> 
</body> 
</html> 
EOF
	exit;
}
