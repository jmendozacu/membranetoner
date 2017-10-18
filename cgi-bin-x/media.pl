#!/usr/bin/perl

#print "Content-type: text/html\n\n";

require "config.pl";

#- Split query string

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

$uid = $info{'u'};
$func = $info{'f'};
$mType = $info{'t'};
$UserId = $info{'p'};

if ($func ne "upload") {
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
    push(@debugstring,"POST:||\$$name -&raquo; $value");
  }
}
#=================================================================================

if ($func eq "list") { &jslist_users_files; }
elsif ($func eq "man") { &open_manager_windo; }
elsif ($func eq "add") { &save_new_media; }
elsif ($func eq "edit") { &edit_new_media; }
elsif ($func eq "del") { &delete_new_media; }
elsif ($func eq "upload") { &upload_new_media; }
else { &jslist_users_files; }

exit;

#--------------------------------------------------------------------------------

sub edit_new_media {
  if ($mType eq "lnk") {
    $LinkId = $info{'d'};
    $sql_statement = "SELECT * FROM media_links WHERE UserId = '$UserId' AND LinkId = '$LinkId'";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    ($LinkId, $UserId, $AddDate, $LinkDescript, $LinkURL) = @arr;

    &open_manager_windo;
  }
  


}

#--------------------------------------------------------------------------------

sub delete_new_media {
  if ($mType eq "lnk") {
    $LinkId = $info{'d'};
    $sql_statement = "DELETE FROM media_links WHERE UserId = '$UserId' AND LinkId = '$LinkId'";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement);
    $StatusDisplay = "_ICONOK_|Your Bookmark link was deleted successfully!|";
    &open_manager_windo;
  }
  if ($mType eq "img") {
    $LinkId = $info{'d'};
    $sql_statement = "SELECT ImageName FROM media_images WHERE LinkId = '$LinkId';";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    $ImageName = @arr[0];
    $outphile = $userroot."gallery/".$ImageName;
    unlink $outphile;
    $outphile = $userroot."gallery/thumbs/".$ImageName;
    unlink $outphile;
    $sql_statement = "DELETE FROM media_images WHERE LinkId = '$LinkId'";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement);
    $StatusDisplay = "_ICONOK_|Your Gallery Image was deleted successfully!|";

    $sql_statement = "DELETE FROM media_links WHERE UserId = '$UserId' AND LinkId = '$LinkId'";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement);
    &open_manager_windo;
  }
  


}

#--------------------------------------------------------------------------------

sub save_new_media {
  if ($mType eq "lnk") {
    $LinkDescript = $form{'LinkDescript'};
    $LinkURL = $form{'LinkURL'};
    $LinkURL =~ s/http\:\/\///gi;
    $LinkId = $info{'d'};
    if ($LinkId ne "") {
      $sql_statement = "UPDATE media_links SET AddDate = '$TimeStamp',LinkDescript = '$LinkDescript',LinkURL = '$LinkURL' WHERE LinkId = '$LinkId' AND UserId = '$UserId';";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement);
      $StatusDisplay = "_ICONOK_|Your Bookmark link was updated successfully!|";
      $LinkId = "";
    }
    else {
      $sql_statement = "SELECT COUNT(*) FROM media_links WHERE LinkURL LIKE '$LinkURL' AND UserId = '$UserId'";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement);
      @arr = $sth->fetchrow;
      $TestCNT = @arr[0];
      if ($TestCNT > 0) { $StatusDisplay = "_ICONERROR_|The URL you entered has already been included in your bookmarks!|Please enter a unique URL!"; }
      elsif (length($LinkURL) < 5) { $StatusDisplay = "_ICONERROR_|The URL you entered appears to be invalid!|Please enter a valid URL!"; }
      else {
        if ($LinkDescript eq "") { $LinkDescript = $LinkURL; }
        $sql_statement = "INSERT INTO media_links VALUES ('','$UserId','$TimeStamp','$LinkDescript','$LinkURL');";
        push(@debugstring,"SQL||$sql_statement");
        $sth = $dbh->query($sql_statement);
        $StatusDisplay = "_ICONOK_|Your Bookmark link was added successfully!|";
        $LinkURL = "";
        $LinkDescript = "";
      }
    }
    &open_manager_windo;
  }

}

#--------------------------------------------------------------------------------

