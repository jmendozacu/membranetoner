#!/usr/bin/perl

#-----------------------------------------------------

print "Content-type: text/html\n\n";
print "<table width=\"500\" border=\"0\" align=\"center\" cellpadding=\"0\" cellspacing=\"3\">\n";
require "config.pl";

$BackupPhile = $docroot."price_update.sql";
open (OUTPHILE, ">$BackupPhile");


$sql_statement = "SELECT ProdId,RetailPrice FROM prod_base WHERE RetailPrice > '0';";
$sth = $dbh->query($sql_statement);
while (@arr = $sth->fetchrow) {
	($ProdId,$RetailPrice) = @arr;
	$Temp = $ProdId."|".$RetailPrice;
	push(@prices,$Temp);
}

foreach $Temp(@prices) {
	($ProdId,$RetailPrice) = split(/\|/,$Temp);
	print OUTPHILE "UPDATE prod_base SET RetailPrice = '$RetailPrice' WHERE ProdId = '$ProdId';\n";
	print "<tr><td>$ProdId</td><td>$RetailPrice</td><td>";
	$AddTen = $RetailPrice * 0.12;
	$RetailPrice = $RetailPrice + $AddTen;
	$RetailPrice = sprintf("%.2f",$RetailPrice);
	print "$AddTen</td><td>$RetailPrice</td></tr>\n";
	$sql_statement = "UPDATE prod_base SET RetailPrice = '$RetailPrice' WHERE ProdId = '$ProdId';";
	$sth = $dbh->query($sql_statement);
	
}
print "</table>\n";
close(OUTPHILE);
