#!/usr/bin/perl

#-System
$error_log = "/home/sites/site153/data/system/errorlog.dat";
$backuplog = "/home/sites/site153/data/system/backuplog.dat";

$current_user = $ENV{REMOTE_ADDR};
$referer = $ENV{HTTP_REFERER};
$user_agent = $ENV{HTTP_USER_AGENT};
$remote = $ENV{REMOTE_HOST};
$mail_prog = '/usr/lib/sendmail' ;

#- MySQL Variables
$host = "localhost";
$user = "faranani_tonercoz";
$password = "carlos4321";
$database = "faranani_tonercoza";

#=====================================================

read (STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
@cgiPairs = split(/&/,$buffer);
foreach $cgiPair (@cgiPairs)
{
  ($name,$value) = split(/=/,$cgiPair);
  $value =~ s/\+/ /g;
  $value =~ s/%(..)/pack("c",hex($1))/ge;
  $value =~ s/\%60/\`/g;
  $value =~ s/\%0\%0/\x/g;
  $value =~ s/\|/\_/g;
  $value =~ s/\'/\&\#146\;/g;
  $value =~ s/\"/\&\#148\;/g; 
  $form{$name} .= "\0" if (defined($form{$name}));
  $form{$name} .= "$value";
}
@vars = split(/&/, $ENV{QUERY_STRING});
foreach $var (@vars) {
        ($v,$i) = split(/=/, $var);
        $v =~ tr/+/ /;
        $v =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $i =~ tr/+/ /;
        $i =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $i =~ s/<!--(.|\n)*-->//g;
        $info{$v} = $i;
}

#-Info string
$func = $info{'fn'};
$page = $info{'pg'};
$BannId = $info{'bid'};

#--------------------------------------------------------------------------------------------------------------

use Mysql;
$dbh = Mysql->connect($host, $database, $user, $password);

$sql_statement = "SELECT NOW();";
$sth = $dbh->query($sql_statement);
@arr = $sth->fetchrow;
$DateNow = @arr[0];

print "Content-type: text/html\n";
#print "<!--Start:$DateNow-->\n";
#print "<!-- Another custom site by W3b.co.za -->\n";

$TimeStamp = time;
#$func = "get";

if ($func eq "get") { &rotate_next_banner; }
elsif ($func eq "fetch") { &link_to_banner; }
else { print "\nNo Banner Defined!"; }
exit;

#--------------------------------------------------------------------------------------------------------------

sub link_to_banner {
	$sql_statement = "SELECT * FROM banner_serve WHERE BannId = '$BannId';";
	$sth = $dbh->query($sql_statement);
	@arr = $sth->fetchrow;
	($BannId, $ClientId, $RotateFlag, $ActivFlag, $ImpCount, $ClickCount, $ImpLimit, $BanFile, $BanType, $LinkURL, $AltText, $DateStart, $DateEnd, $BannSerial, $LinkTarget, $ExcludeList) = @arr;
	
	$ClickCount++;
	$sql_statement = "UPDATE banner_serve SET ClickCount = '$ClickCount' WHERE BannId = '$BannId';";
	$sth = $dbh->query($sql_statement);

	print "Location: $LinkURL\nURI: $LinkURL\n\n\n" ;
	exit;


}

#--------------------------------------------------------------------------------------------------------------

sub rotate_next_banner {
	#print "1";
	$sql_statement = "SELECT * FROM banner_serve WHERE RotateFlag = '0' AND ActivFlag = '1' LIMIT 0,1;";
	$sth = $dbh->query($sql_statement);
	@arr = $sth->fetchrow;
	($BannId, $ClientId, $RotateFlag, $ActivFlag, $ImpCount, $ClickCount, $ImpLimit, $BanFile, $BanType, $LinkURL, $AltText, $DateStart, $DateEnd, $BannSerial, $LinkTarget, $ExcludeList) = @arr;
	
	if ($BannId eq "") { 
		$sql_statement = "UPDATE banner_serve SET RotateFlag = '0' WHERE ActivFlag = '1';";
		$sth = $dbh->query($sql_statement);

		$sql_statement = "SELECT * FROM banner_serve WHERE RotateFlag = '0' AND ActivFlag = '1' LIMIT 0,1;";
		$sth = $dbh->query($sql_statement);
		@arr = $sth->fetchrow;
		($BannId, $ClientId, $RotateFlag, $ActivFlag, $ImpCount, $ClickCount, $ImpLimit, $BanFile, $BanType, $LinkURL, $AltText, $DateStart, $DateEnd, $BannSerial, $LinkTarget, $ExcludeList) = @arr;
	}
	
	$ImpCount++;
	$sql_statement = "UPDATE banner_serve SET RotateFlag = '1',ImpCount = '$ImpCount' WHERE BannId = '$BannId';";
	$sth = $dbh->query($sql_statement);
	
	if ($LinkTarget eq "1") { $LinkTarget = "_blank"; } else { $LinkTarget = "_self"; }

	if ($BanType eq "0") { &output_standard; }	
	if ($BanType eq "1") { &output_getfile; }	
	if ($BanType eq "2") { &output_active; }	




}

#--------------------------------------------------------------------------------------------------------------

sub output_getfile {

print "\n\n";
$BannerHTML = "/home/sites/site153/web/banners/".$ClientId."/".$BanFile;

open (INPHILE, "<$BannerHTML");
@indata = <INPHILE>;
close (INPHILE);

foreach $line(@indata) {
	print $line;
}
}

sub output_standard {
	
print <<_EOF_;


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>$AltText</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>

<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table border="0" cellpadding="0" cellspacing="0" width="234">
 <tr>
  <td><a href="adrtt.pl?fn=fetch&bid=$BannId" target="$LinkTarget"><img src="../banners/$ClientId/$BanFile" alt="$AltText" width="234" height="60" border="0"></a></td>
 </tr>
</table>
</body>
</html>
_EOF_

	
}

sub output_active {
	
print <<_EOF_;


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv=Content-Type content="text/html; charset=iso-8859-1">
<title>$AltText</title>
<script language='JavaScript'>
<!--
	function interactive(text) {
		window.document.BannerMovie.SetVariable("LinkToURL", text);
	}
-->

</script>

</head>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" OnLoad="return interactive('adrtt.pl?fn=fetch&bid=$BannId');">
<!-- URL's used in the movie-->
<a href=$LinkURL> 
<!-- text used in the movie-->
<!--$AltText-->
<table border="0" cellpadding="0" cellspacing="0" width="468">
 <tr>
  <td><object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" WIDTH="468" HEIGHT="60" id="BannerMovie" ALIGN="">
<param name=movie value="../banners/$ClientId/$BanFile">
<param name=quality VALUE=high>
<param name=scale VALUE=exactfit>
<param name=devicefont VALUE=true>
<param name=bgcolor VALUE=#FFFFFF>
<embed src="../banners/$ClientId/$BanFile" quality=high scale=exactfit devicefont=true bgcolor=#006600  WIDTH="468" HEIGHT="60" NAME="BannerMovie" ALIGN="" TYPE="application/x-shockwave-flash" PLUGINSPAGE="http://www.macromedia.com/go/getflashplayer"></embed>
</object></td>
 </tr>
</table>
</body>
</html>
_EOF_
	
}