sub open_manager_windo {
  $MediaCount = "0";
  if ($mType eq "lnk") {
    $sql_statement = "SELECT * FROM media_links WHERE UserId = '$UserId' ORDER BY AddDate DESC;";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement);
    while (@arr = $sth->fetchrow) {
      ($XLinkId, $XUserId, $AddDate, $XLinkDescript, $XLinkURL) = @arr;
      $XLinkURL = "http://".$XLinkURL;
      &convert_timestamp($AddDate);
      $AddDate = $ConvTimeStampShort;
      if ($FirstFlag ne "1") { $XLinkDescript = "<b>$XLinkDescript</b>"; $FirstFlag = "1"; }
      if ($BgFlag eq "1") { $BgColor = "#F2F2F2"; $BgFlag = "0"; } else { $BgColor = "#FFFFFF"; $BgFlag = "1"; }
      $MediaList = $MediaList." <tr><td bgcolor=\"$BgColor\">$AddDate</td><td bgcolor=\"$BgColor\">&nbsp;<a href=\"$XLinkURL\" title=\"Click to open: $XLinkURL\" target=\"_blank\">$XLinkDescript</a></td><td align=\"center\" bgcolor=\"$BgColor\"><a href=\"$XLinkURL\" title=\"$XLinkURL\" target=\"_blank\"><img src=\"../images/con_info.gif\" border=\"0\"></a><a href=\"media.pl?f=edit&t=lnk&p=$UserId&u=$uid&d=$XLinkId\" title=\"Edit Link\"><img src=\"../images/edit.gif\" border=\"0\" hspace=\"2\"></a><a href=\"media.pl?f=del&t=lnk&p=$UserId&u=$uid&d=$XLinkId\" title=\"Delete Link\"><img src=\"../images/del_nb.gif\" border=\"0\"></td></tr>\n";
      $MediaCount++;
    }
    if ($MediaCount eq "0") { $MediaList = $MediaList."<tr><td colspan=\"2\" align=\"center\">No Bookmark Links to Display</td></tr>\n"; }

    $PageTitle = "Bookmark Manager [$UserId]";
    $page = "media_addlink";
    &print_html;
  }   
  if ($mType eq "img") {
    &create_image_gallery;
    $PageTitle = "Image/Photo Gallery Manager [$UserId]";
    $page = "media_addimg";
    &print_html;
  }   


}

sub create_image_gallery {
  $ColumnCount = "1";
  $sql_statement = "SELECT * FROM media_images WHERE UserId = '$UserId' ORDER BY AddDate DESC;";
  push(@debugstring,"SQL||$sql_statement");
  $sth = $dbh->query($sql_statement);
  while (@arr = $sth->fetchrow) {
    ($XLinkId, $XUserId, $AddDate, $XImageTitle, $XImageDescript, $ImageName, $ImageCSum, $ImageSize, $ImageX, $ImageY, $XImageURL) = @arr;
    $XLinkURL = "http://".$XLinkURL;
    &convert_timestamp($AddDate);
    $AddDate = $ConvTimeStampShort;
    if ($ColumnCount == 1) { $MediaList = $MediaList."<tr>\n"; }
    if ($FirstFlag eq "1") { $FirstFlag = "0"; }
    else {
      $ThumbPath = $userroot."gallery/thumbs/".$ImageName;
      if (-e $ThumbPath) { $ImageFound = "1"; }
      else { $ImageName = "none.jpg"; }
      $BgColor = "#F2F2F2";
      $MediaList = $MediaList."<td bgcolor=\"$BgColor\" align=\"center\">$AddDate<br><a href=\"../user/gallery/".$ImageName."\" title=\"$ImageTitle\" target=\"_blank\"><img src=\"../user/gallery/thumbs/".$ImageName."\" alt=\"$ImageTitle\"></a><br><span class=\"SubEditText\">$ImageSize Kb<br>$ImageX x $ImageY pixels</span><br><a href=\"media.pl?f=del&t=img&p=$UserId&u=$uid&d=$XLinkId\" title=\"Delete Link\"><img src=\"../images/del_nb.gif\" border=\"0\" hspace=\"3\" align=\"absmiddle\">Delete</a>&nbsp;</td>\n";
      $MediaCount++;
      if ($ColumnCount == 4) { $MediaList = $MediaList."</tr>\n"; $ColumnCount = "0"; }
      $ColumnCount++;
    }
  }
  if ($MediaCount eq "0") { $MediaList = $MediaList."<tr><td colspan=\"4\" align=\"center\">No Images in your Gallery to Display</td></tr>\n"; }
  $MediaList = $MediaList."<tr><td><img src=\"../images/blank.gif\" width=\"125\" height=\"1\"></td><td><img src=\"../images/blank.gif\" width=\"125\" height=\"1\"></td><td><img src=\"../images/blank.gif\" width=\"125\" height=\"1\"></td><td><img src=\"../images/blank.gif\" width=\"125\" height=\"1\"></td></tr>\n";
}

