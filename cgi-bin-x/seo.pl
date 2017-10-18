#!/usr/bin/perl

require "config.pl";

#$docroot = "/home/one23ale/public_html/en/";
$indexroot = "/hsphere/local/home/carbs/toner.co.za/en/";
$xmlphile = "/hsphere/local/home/carbs/toner.co.za/sitemap.xml";

$IndexList = $IndexList."<br><b>Brands...</b><br><br>\n";

$sql_statement = "SELECT MfId,MfCode,MfName FROM brand_base ORDER BY MfName;";
$sth = $dbh->query($sql_statement);
while (@arr = $sth->fetchrow) {
	($MfId,$MfCode,$MfName) = @arr;
	$outphile = $indexroot.$MfCode."b.shtml";
	open (OUTPHILE2, ">$outphile");
	print OUTPHILE2 "\n<!--#include virtual=\"../cgi-bin/index.pl?fn=spbrand&br=$MfCode&mct=100&sct=100&pct=0&uid=\"-->\n";
	close (OUTPHILE2);
	chmod(0777,$outphile);
  $IndexList = $IndexList."<a href=\"".$MfCode."b.shtml\"><b>$MfName</b></a><br>\n";
  $XmlList = $XmlList."\t<url>\n\t\t<loc>http://www.toner.co.za/cgi-bin/index.pl?fn=spbrand&amp;br=$MfCode&amp;mct=100&amp;sct=100&amp;pct=0&amp;uid=</loc>\n\t\t<changefreq>weekly</changefreq>\n\t</url>\n";
  
}

$IndexList = $IndexList."<br><b>Categories...</b><br><br>\n";

$sql_statement = "SELECT * FROM cat_base WHERE Level1 != '100' ORDER BY Level1,CatName;";
$sth = $dbh->query($sql_statement);
while (@arr = $sth->fetchrow) {
	($CatId, $Level1, $Level2, $Level3, $CatName, $CatImage, $CatDescript) = @arr;
	push(@cats,"$CatId|$Level1|$Level2|$Level3|$CatName|$CatImage|$CatDescript");
}

foreach $Temp(@cats) {
	($CatId, $Level1, $Level2, $Level3, $CatName) = split(/\|/,$Temp);
	$outphile = $indexroot.$CatId."c.shtml";
	open (OUTPHILE2, ">$outphile");
	print OUTPHILE2 "\n<!--#include virtual=\"../cgi-bin/index.pl?fn=spmain&mct=$Level1&sct=$Level2&pct=0&uid=\"-->\n";
	close (OUTPHILE2);
	chmod(0777,$outphile);
  $IndexList = $IndexList."<a href=\"".$CatId."c.shtml\"><b>$CatName</b></a><br>\n";

	$sql_statement = "SELECT * FROM prod_base WHERE Level1 = '$Level1' AND Level2 = '$Level2' AND ProdFlag = '1' ORDER BY ProdName;";
	$sth = $dbh->query($sql_statement);
	while (@arr = $sth->fetchrow) {
		($ProdId, $OrderCode, $MfId, $Level1, $Level2, $Level3, $Model, $ProdName) = @arr;
		$outphile = $indexroot.$ProdId."p.shtml";
		open (OUTPHILE2, ">$outphile");
		print OUTPHILE2 "\n<!--#include virtual=\"../cgi-bin/index.pl?fn=spbrand&br=$MfId&mct=$Level1&sct=$Level2&pct=0&st=view&pid=$ProdId&uid=\"-->\n";
		close (OUTPHILE2);
		chmod(0777,$outphile);
  	$IndexList = $IndexList."&#149; <a href=\"".$ProdId."p.shtml\">$OrderCode : $ProdName</a><br>\n";
  	$XmlList = $XmlList."\t<url>\n\t\t<loc>http://www.toner.co.za/cgi-bin/index.pl?fn=spbrand&amp;br=$MfId&amp;mct=$Level1&amp;sct=$Level2&amp;pct=0&amp;st=view&amp;pid=$ProdId&amp;uid=</loc>\n\t\t<changefreq>weekly</changefreq>\n\t</url>\n";
	}
}

open (OUTPHILE2, ">$xmlphile");
print OUTPHILE2 "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.google.com/schemas/sitemap/0.84\">\n".$XmlList."</urlset>\n";
close (OUTPHILE2);
chmod(0777,$xmlphile);

$PageTitle = "www.toner.co.za : Document Index (Site Map)";
&print_html;

#--------------------------------------------------------------------------------------------------------------
sub print_html {

$template = $docroot."seo.html";
print "Content-type: text/html\n\n<!--blah:$template-->\n";

open (INPHILE, "<$template");
@indata = <INPHILE>;
close(INPHILE);

foreach $line(@indata) {
	$line =~ s/_INDEXLIST_/$IndexList/g;  
	print "$line";
}
exit;
}

#--------------------------------------------------------------------------------------------------------------
