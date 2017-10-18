#!/usr/bin/perl

#print "Content-type: text/html\n\n";

require "admconfig.pl";

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

$uid = $info{'uid'};
$func = $info{'f'};
$ProdId = $info{'pid'};
$OrderCode = $info{'oc'};
$TokenKey = $info{'tk'};
$FolderName = $info{'ifn'};
$ImageId = $info{'img'};

#=================================================================================

if ($func eq "upload") { &get_upload_files; }
elsif ($func eq "view") { &view_image_files; }
else { &show_upload_form; }

exit;

#--------------------------------------------------------------------------------
sub show_upload_form {
  if ($ImageId ne "") {
    $sql_statement = "SELECT NewPhile FROM media_images WHERE ImageId = '$ImageId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement");
    @arr = $sth->fetchrow;
    ($ExistPhile) = @arr;

    $outphile = $imgroot.$FolderName."/".$ExistPhile;
  
    if (-e $outphile) {
      use Image::Size;
      ($globe_x, $globe_y) = imgsize("$outphile");
      ($FileSize, $filedate, $perm) = (stat($outphile))[7, 9, 2];
      $perm = sprintf "%lo", ($perm & 07777);
      $FileSize = $FileSize/1024;
      $FileSize = sprintf("%.2f",$FileSize);
      $FullFileDetail = "File Name: $ProdImage<br>File Size: ".$FileSize." Kb<br>Dimensions: ".$globe_x." x ".$globe_y." (WxH pixels)";
    }
    
  }
  else { $ViewProdImage = "none.gif"; }
  $InstructText = "Attach Image File for upload to '".$FolderName."/':";

  $PageTitle = "Upload Product Images";
  $page = "gallery_upload";
  &print_html;
}

#--------------------------------------------------------------------------------

sub view_image_files {

  $ProdImage = $OrderCode.".jpg";
  $ImagePath = $ThumbNailPath.$OrderCode.".jpg";
  if (-e $ImagePath) {
    $ViewProdImage = $ProdImage;
    $outphile = $imgroot."full/".$OrderCode.".jpg";
    use Image::Size;
    ($globe_x, $globe_y) = imgsize("$outphile");
    ($FileSize, $filedate, $perm) = (stat($outphile))[7, 9, 2];
    $perm = sprintf "%lo", ($perm & 07777);
    $FileSize = $FileSize/1024;
    $FileSize = sprintf("%.2f",$FileSize);
    $FullFileDetail = "Existing File Name: ".$OrderCode.".jpg<br>File Size: ".$FileSize." Kb<br>Dimensions: ".$globe_x." x ".$globe_y." (WxH pixels)";
    
  } else { $ViewProdImage = "none.gif"; }

  $PageTitle = "View Product Images";
  $page = "image_view";
  &print_html;
}
#--------------------------------------------------------------------------------

sub generate_random_filename {
for ($a=0; $a <= 2500; $a++) {
    $rval = rand(74);
    $rval = $rval + 48;
    $rval = sprintf("%.0f", $rval);
    $rval = chr($rval);
    $RandPhile = $RandPhile.$rval;
    $RandPhile =~ tr/A-Za-z0-9/ /cs;
    $RandPhile =~ s/A//gi;
    $RandPhile =~ s/E//gi;
    $RandPhile =~ s/I//gi;
    $RandPhile =~ s/O//gi;
    $RandPhile =~ s/U//gi;
    $RandPhile =~ s/ //g;
    if (length($RandPhile) > 11) {
      $RandPhile =~ tr/A-Z/a-z/;
      return;
    }
}
}
#--------------------------------------------------------------------------------

