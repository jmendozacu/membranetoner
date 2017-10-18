#!/usr/bin/perl

print "Content-type: text/html\n\n";
print "start<br>";

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

#=================================================================================

if ($func eq "upload") { &get_upload_files; }
elsif ($func eq "view") { &view_image_files; }
else { &show_upload_form; }

exit;

#--------------------------------------------------------------------------------
sub show_upload_form {
  print "form<br>";
  $ProdImage = $OrderCode.".jpg";
  $ImagePath = $ThumbNailPath.$OrderCode.".jpg";
  if (-e $ImagePath) {
    $ViewProdImage = $ProdImage;
    $outphile = $imgroot."full/".$OrderCode.".jpg";
    #use Image::Size;
    #($globe_x, $globe_y) = imgsize("$outphile");
    ($FileSize, $filedate, $perm) = (stat($outphile))[7, 9, 2];
    $perm = sprintf "%lo", ($perm & 07777);
    $FileSize = $FileSize/1024;
    $FileSize = sprintf("%.2f",$FileSize);
    $FullFileDetail = "File Name: ".$OrderCode.".jpg<br>File Size: ".$FileSize." Kb<br>Dimensions: ".$globe_x." x ".$globe_y." (WxH pixels)";
    
  } else { $ViewProdImage = "none.gif"; }

  $PageTitle = "Upload Product Images";
  $page = "image_upload";
  &print_html;
}

#--------------------------------------------------------------------------------

sub view_image_files {

  $ProdImage = $OrderCode.".jpg";
  $ImagePath = $ThumbNailPath.$OrderCode.".jpg";
  if (-e $ImagePath) {
    $ViewProdImage = $ProdImage;
    $outphile = $imgroot."full/".$OrderCode.".jpg";
    #use Image::Size;
    #($globe_x, $globe_y) = imgsize("$outphile");
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

sub get_upload_files {

  use CGI; 
  my $req = new CGI; 
  my $file = $req->param("FILE1"); 
  my $fileName = $file;
  $TestString = $TestString.$fileName."|";
  $fileName =~ s!^.*(\\|\/)!!;
  $fileName =~ tr/A-Z/a-z/;
  $TestString = $TestString.$fileName."|";

  if ((index($fileName,".jpg") < 1) && (index($fileName,".jpeg") < 1) && (index($fileName,".jpe") < 1) && (index($fileName,".gif") < 1) && (index($fileName,".png") < 1)) {
    $AlertPrompt = "Upload Error: '$fileName' is not a JPEG, GIF or PNG image!\\nOnly JPEG, GIF or PNG format images are accepted!";
    &show_upload_form;
  }
  if (index($fileName,".png") > -1) { $FileExt = ".png"; }
  elsif (index($fileName,".gif") > -1) { $FileExt = ".gif"; }
  else { $FileExt = ".jpg"; }
  
  $outphile = $imgroot."source/".$OrderCode.$FileExt;
  open (OUTFILE, ">$outphile"); 
  binmode(OUTFILE, ":raw");
  while (my $bytesread = read($file, my $buffer, 1024)) { 
    print OUTFILE $buffer; 
  }
  close (OUTFILE); 

  chmod(0777,$outphile);
  #use Image::Size;
  #($globe_x, $globe_y) = imgsize("$outphile");

  ($FileSize, $filedate, $perm) = (stat($outphile))[7, 9, 2];
  $perm = sprintf "%lo", ($perm & 07777);
  $FileSize = $FileSize/1024;
  $FileSize = sprintf("%.2f",$FileSize);
  
  $FullFileDetail = "File Name: ".$OrderCode.$FileExt." [$fileName]<br>File Size: ".$FileSize." Kb<br>Dimensions: ".$globe_x." x ".$globe_y." (WxH pixels)";
  $ThumbName = $OrderCode.$FileExt;
  $FullName = $OrderCode.$FileExt;
  $ThumbWidth = "100";
  $ThumbHeight = "100";
  
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
  
  $sql_statement = "UPDATE prod_base SET ProdImage = '$ThumbName' WHERE ProdId = '$ProdId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement");


  $PageTitle = "Upload Product Images";
  $page = "image_complete";
  &print_html;
}

#--------------------------------------------------------------------------------------------------------------
sub print_html {

print "Content-type: text/html\n\n";
print "<!--$outphile : $fileName : $newmain : $globe_x,$globe_y \n $TestString-->\n";
if ($AlertPrompt ne "") { $AlertPrompt = "\nwindow.alert(\"".$AlertPrompt."\");"; }
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

	$line =~ s/_THUMBWIDTH_/$ThumbWidth/g;
	$line =~ s/_THUMBHEIGHT_/$ThumbHeight/g;
	$line =~ s/_THUMBNAME_/$ThumbName/g;
	$line =~ s/_FULLWIDTH_/$FullWidth/g;
	$line =~ s/_FULLHEIGHT_/$FullHeight/g;
	$line =~ s/_FULLNAME_/$FullName/g;
  $line =~ s/_PRODIMAGE_/$ViewProdImage/g;
  $line =~ s/_TIMESTAMP_/$TimeStamp/g;
  $line =~ s/_CREDITTEXT_/$CreditText/g;


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