#--------------------------------------------------------------------------------

sub jslist_users_files {
  print "Content-type: application/x-javascript\n\n";
  if ($mType eq "lnk") {
    $JsOutput = $JsOutput."\nvar tinyMCELinkList = new Array(";
    $sql_statement = "SELECT * FROM media_links WHERE UserId = '$UserId' ORDER BY AddDate DESC;";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement);
    while (@arr = $sth->fetchrow) {
      ($XLinkId, $XUserId, $AddDate, $XLinkDescript, $XLinkURL) = @arr;
      $XLinkURL = "http://".$XLinkURL;
      $JsOutput = $JsOutput."\n[\"$XLinkDescript\", \"$XLinkURL\"],";
    }
    chop $JsOutput;
  }
  if ($mType eq "img") {
    $JsOutput = $JsOutput."\nvar tinyMCEImageList = new Array(\n";
    $sql_statement = "SELECT * FROM media_images WHERE FolderName != 'source' ORDER BY TimeStamp DESC;";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement);
    while (@arr = $sth->fetchrow) {
      ($ImageId, $StatFlag, $TimeStamp, $FolderName, $OriginalPhile, $NewPhile, $PhileSize, $PhileX, $PhileY) = @arr;
      #($XLinkId, $XUserId, $AddDate, $ImageTitle, $ImageDescript, $ImageName, $ImageCSum, $ImageSize, $ImageX, $ImageY, $ImageURL) = @arr;
      $ImageCount++;
      $XLinkURL = "http://".$XLinkURL;
      $JsOutput = $JsOutput."\n[\"$ImageCount\. $NewPhile ($OriginalPhile)\", \"../user/$FolderName/".$NewPhile."\"],";
      $JsOutput = $JsOutput."\n[\"  Thumb: $ImageTitle\", \"../user/thumbs/".$NewPhile."\"],";
    }
    chop $JsOutput;
  }
  
  
  print $JsOutput."\n);\n\n";
  exit;

}

#--------------------------------------------------------------------------------