sub get_upload_files {
  $tokenphile = $imgroot.$TokenKey.".tmp";
  open (OUTFILE, ">$tokenphile");
  print OUTFILE $TokenKey;
  close (OUTFILE);
  chmod(0777,$tokenphile);

  use CGI; 
  my $req = new CGI; 
  my $file = $req->param("FILE1"); 
  my $fileName = $file;
  $fileName =~ s!^.*(\\|\/)!!;
  $fileName =~ tr/A-Z/a-z/;

  if ((index($fileName,".jpg") < 1) && (index($fileName,".jpeg") < 1) && (index($fileName,".jpe") < 1) && (index($fileName,".gif") < 1) && (index($fileName,".png") < 1)) {
    $StatusMessage = "2|'<b>$fileName</b>' is not a JPEG, GIF or PNG image! Only JPEG, GIF or PNG format images are accepted!";
    $PageTitle = "Upload Error";
    $page = "image_error";
    unlink $tokenphile;
    &print_html;
  }
  if (index($fileName,".png") > -1) { $FileExt = ".png"; }
  elsif (index($fileName,".gif") > -1) { $FileExt = ".gif"; }
  else { $FileExt = ".jpg"; }
  
  $outphile = $imgroot."source/".$fileName;
  
  open (OUTFILE, ">$outphile"); 
  binmode(OUTFILE, ":raw");
  while (my $bytesread = read($file, my $buffer, 1024)) { 
    print OUTFILE $buffer; 
  }
  close (OUTFILE); 

  chmod(0777,$outphile);
  use Image::Size;
  ($globe_x, $globe_y) = imgsize("$outphile");

  ($FileSize, $filedate, $perm) = (stat($outphile))[7, 9, 2];
  $perm = sprintf "%lo", ($perm & 07777);
  $FileSize = $FileSize/1024;
  $FileSize = sprintf("%.2f",$FileSize);

  $sql_statement = "SELECT ImageId FROM media_images WHERE OriginalPhile = '$fileName';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement");
  @arr = $sth->fetchrow;
  ($ImageId) = @arr;
  
  if ($ImageId eq "") { $sql_statement = "INSERT INTO media_images VALUES ('','1','$TimeStamp','$FolderName','$fileName','$fileName','$FileSize','$globe_x','$globe_y');"; }
  else { $sql_statement = "UPDATE media_images SET TimeStamp = '$TimeStamp',PhileSize = '$FileSize',PhileX = '$globe_x',PhileY = '$globe_y' WHERE ImageId = '$ImageId';"; }
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement");
  
  $FullFileDetail = "File Name: $fileName [$fileName]<br>File Size: ".$FileSize." Kb<br>Dimensions: ".$globe_x." x ".$globe_y." (WxH pixels)";
  $ThumbName = $fileName;
  $FullName = $fileName;
  $ThumbWidth = "100";
  $ThumbHeight = "100";
  $OrderCode = $fileName;
  $OrderCode =~ s/$FileExt//gi;
  
  if ($globe_x > 400) {
    $ResizeFactor = 400/$globe_x;
    $FullHeight = $ResizeFactor * $globe_y;
    $FullHeight = sprintf("%.0f",$FullHeight);
    $FullWidth = "400";
    $FullFileDetail = "<b>Image has been resized!</b><br>".$FullFileDetail;
  }
  else {
    $FullHeight = $globe_y;
    $FullWidth = $globe_x;
  }

  #sleep(20);
  unlink $tokenphile;

  $PageTitle = "Upload Product Images";
  $page = "gallery_complete";
  &print_html;
}

#--------------------------------------------------------------------------------------------------------------
sub print_html {

print "Content-type: text/html\n\n";
print "<!--$outphile : $fileName : $newmain : $globe_x,$globe_y \n $TestString-->\n";
if ($AlertPrompt ne "") { $AlertPrompt = "\nwindow.alert(\"".$AlertPrompt."\");"; }
if ($StatusMessage ne "") {
  ($StatusType,$StatusMessage) = split(/\|/,$StatusMessage);
  if ($StatusType eq "0") { $StatusMessage = "<span class=\"StatusOk\"><img src=\"../images/status_ok.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</span>"; }
  if ($StatusType eq "1") { $StatusMessage = "<span class=\"StatusAlert\"><img src=\"../images/status_alert.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</span>"; }
  if ($StatusType eq "2") { $StatusMessage = "<span class=\"StatusStop\"><img src=\"../images/status_stop.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</span>"; }
}

$template = $docroot.$page.".html";	
open (INPHILE, "<$template");
@indata = <INPHILE>;
close(INPHILE);

foreach $line(@indata) {
	$line =~ s/_UID_/$uid/g;
	$line =~ s/_PRODID_/$ProdId/g;
	$line =~ s/_ORDERCODE_/$OrderCode/g;
	$line =~ s/_ALERT_PROMPT_/$AlertPrompt/g;
	$line =~ s/_PAGEHEADER_/$PageTitle/g;
	$line =~ s/_FULLDETAIL_/$FullFileDetail/g;
	$line =~ s/_THUMBDETAIL_/$ThumbFileDetail/g;
	$line =~ s/_STAT_MSG_/$StatusMessage/g;

	$line =~ s/_THUMBWIDTH_/$ThumbWidth/g;
	$line =~ s/_THUMBHEIGHT_/$ThumbHeight/g;
	$line =~ s/_THUMBNAME_/$ThumbName/g;
	$line =~ s/_FULLWIDTH_/$FullWidth/g;
	$line =~ s/_FULLHEIGHT_/$FullHeight/g;
	$line =~ s/_FULLNAME_/$FullName/g;
  $line =~ s/_PRODIMAGE_/$ViewProdImage/g;
  $line =~ s/_TIMESTAMP_/$TimeStamp/g;
  $line =~ s/_CREDITTEXT_/$CreditText/g;
  $line =~ s/_INSTRUCT_TEXT_/$InstructText/g;
  $line =~ s/_PARENT_LINK_/$referer/g;
  $line =~ s/_FOLDERNAME_/$FolderName/g;
  $line =~ s/_FILEEXT_/$FileExt/g;

	print "$line";
}
exit;
}

#--------------------------------------------------------------------------------------------------------------
#sub lock {
#  local($file)=@_;
  #flock($file, $LOCK_EX);
#}

#---------------------------------------------------------------------------------------------------------------------------
#sub unlock {
#  local($file)=@_;
  #flock($file, $LOCK_UN);
#}
#--------------------------------------------------------------------------------------------------------------
