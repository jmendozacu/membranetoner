#!/usr/bin/perl

#-----------------------------------------------------
#use Time::HiRes qw( gettimeofday tv_interval );;

#$t0 = [gettimeofday];
#($seconds, $microseconds) = gettimeofday;
#$StartTime = $seconds.".".$microseconds;
#$MachTime = time;
#-----------------------------------------------------

require "config.pl";

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
  $value =~ s/\'/\\'/g;
  $value =~ s/\"/\\"/g; 
  $value =~ s/\,/\\,/g; 
  $form{$name} .= "\0" if (defined($form{$name}));
  $form{$name} .= "$value";
  $LogPhorm = $LogPhorm."$name:$value\n";
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
$tst = $info{'test'};

$uid = $info{'u'};
$func = $info{'f'};
$CLevel1 = $info{'c'};
$BrandId = $info{'b'};


#--------------------------------------------------------------------------------------------------------------
#-Check for XML requirements

print "Content-type: application/xml\n\n<?xml version=\"1.0\" standalone=\"yes\"?>\n";
print "<ROOT>\n";
if (($CLevel1 > 100) && ($CLevel1 < 1000)) { $sql_statement = "SELECT ProdId FROM prod_base WHERE Level1 = '$CLevel1' AND ProdFlag = '1' ORDER BY ProdId;"; }
elsif ($CLevel1 eq "featured") { $sql_statement = "SELECT ProdId FROM prod_base WHERE ProdFlag = '1' AND SpecFlag = '1' ORDER BY ProdId;"; }
else { $sql_statement = "SELECT ProdId FROM prod_base WHERE ProdFlag = '1' ORDER BY ProdId;"; }

push(@debugstring,"SQL||$sql_statement");
$sth = $dbh->query($sql_statement);
while (@arr = $sth->fetchrow) {
  ($ProdId) = @arr;
  push(@prods,$ProdId);
}
foreach $ProdId(@prods) {
  $sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId' LIMIT 0,1;";
  $sth = $dbh->query($sql_statement);
  @arr = $sth->fetchrow;
  ($ProdId, $OrderCode, $BrandId, $CLevel1, $CLevel2, $CLevel3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize) = @arr;

  $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
  push(@debugstring,"SQL||$sql_statement");
  $sth = $dbh->query($sql_statement);
  @arr = $sth->fetchrow;
  $CatName = @arr[0];
  $ProdKeys = $CatName." ".$ProdName;
  $ProdKeys =~ tr/a-zA-Z0-9/ /cs;
  $ProdKeys =~ s/  / /g;
  $ProdKeys =~ s/  / /g;
  $ProdKeys =~ s/  / /g;
  $ProdKeys =~ s/ /\,/g;
  $ProdName =~ s/\&/\&amp;/gi;
  $FeatureSumm =~ s/\&/\&amp;/gi;
  $FeatureText =~ s/\&/\&amp;/gi;

	if ($ProdImage eq "") { $ProdImage = $OrderCode.".jpg"; }
	$ImagePath = $FullImagePath.$ProdImage;
	if (-e $ImagePath) { $SetProdImage = "http://www.toner.co.za/user/full/".$ProdImage; } else { $SetProdImage = ""; }

  $RetailTotal = $RetailPrice * $VatRate;
  $RetailTotal = $RetailTotal + $RetailPrice;
  $RetailTotal = sprintf("%.2f",$RetailTotal);
  
	print "\t<Products>\n";
	print "\t\t<ProductCode>$OrderCode</ProductCode>\n";
	print "\t\t<ProductName>$ProdName</ProductName>\n"; 
	print "\t\t<ProductDescription>$FeatureSumm</ProductDescription>\n";
	if ($info{'d'} eq "1") { print "\t\t<ProductLongDescription>$FeatureText</ProductLongDescription>\n"; }
  else { print "\t\t<ProductLongDescription></ProductLongDescription>\n"; }
	print "\t\t<Brand>$CatName</Brand>\n";
	print "\t\t<Price>$RetailTotal</Price>\n";
	print "\t\t<StockLevel>In Stock</StockLevel>\n";
	print "\t\t<Category1>Office Supplies</Category1>\n";
	print "\t\t<OnSpecial>false</OnSpecial>\n";
	print "\t\t<SpecialPrice>0</SpecialPrice>\n";
	print "\t\t<SpecialStartDate></SpecialStartDate>\n";
	print "\t\t<SpecialEndDate></SpecialEndDate>\n";
	print "\t\t<ProductURL>http://www.toner.co.za/cgi-bin/index.pl?fn=buy&amp;pid=$ProdId</ProductURL>\n";
	print "\t\t<PreOrderItem>false</PreOrderItem>\n";
	print "\t\t<ReleaseDate></ReleaseDate>\n";
	print "\t\t<ProductKeywords>$ProdKeys</ProductKeywords>\n";
	print "\t\t<ImageURL>$SetProdImage</ImageURL>\n";
	print "\t\t<AltImageURL></AltImageURL>\n";
	print "\t\t<GalleryURL1></GalleryURL1>\n";
	print "\t\t<GalleryURL2></GalleryURL2>\n";
	print "\t\t<GalleryURL3></GalleryURL3>\n";
	print "\t\t<GalleryURL4></GalleryURL4>\n";
	print "\t\t<GalleryURL5></GalleryURL5>\n";
  print "\t</Products>\n";
  
}
print "</ROOT>\n\n";
exit;





#--------------------------------------------------------------------------------------------------------------

sub generate_random_string {

for ($a=0; $a <= 2500; $a++) {
	$rval = rand(74);
	$rval = $rval + 48;
	$rval = sprintf("%.0f", $rval);
	$rval = chr($rval);
	$uid = $uid.$rval;
	$uid =~ tr/A-Za-z0-9/ /cs;
	$uid =~ s/ //g;
	if (length($uid) > 10) { return; }
}
}

#--------------------------------------------------------------------------------------------------------------