sub upload_new_media {
#print "Content-type: text/html\n\n";

&generate_random_string;
use CGI;
my $req = new CGI;
my $file = $req->param("FILE1");
my $ImageTitle = $req->param("ImageTitle");
my $ImageDescript = $req->param("ImageDescript");
my $ImageURL = $req->param("ImageURL");
my $fileName = $file;
$fileName =~ s!^.*(\\|\/)!!;
$fileName =~ tr/A-Z/a-z/;
$TestFile = substr($fileName,-5,5);

if (index($TestFile,".jpg") > -1) { $outphileName = $SessId.".jpg"; }
if (index($TestFile,".jpeg") > -1) { $outphileName = $SessId.".jpeg"; }
if (index($TestFile,".gif") > -1) { $outphileName = $SessId.".gif"; }
if (index($TestFile,".png") > -1) { $outphileName = $SessId.".png"; }

#print "$outphileName<br>";

if (($outphileName eq "") && ($ImageURL eq "")) {
  $StatusDisplay = "_ICONERROR_|Upload Error: '$fileName' is not a JPEG, GIF, or PNG image!|Only JPEG, GIF, or PNG format images are accepted!";
  unlink $outphile;
  &open_manager_windo;
}
elsif ($ImageURL ne "") {
  $ImageURL =~ s/http\:\/\///gi;
  $ImageURL = "http://".$ImageURL;

  use LWP::UserAgent;

  $ua = new LWP::UserAgent;
  $ua->agent("Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)");
  $ua->timeout('120');
#  $ua->max_size('400000');
  $Header = $ua->head($ImageURL);
 
  $outphile = $userroot."gallery/".$SessId.".tmp";
  my $response = $ua->mirror($ImageURL,$outphile);
  if ($response->is_success) {
    sleep(1);
    open (INPHILE, "<$outphile");
    $indata = <INPHILE>;
    close(INPHILE);
   
    $indata = substr($indata,0,12);
    if (index($indata,"JFIF") > -1) { $FileType = ".jpg"; }
    elsif (index($indata,"GIF") > -1) { $FileType = ".gif"; }
    elsif (index($indata,"PNG") > -1) { $FileType = ".png"; }
    else {
      $StatusDisplay = "_ICONERROR_|Fetch URL Error: URL given is not a JPEG, GIF, or PNG image!|Only JPEG, GIF, or PNG format images are accepted!";
      #Sunlink $outphile;
      &open_manager_windo;
    }
    $outphileNew = $userroot."gallery/".$SessId.$FileType;
    use File::Copy;
    copy($outphile,$outphileNew);
    sleep(1);
    unlink $outphile;
    $outphile = $outphileNew;
    $outphileName = $SessId.$FileType;
  }
  else {
    $CheckError = $response->status_line;
    $CheckError = substr($CheckError,0,3);
    $StatusDisplay = "_ICONERROR_|Fetch URL Error: '$CheckError' URL given is not a valid!|Please enter a valid URL!";
    unlink $outphile;
    &open_manager_windo;
  } 
}
else {
  $outphile = $userroot."gallery/".$outphileName;

  open (OUTFILE, ">$outphile");
  binmode(OUTFILE, ":raw");
  while (my $bytesread = read($file, my $buffer, 1024)) {
    print OUTFILE $buffer;
  }
  close (OUTFILE);
  chmod(0777,$outphile);
}

use Image::Size;
($globe_x, $globe_y) = imgsize("$outphile");

($FileSize, $filedate, $perm) = (stat($outphile))[7, 9, 2];
$perm = sprintf "%lo", ($perm & 07777);
$FileSize = $FileSize/1024;
$FileSize = sprintf("%.2f",$FileSize);

if ($FileSize > 350) {
  $StatusDisplay = "_ICONALERT_|'$fileName' exceeds the maximum allowable image file size of 350 kb!||";
  unlink $outphile;
  &open_manager_windo;
}

if (($globe_x > 401) || ($globe_y > 641)) {
  $StatusDisplay = "_ICONALERT_|<font color=\"#FF6600\">'$fileName' exceeds the maximum allowable image size!|Image has been automatically resized</font>|";
  $ResizeFullFlag = "0";
  if ($globe_x > 401) {
    $AspectRatio = $globe_x / $globe_y;
    $globe_y = 401 / $AspectRatio;
    $globe_y = sprintf("%.0f",$globe_y);
    $globe_x = "401";
  }
  else {
    $AspectRatio = $globe_y / $globe_x;
    $globe_x = 641 / $AspectRatio;
    $globe_x = sprintf("%.0f",$globe_x);
    $globe_y = "641";
  }
}
else { $ResizeFullFlag = "1"; }

if (($globe_x > 100) || ($globe_y > 100)) {
  $ResizeThumbFlag = "0";
  if ($globe_x > 100) {
    $AspectRatio = $globe_x / $globe_y;
    $globe_thy = 100 / $AspectRatio;
    $globe_thy = sprintf("%.0f",$globe_thy);
    $globe_thx = "100";
    $globe_thy = "100";
  }
  else {
    $AspectRatio = $globe_y / $globe_x;
    $globe_thx = 100 / $AspectRatio;
    $globe_thx = sprintf("%.0f",$globe_x);
    $globe_thy = "100";
  }
}
else {
  $globe_thx = $globe_x;
  $globe_thy = $globe_y;
  #$ResizeThumbFlag = "1";
}

$sql_statement = "INSERT INTO media_images VALUES ('','$UserId','$TimeStamp','$ImageTitle','$ImageDescript','$outphileName','$ImageCSum','$FileSize','$globe_x','$globe_y','$ImageURL');";
push(@debugstring,"SQL||$sql_statement");
$sth = $dbh->query($sql_statement);

$ImageString = $ImageString." <tr><td colspan=\"3\"><table width=\"540\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\">\n";
$ImageString = $ImageString." <tr><td width=\"110\" valign=\"top\" align=\"center\"><b>Thumbnail</b><br><iframe name=\"ThumbWindo\" width=\"110\" height=\"180\" src=\"../user/gallery/resize_thumb.php?fn=$outphileName&pw=$globe_thx&ph=$globe_thy&ds=$ResizeThumbFlag&u=$SessId\" border=\"0\" frameborder=\"0\" scrolling=\"auto\"></iframe></td>\n";
if ($globe_x > 400) { $ShowX = "400"; } else { $ShowX = $globe_x; }
$ImageString = $ImageString." <td width=\"410\" valign=\"top\" align=\"center\"><img src=\"../user/gallery/".$outphileName."\" border=\"1\" width=\"$ShowX\"></td></tr>\n";
$ImageString = $ImageString." </table></td></tr>\n";


#$ImageString = "<tr><td colspan=\"3\" align=\"center\"><img src=\"../user/gallery/".$outphileName."\" width=\"$ShowX\" border=\"1\" vspace=\"5\"><br>$ImageTitle<br><span class=\"SubEditText\">$FileSize Kb ($globe_x x $globe_y pixels)</span><br><a href=\"../user/gallery/".$outphileName."\" target=\"_blank\">View Full Size</a><br>&nbsp;</td></tr>\n";
if ($ResizeFullFlag eq "1") { $StatusDisplay = "_ICONOK_|'$fileName' was saved successfully!||"; }

$FirstFlag = "1";
&create_image_gallery;

  $PageTitle = "Image/Photo Gallery Manager [$UserId]";
  $page = "media_addimg";
  &print_html;
}   

#--------------------------------------------------------------------------------------------------------------
sub print_html {

if ($StatusDisplay ne "") {
  ($IconImage,$ErrorMessage,$FixMessage) = split(/\|/,$StatusDisplay);
  $StatusDisplay = "<table width=\"100%\" border=\"0\" cellspacing=\"1\" cellpadding=\"1\"><tr><td valign=\"top\" width=\"4%\">$IconImage</td><td width=\"96%\"><b>$ErrorMessage</b><br>$FixMessage</td></tr></table>\n";
}
else { $StatusDisplay = "<img src=\"../images/blank.gif\">"; }

print "Content-type: text/html\n\n";
print "<!--$outphile : $fileName : $newmain : $globe_x,$globe_y \n $ImageString-->\n";
if ($AlertPrompt ne "") { $AlertPrompt = "\nwindow.alert(\"".$AlertPrompt."\");"; }
$template = $docroot.$page.".html";
open (INPHILE, "<$template");
@indata = <INPHILE>;
close(INPHILE);

foreach $line(@indata) {
	$line =~ s/_UID_/$uid/g;
	$line =~ s/_USERID_/$UserId/g;
	$line =~ s/_ERRORMSG_/$ErrorMsg/g;
	$line =~ s/_ALERT_PROMPT_/$AlertPrompt/g;
	$line =~ s/_PAGEHEADER_/$PageTitle/g;
	$line =~ s/_FULLDETAIL_/$FullFileDetail/g;
	$line =~ s/_AVATARFILE_/$AvatarFile/g;
	$line =~ s/_AVATARLIST_/$AvatarList/g;
	$line =~ s/_AFDT_/$AvatarDetail/g;
	$line =~ s/_PAGE_TITLE_/$PageTitle/g;

  $line =~ s/_LINKDESCRIPT_/$LinkDescript/g;
	$line =~ s/_LINKURL_/$LinkURL/g;
	$line =~ s/_LINKID_/$LinkId/g;
  $line =~ s/_MEDIALIST_/$MediaList/g;

  $line =~ s/_IMAGESTRING_/$ImageString/g;
  $line =~ s/_IMAGETITLE_/$ImageTitle/g;
  $line =~ s/_IMAGEDESCRIPT_/$ImageDescript/g;
  $line =~ s/_IMAGEURL_/$ImageURL/g;
  
  $line =~ s/_STATUSDISPLAY_/$StatusDisplay/g;
  $line =~ s/_ICONOK_/$IconOK/g;
  $line =~ s/_ICONERROR_/$IconError/g;
  $line =~ s/_ICONALERT_/$IconAlert/g;
  $line =~ s/_MEDIACOUNT_/$MediaCount/g;

	print "$line";
}
exit;
}

#--------------------------------------------------------------------------------------------------------------
sub generate_random_string {
for ($a=0; $a <= 2500; $a++) {
    $rval = rand(74);
    $rval = $rval + 48;
    $rval = sprintf("%.0f", $rval);
    $rval = chr($rval);
    $SessId = $SessId.$rval;
    $SessId =~ tr/A-Za-z0-9/ /cs;
    $SessId =~ s/ //g;
    if (length($SessId) > 15) {
      $SessId = $SessId.$TimeStamp;
      return;
    }
}
}
sub convert_timestamp {
    local($e) = @_;
    if ($e eq "") { $ConvTimeStamp = "N/A"; return; }
    ($tsec,$tmin,$thour,$tmday,$tmon,$tyear,$twday,$tyday,$tisdst) = localtime($e);
    $tyear = $tyear + 1900;
    $tmon++;
    if ($tmon < 10) { $tmon = "0".$tmon; }
    if ($tmday < 10) { $tmday = "0".$tmday; }
    if ($tsec < 10) { $tsec = "0".$tsec; }
    if ($tmin < 10) { $tmin = "0".$tmin; }
    if ($thour < 10) { $thour = "0".$thour; }
    $ConvTimeStamp = "$tyear-$tmon-$tmday $thour:$tmin";
    $ConvTimeStampShort = "$tyear-$tmon-$tmday";
}

#---------------------------------------------------------------------------------------------------------------------------
#sub unlock {
#  local($file)=@_;
  #flock($file, $LOCK_UN);
#}
#--------------------------------------------------------------------------------------------------------------
