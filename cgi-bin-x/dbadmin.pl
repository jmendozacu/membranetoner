#!/usr/bin/perl

#print "Content-type: text/html\n\n";

$CreditText = "Powered by <b>W3Mall</b> Version 2.01 ©2003-2006 <a href=\"http://www.w3b.co.za/\">W3b.co.za</a>. All rights reserved.";

#-----------------------------------------------------
#use GD::Graph::pie;
use Time::HiRes qw( gettimeofday tv_interval );;

$t0 = [gettimeofday];
($seconds, $microseconds) = gettimeofday;
$StartTime = $seconds.".".$microseconds;

require "admconfig.pl";

&load_system_variables;

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
  $value =~ s/\'/\\'/g;
  $value =~ s/\"/\\"/g; 
  $value =~ s/\,/\\,/g; 
  $form{$name} .= "\0" if (defined($form{$name}));
  $form{$name} .= "$value";
  push(@debugstring,"FORM: $name||$value");
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

#--------------------------------------------------------------------------------------------------------------
#-Parse Info string

$page = $info{'page'};
$func = $info{'f'};
$step = $info{'s'};
$uid = $info{'u'};
$RedFlag = $form{'RedFlag'};
$QueryStringRep = $ENV{QUERY_STRING};
$QueryStringRep =~ s/$uid//gi;
$OffSet = $info{'fs'};
$OrderBy = $info{'ord'};
$OrderRange = $info{'rng'};
$CLevel1 = $info{'mct'};
$CLevel2 = $info{'sct'};
$CLevel3 = $info{'pct'};
$BrandId = $info{'br'};
$ProdId = $info{'pid'};
$BuyerId = $info{'bid'};
$ResId = $info{'rid'};
if ($CLevel2 < 100) { $CLevel2 = "100"; }

if ($OffSet eq "") { $OffSet = "0"; }

#--------------------------------------------------------------------------------------------------------------
#- Get Cookies

use CGI;
$query = new CGI;
$LastView = $query->cookie('tonLastView');
$query = new CGI;
$SessionCid = $query->cookie('tonAdSessionCid');
$query = new CGI;
$FirstVisit = $query->cookie('tonFirstVisit');
$query = new CGI;
$RemString = $query->cookie('tonRemString');
$query = new CGI;
$uid = $query->cookie('tonAdUniqueId');
$query = new CGI;
$LastSearchTerm = $query->cookie('tonLastSearch');
$query = new CGI;
$ClearSession = $query->cookie('tonClearSession');

push(@debugstring,"R COOKIE: tonLastView||$LastView");
push(@debugstring,"R COOKIE: tonAdSessionCid||$SessionCid");
push(@debugstring,"R COOKIE: tonFirstVisit||$FirstVisit");
push(@debugstring,"R COOKIE: tonRemString||$RemString");
push(@debugstring,"R COOKIE: tonAdUniqueId||$uid");
push(@debugstring,"R COOKIE: tonLastSearch||$LastSearchTerm");
push(@debugstring,"R COOKIE: tonClearSession||$ClearSession");


#--------------------------------------------------------------------------------------------------------------
#- Test timeout frames

if (length($ENV{QUERY_STRING}) < 2) {
    $PageHeader = "Administrators Login";
    $page = "admin_login";
    &display_page_requested;
}

#--------------------------------------------------------------------------------------------------------------
#- Test session valid

if ($func eq "login") {
    $AttCount = $form{'AttCount'};
    $TestUser = $form{'UserName'};
    $TestPass = $form{'PassWord'};
    $TestString = $TestUser."|".$TestPass;
    if ((length($TestUser) < 2) || (length($TestPass) < 2)) {
        $AlertPrompt = "Invalid Username and/or Password entered!\\nPlease try again.";
        $EventTrap = "1000";
        $AttCount++;
        $PageHeader = "Administrators Login";
        $page = "admin_login";
        &display_page_requested;
    }
    $sql_statement = "SELECT * FROM admin_users WHERE UserName = '$TestUser' AND PassWord = '$TestPass' LIMIT 0,1;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($UserId, $AdminLevel, $UserName, $PassWord, $IpMask, $ExpireDate, $FirstName, $SurName, $EmailAddy) = @arr;
    if ($UserId eq "") {
        $AlertPrompt = "Invalid Username and/or Password entered!\\nPlease try again.";
        $EventTrap = "1000";
        $AttCount++;
        $PageHeader = "Administrators Login";
        $page = "admin_login";
        &display_page_requested;
    }
    else {
        &generate_random_code;
        $uid = $SessId.$UserId;
        $ExpireTime = time;
        &resolve_host_name;
        $sql_statement = "INSERT INTO admin_session VALUES ('','$SessId','$UserId','$ExpireTime','$current_user');";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        $sql_statement = "DELETE FROM admin_session WHERE SessionId != '$SessId' AND UserId = '$UserId';";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        $AccessType = "1";
        $func = "home";
    }
}
elsif ($func eq "logout") {
  $SessId = substr($uid,0,12);
  $UserId = substr($uid,-5,5);
  $sql_statement = "DELETE FROM admin_session WHERE SessionId = '$SessId' AND UserId = '$UserId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  $uid = "";
  $PageHeader = "Administrators Login";
  $page = "admin_login";
  &display_page_requested;
}
else {
    $SessId = substr($uid,0,12);
    $UserId = substr($uid,-5,5);
    $sql_statement = "SELECT ExpireTime,SessionIP FROM admin_session WHERE SessionId = '$SessId' AND UserId = '$UserId';";
    $test_sql = $sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($ExpireTime,$HitHost) = @arr;
    $now_time = time;
    $TestExpire = $now_time - $ExpireTime;
    if ($TestExpire > 90000) {
        $AlertPrompt = "Your user session has expired!\\nPlease login again.";
        $page = "admin_login";
        $uid = "";
        &display_page_requested;
    }
    else {
        $sql_statement = "UPDATE admin_session SET ExpireTime = '$now_time' WHERE SessionId = '$SessId' AND UserId = '$UserId';";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        $sql_statement = "SELECT * FROM admin_users WHERE AdminId = '$UserId' LIMIT 0,1;";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        @arr = $sth->fetchrow;
        ($UserId, $AdminLevel, $UserName, $PassWord, $IpMask, $ExpireDate, $FirstName, $SurName, $AdminEmailAddy) = @arr;
        $LoginFlag = "1";
    }
}

sub generate_random_code {
for ($a=0; $a <= 2500; $a++) {
    $rval = rand(74);
    $rval = $rval + 48;
    $rval = sprintf("%.0f", $rval);
    $rval = chr($rval);
    $SessId = $SessId.$rval;
    $SessId =~ tr/A-Za-z0-9/ /cs;
    $SessId =~ s/A//gi;
    $SessId =~ s/E//gi;
    $SessId =~ s/I//gi;
    $SessId =~ s/O//gi;
    $SessId =~ s/U//gi;
    $SessId =~ s/ //g;
    if (length($SessId) > 11) { return; }
}
}

#--------------------------------------------------------------------------------------------------------------
#-Function Calls
$SearchKey = "- OrderCode/Keyword -";
$SearchKey2 = "- Keyword -";

if ($func eq "home") { &display_admin_home; }
#------
#------
elsif ($func eq "config") { &display_config_function; }
elsif ($func eq "reseller") { &display_resellers_page; }
elsif ($func eq "affils") { &display_affiliates_page; }
elsif ($func eq "prods") { &display_products_page; }
elsif ($func eq "cats") { &display_category_page; }
elsif ($func eq "buyer") { &display_buyers_page; }
elsif ($func eq "report") { &display_under_construct; }
elsif ($func eq "order") { &display_orders_page; }
elsif ($func eq "access") { &display_under_construct; }
elsif ($func eq "backup") { &display_under_construct; }
elsif ($func eq "config") { &display_under_construct; }
elsif ($func eq "support") { &display_under_construct; }
elsif ($func eq "forex") { &display_forex_page; }
elsif ($func eq "system") { &display_system_info; }
elsif ($func eq "links") { &display_links_info; }
elsif ($func eq "mpay") { &display_payment_info; }
elsif ($func eq "deliver") { &fetch_delivery_options; }
elsif ($func eq "luser") { &display_user_settings; }
elsif ($func eq "runfix") { &run_db_fix; }
elsif ($func eq "image") { &fetch_gallery_manager; }
elsif ($func eq "content") { &fetch_content_manager; }
elsif ($func eq "resinvoice") { &fetch_reseller_invoice; }
elsif ($func eq "custinvoice") { &fetch_customer_invoice; }
#----
else { $page = "admin_login"; &display_page_requested; }
exit;

#--------------------------------------------------------------------------------------------------------------
sub run_db_fix {
  $StatusMessage = "1|Update Complete";
  $func = "home";
  &display_admin_home;
}

#--------------------------------------
sub fetch_reseller_invoice {
  $OrderId = $info{'oi'};
  $InvoiceNumber = $info{'iv'};

  $sql_statement = "SELECT * FROM reseller_order WHERE OrderId = '$OrderId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($XOrderId, $OrderStat, $PayOption, $ResId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderNumber, $DeliverOption, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $DeliveryAddress, $InvoiceNumber, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
  $DeliveryAddress =~ s/\n/<br>/g;
  #if ($PayOption eq "CC") { $page = "invoice_full"; } else { $page = "invoice_proforma"; }

	&convert_timestamp($XTimeStamp);
	$InvoiceDate = $ConvTimeDate;
	$sql_statement = "SELECT SafePayRefNr,BankRefNr,BuyerCreditCardNr FROM safe_shop WHERE TransactId = '$TransactId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($SafePayRefNr, $BankRefNr, $BuyerCreditCardNr) = @arr;
	$sql_statement = "SELECT * FROM reseller_details WHERE ResId = '$ResId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($XResId, $StatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $DiscountRate, $AcceptTerms, $AccountNumber, $BusinessDescript) = @arr;

	$sql_statement = "SELECT * FROM reseller_items WHERE OrderId = '$OrderId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	while (@arr = $sth->fetchrow) {
	  ($ItemId, $XResId, $XOrderId, $TimeStamp, $Level1, $Level2, $Level3, $ProdId, $OrderCode, $ProdName, $OrderQty, $OrderPrice, $OrderWeight, $DelCharge, $ItemFlag) = @arr;
	  $ItemTotal = $OrderPrice * $OrderQty;
	  $ItemTotal = sprintf("%.2f",$ItemTotal);
	  $InvoiceString = $InvoiceString."<tr>\n <td class=\"dotborderlg\">&nbsp;$OrderCode</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\">&nbsp;$ProdName</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" align=\"center\">$OrderQty</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" align=\"right\">$OrderPrice&nbsp;</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlgsh\" align=\"right\">$ItemTotal&nbsp;</td>\n</tr>\n";
	}
	
	$sql_statement = "SELECT OptionName,DeliverTime,DeliverMax FROM deliver_options WHERE DelId = '$DeliverOption';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
	($OptionName,$DeliverTime,$DeliverMax) = @arr;
	$EstDeliver = $XTimeStamp + $DeliverMax;
	&convert_timestamp($EstDeliver);
	$EstDeliver = $ConvTimeStampShort;
  
	$sql_statement = "SELECT VarText FROM system_variables WHERE VarGroup = '99';";
  $sth = $dbh->query($sql_statement);
  @arr = $sth->fetchrow;
	$VarText = @arr[0];
	($CsImage,$CsName,$CsVatNum,$CsRegNum,$CsPostal,$CsPhysical,$CsTele,$CsFax,$CsEmail,$CsUrl,$CsUrlEx,$CsBank,$CsSlogan) = split(/\|/,$VarText);

  $page = "reseller_invoice";
  $PageTitle = "Invoice : $InvoiceNumber";
  &display_page_requested;
}

sub fetch_customer_invoice {
  $OrderId = $info{'oi'};
  $InvoiceNumber = $info{'iv'};
  $BuyerId = $info{'byd'};

  $sql_statement = "SELECT * FROM order_main WHERE OrderId = '$OrderId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($XOrderId, $OrderStat, $PayOption, $BuyerId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderWeight, $OptionDel, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNumber, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
  #($XOrderId, $OrderStat, $PayOption, $ResId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderNumber, $DeliverOption, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $DeliveryAddress, $InvoiceNumber, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
  $DeliveryAddress =~ s/\n/<br>/g;
  #if ($PayOption eq "CC") { $page = "invoice_full"; } else { $page = "invoice_proforma"; }

	&convert_timestamp($XTimeStamp);
	$InvoiceDate = $ConvTimeDate;
	$sql_statement = "SELECT SafePayRefNr,BankRefNr,BuyerCreditCardNr FROM safe_shop WHERE TransactId = '$TransactId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($SafePayRefNr, $BankRefNr, $BuyerCreditCardNr) = @arr;
	$sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
  ($BuyerId, $BuyFlag, $SessionId, $SignDate, $EmailAddress, $PassWord, $Title, $FirstName, $SurName, $DateOfBirth, $TelAreaCode, $Telephone, $FaxAreaCode, $FaxNum, $CompanyName, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostalCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DelDayFrom, $DelDayTo, $VoucherCode) = @arr;
	#($XResId, $StatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $BusinessDescript) = @arr;

	$sql_statement = "SELECT * FROM order_items WHERE OrderId = '$OrderId';";
	$sth = $dbh->query($sql_statement);
	while (@arr = $sth->fetchrow) {
	  ($ItemId, $XResId, $XOrderId, $TimeStamp, $Level1, $Level2, $Level3, $ProdId, $OrderCode, $ProdName, $OrderQty, $OrderPrice, $OrderWeight, $DelCharge, $ItemFlag) = @arr;
	  $ItemTotal = $OrderPrice * $OrderQty;
	  $ItemTotal = sprintf("%.2f",$ItemTotal);
	  $InvoiceString = $InvoiceString."<tr>\n <td class=\"dotborderlg\">&nbsp;$OrderCode</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\">&nbsp;$ProdName</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" align=\"center\">$OrderQty</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" align=\"right\">$OrderPrice&nbsp;</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlgsh\" align=\"right\">$ItemTotal&nbsp;</td>\n</tr>\n";
	}
	
	$sql_statement = "SELECT OptionName,DeliverTime,DeliverMax FROM deliver_options WHERE DelId = '$DeliverOption';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
	($OptionName,$DeliverTime,$DeliverMax) = @arr;
	$EstDeliver = $XTimeStamp + $DeliverMax;
	&convert_timestamp($EstDeliver);
	$EstDeliver = $ConvTimeStampShort;
  
	$sql_statement = "SELECT VarText FROM system_variables WHERE VarGroup = '99';";
  $sth = $dbh->query($sql_statement);
  @arr = $sth->fetchrow;
	$VarText = @arr[0];
	($CsImage,$CsName,$CsVatNum,$CsRegNum,$CsPostal,$CsPhysical,$CsTele,$CsFax,$CsEmail,$CsUrl,$CsUrlEx,$CsBank,$CsSlogan) = split(/\|/,$VarText);

  $page = "customer_invoice";
  $PageTitle = "Invoice : $InvoiceNumber";
  &display_page_requested;
}


#--------------------------------------
sub fetch_content_manager {




  $PageHeader = "Content Manager";
  $page = "content_editor";
  &display_page_requested;
}

#--------------------------------------

sub display_affiliates_page {
  $SortFlag = "AffId DESC ";
  $SearchFlag = " ";
  $SortData = $info{'sd'};
  $SortType = $info{'sr'};

  if ($step eq "update") {
    $OrderId = $info{'oid'};
    $UpdateStatus = $form{'UpdateStatus'};
    $WayBillNumber = $form{'WayBillNumber'};
    $AdminComment = $form{'AdminComment'};
    $WayBillNumber =~ s/- Waybill Number -//g;
    $AdminComment =~ s/- Comments\/Reason -//g;
    $AdminComment =~ s/\cM//g;
    $AdminComment =~ s/\n/ /g;
    $sql_statement = "UPDATE affiliate_order SET DeliverDate = '$TimeStamp',OrderStat = '$UpdateStatus',WayBillNumber = '$WayBillNumber',AdminComment = 'Updated by $UserName $DateNow : $AdminComment' WHERE OrderId = '$OrderId' AND AffId = '$AffId';";
    $TestString = $TestString."\n".$sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "reshow";
    $func = "order";
    $AlertPrompt = "The status of this order has been updated successfully!";
    &display_orders_page;
  }
  
  if ($step eq "disable") {
    $sql_statement = "UPDATE affiliate_details SET StatFlag = '0' WHERE AffId = '$AffId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "view";
    $StatusMessage = "0|Reseller account '$AffId _COMPANYNAME_' has been disabled!";
  }
  if ($step eq "approve") {
    $DiscountRate = $form{'DiscountRate'};
    $sql_statement = "SELECT AccountNumber FROM reseller_details WHERE ResId = '$ResId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($XStatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $DiscountRate, $BusinessDescript) = @arr;
    
    
    
    
    $sql_statement = "SELECT AccountNum FROM account_table WHERE StatFlag = '0' LIMIT 0,1";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($XStatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $DiscountRate, $BusinessDescript) = @arr;


    $sql_statement = "UPDATE affiliate_details SET StatFlag = '3',DiscountRate = '$DiscountRate' WHERE AffId = '$AffId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "view";
    $StatusMessage = "0|Reseller account '$AffId _COMPANYNAME_' was approved successfully!";
  }
  if ($step eq "setrate") {
    $DiscountRate = $info{'dir'};
    $sql_statement = "UPDATE affiliate_details SET DiscountRate = '$DiscountRate' WHERE AffId = '$AffId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "view";
    $StatusMessage = "0|Discount Rate for Reseller account '$AffId _COMPANYNAME_' was updated successfully!";
  }
  if ($step eq "view") {
    $sql_statement = "SELECT * FROM affiliate_details WHERE AffId = '$AffId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($AffId, $XStatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $DiscountRate, $BusinessDescript) = @arr;
      $WebURL =~ s/http:\/\///gi;
    &convert_timestamp($SignDate);
    $SignDate = $ConvTimeStamp;
    if ($XStatFlag eq "1") { $Disable_1 = " class=\"DisableImage\" disabled"; $Disable_2 = $Disable_1; $ResStatus = "Not Activated"; }
    if ($XStatFlag eq "3") { $Disable_1 = " class=\"DisableImage\" disabled"; $ResStatus = "Approved"; }    
    if ($XStatFlag eq "2") { $ResStatus = "Pending Approval"; }    
    if ($XStatFlag eq "0") { $Disable_2 = " class=\"DisableImage\" disabled";$ResStatus = "Disabled"; }    
    $sql_statement = "SELECT CountryName FROM countrycodes WHERE CountryCode = '$Country'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $CountryName = @arr[0];
    $PurchaseTotal = "0";
    $sql_statement = "SELECT * FROM affiliate_order WHERE AffId = '$AffId' ORDER BY OrderId DESC;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      #($OrderId, $OrderStat, $PayOption, $BuyerId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderTotal, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $CurrencyMark, $WayBillNumber) = @arr;
      ($OrderId, $OrderStat, $PayOption, $XAffId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderNumber, $DeliverOption, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $DeliverAddress, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
      $RowCount++;
      $OrderCount = $RowCount + $OffSet;
      #if ($step eq "search") { $TableListing =~ s/$SearchKey/\<span class=\"highlightsearch\"\>$SearchKey\<\/span\>/gi; }
      if ($BgFlag eq "1") { $BgFlag = "0"; $BgColor = "#F2F2F2"; } else { $BgFlag = "1"; $BgColor = "#FFFFFF"; }
      if ($OrderStat eq "1") { $OrderStatus = "Pending"; }
      if ($OrderStat eq "2") { $OrderStatus = "Delivered"; }
      if ($OrderStat eq "3") { $OrderStatus = "On-Hold"; }
      if ($OrderStat eq "4") { $OrderStatus = "Cancelled"; }
      &convert_timestamp($XTimeStamp);
      $InvoiceDate = $ConvTimeStamp;
      if ($WayBillNumber eq "") { $WayBillNumber = "---"; }
      if ($PayOption eq "TX") { $InvoiceNum = "PF".$InvoiceNum; }
      $PurchaseTotal = $PurchaseTotal + $OrderTotal;
      $PurchaseHistory = $PurchaseHistory."<tr onmouseover=\"setPointer(this, $RowCount, 'over', '".$BgColor."', '#CCFFCC', '#FFCC99');\" onmouseout=\"setPointer(this, $RowCount, 'out', '".$BgColor."', '#CCFFCC', '#FFCC99');\" onmousedown=\"setPointer(this, $RowCount, 'click', '".$BgColor."', '#CCFFCC', '#FFCC99');\">\n ";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" class=\"ListCell\">&nbsp;".$RowCount.".</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" class=\"ListCell\">&nbsp;<a href=\"../cgi-bin/dbadmin.pl?f=order&s=reshow&oid=".$OrderId."&fs=".$OffSet."\">".$InvoiceNum."</a></td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" class=\"ListCell\">&nbsp;".$InvoiceDate."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" align=\"center\" class=\"ListCell\">".$WayBillNumber."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" align=\"right\" class=\"ListCell\">".$OrderTotal."&nbsp;</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" align=\"center\" class=\"ListCell\">".$PayOption."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" class=\"ListCell\">&nbsp;".$OrderStatus."</td>\n</tr>\n";
    }
    if ($PurchaseHistory eq "") { $PurchaseHistory = "<tr><td colspan=\"7\" class=\"ListCellCenter\">No Purchases to Display</td></tr>\n"; }
    $PurchaseTotal = sprintf("%.2f",$PurchaseTotal);
    $RateVar = "0";
    $DiscountRate = sprintf("%.1f",$DiscountRate);
    for ($a=0; $a <= 100; $a++) {
      if ($DiscountRate eq $RateVar) { $DiscRateListing = $DiscRateListing."<option value=\"$RateVar\" selected>$RateVar %</option>\n"; }
      else { $DiscRateListing = $DiscRateListing."<option value=\"$RateVar\">$RateVar %</option>\n"; }
      $RateVar = $RateVar + 0.5;
      $RateVar = sprintf("%.1f",$RateVar);
    }
    $PageHeader = "Reseller Information : $BuyerId";
    $page = "affiliate_show";
    &display_page_requested;
  }

  if ($SortType eq "sort") {
    if ($SortData eq "") { $SortData = $form{'SortOption'}; }
    ($SortBy,$SortDirect) = split(/\^/,$SortData);
    if ($SortBy eq "OrderStat") { $SearchFlag = "WHERE OrderStat = '".$SortDirect."' "; }
    else { $SortFlag = "$SortBy $SortDirect "; }
  }
  if ($SortType eq "search") {
    $SearchField = $form{'SearchField'};
    $SearchKey2 = $form{'SearchKey'};
    $SearchKey2 =~ s/- Keyword -//g;
    if (($SearchField ne "") && (length($SearchKey2) > 0)) {
      $SearchFlag = "WHERE $SearchField LIKE '%".$SearchKey2."%' ";
      $SortData = $SearchField."^".$SearchKey2;
    }
    else {
      ($SearchField,$SearchKey2) = split(/\^/,$SortData);
      $SearchFlag = "WHERE $SearchField LIKE '%".$SearchKey2."%' ";
    }
  }

  if ($step eq "summ") {
    $sql_statement = "SELECT COUNT(*) FROM affiliate_details $SearchFlag;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ResultCount = @arr[0];
    $BuyerCount = "0";

    $sql_statement = "SELECT * FROM affiliate_details ".$SearchFlag."ORDER BY ".$SortFlag."LIMIT ".$OffSet.",".$OrderDisplayLimit.";";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($AffId, $StatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $DiscountRate, $BusinessDescript) = @arr;
      $RowCount++;
      $BuyerCount = $RowCount + $OffSet;
      if ($StatFlag eq "1") { $StatusMsg = "Not Activated"; $StatusIcon = "pending.png"; }
      if ($StatFlag eq "2") { $StatusMsg = "Pending Approval"; $StatusIcon = "alert.png"; }
      if ($StatFlag eq "3") { $StatusMsg = "Approved";  $StatusIcon = "ok.png";}
      if ($StatFlag eq "0") { $StatusMsg = "Disabled";  $StatusIcon = "stop.png";}
      &convert_timestamp($SignDate);
      $SignDate = $ConvTimeDate;
      $DiscountRate = sprintf("%.1f",$DiscountRate);

      $WebURL =~ s/http:\/\///gi;
      if ($WebURL ne "") { $WebIcon = "<a href=\"http://$WebURL\" target=\"_blank\"><img src=\"../images/site_admin/www2.png\" border=\"0\"></a>"; }
      else { $WebIcon = "<a href=\"#\" class=\"DisableImage\"><img src=\"../images/site_admin/www2.png\" border=\"0\"></a>"; }

      if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
      $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$RowCount."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=reseller&s=view&rid=".$AffId."&fs=".$OffSet."\">".$AffId."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=reseller&s=view&rid=".$AffId."&fs=".$OffSet."\">".$Title." ".$FirstName." ".$SurName."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$CompanyName."</td>\n";
      #$TableListing = $TableListing." <td class=\"ListCell\">".$Country."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$SignDate."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellRight\">".$StatusMsg."</td>\n<td align=\"right\" class=\"ListCell\"><img src=\"../images/site_admin/$StatusIcon\"></td>\n <td class=\"ListCellRight\">".$DiscountRate."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><a href=\"mailto:$EmailAddress\"><img src=\"../images/site_admin/email2.png\" hspace=\"2\" border=\"0\" alt=\"$EmailAddress\"></a><a href=\"../cgi-bin/dbadmin.pl?fn=reseller&st=view&rid=".$AffId."&fs=".$OffSet."&uid=".$uid."\" onmouseover=\"ddrivetip('<div align=center>Telephone: <b>($TelArea) $Telephone</b><br>Fax: <b>($FaxArea) $FaxNum</b><br>Mobile: <b>$Mobile</b><br><br>Physical Address:<br>$PhysicalAddress<br><br>Postal Address<br>$PostalAddress</div>','#F7F7F7',300)\"; onmouseout=\"hideddrivetip()\"><img src=\"../images/site_admin/user_green.png\" hspace=\"2\" border=\"0\" alt=\"View\"></a>$WebIcon</td>\n</tr>\n";
    }
    if ($ResultCount < 1) { $TableListing = $TableListing."<tr><td class=\"ListCellCenter\" colspan=\"12\"><br><b>No records found matching your search criteria!</b><br>&nbsp;</td></tr>\n"; }
  
    $StartRecord = $OffSet + 1;
    $ResultText = "Displaying Items <b>$StartRecord</b> to <b>$OrderCount</b> of <b>$ResultCount</b> Items...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $OrderDisplayLimit;
    $OffSet = $OffSet + $OrderDisplayLimit;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $OrderDisplayLimit) { $RNavLink = $RNavLink."&laquo; <a href=\"dbadmin.pl?fn=buyer&st=summ&fs=".$PrevLink."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $OrderDisplayLimit;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ResultCount) { $RNavLink = $RNavLink."<a href=\"dbadmin.pl?fn=buyer&st=summ&fs=".$TestOffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ResultCount) { $RNavLink = $RNavLink." <a href=\"dbadmin.pl?fn=buyer&st=summ&fs=".$OffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
  }
  &populate_affiliate_options;
  $PageHeader = "Affiliate Administration";
  $page = "affiliate_view";
  &display_page_requested;

}
sub populate_affiliate_options {
    $sql_statement = "SELECT VarName,VarMax FROM system_variables WHERE VarGroup = '7'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($VarName,$VarMax) = @arr;
      if ($SearchField eq $VarName) { $SearchFieldList = $SearchFieldList."<option value=\"".$VarName."\" selected> ".$VarMax." </option>\n"; }
      else { $SearchFieldList = $SearchFieldList."<option value=\"".$VarName."\"> ".$VarMax." </option>\n"; }
    }
    $sql_statement = "SELECT VarName,VarMax FROM system_variables WHERE VarGroup = '8'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($VarName,$VarMax) = @arr;
      if ($SortData eq $VarName) { $SortOptionList = $SortOptionList."<option value=\"".$VarName."\" selected> ".$VarMax." </option>\n"; }
      else { $SortOptionList = $SortOptionList."<option value=\"".$VarName."\"> ".$VarMax." </option>\n"; }
    }
}

#--------------------------------------

sub fetch_gallery_manager {
  $FileTotal = "0";
  $FileCount = "0";
  $FolderName = $info{'ifn'};
  $ImageId = $info{'img'};
  
  if ($step eq "delete") {
    $sql_statement = "SELECT * FROM media_images WHERE ImageId = '$ImageId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($FileTotal) = @arr;
    ($XImageId, $XStatFlag, $XTimeStamp, $XFolderName, $OriginalPhile, $NewPhile, $PhileSize, $PhileX, $PhileY) = @arr;
    $sql_statement = "DELETE FROM media_images WHERE ImageId = '$ImageId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $ImagePhile = $imgroot.$XFolderName."/".$NewPhile;
    push(@debugstring,"UNLINK||$ImagePhile"); 
    unlink $ImagePhile;
    $StatusMessage = "1|Deleted Image 'NewPhile' from folder $XFolderName";
  }
  
  if ($FolderName eq "") { $step = "recent"; } else { $step = "getfolder"; }
  @folders = ('banners','brands','cats','content','products','news');
  foreach $Folder(@folders) {
    $sql_statement = "SELECT COUNT(*) FROM media_images WHERE FolderName = '$Folder';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($FileCount) = @arr;
    $sql_statement = "SELECT SUM(PhileSize) FROM media_images WHERE FolderName = '$Folder';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($FileTotal) = @arr;
    $TotalCount = $TotalCount + $FileCount;
    $FolderTotal = $FolderTotal + $FileTotal;
    if ($FileTotal eq "") { $FileTotal = "---"; }
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    if ($FolderName eq $Folder) { $BgClass = "ListStyle3"; $ResultCount = $FileCount; }
    $FolderListing = $FolderListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $FolderListing = $FolderListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=image&ifn=$Folder\"><img src=\"../images/site_admin/folder_add.png\" border=\"0\" hspace=\"2\" align=\"absmiddle\">".$Folder."/</a></td>\n";
    $FolderListing = $FolderListing." <td class=\"ListCellCenter\">$FileCount</td>\n";
    $FolderListing = $FolderListing." <td class=\"ListCellRight\">$FileTotal</td>\n</tr>";
  }
  if ($step eq "recent") {
    $UploadLink = "&nbsp;";
    $ResultCount = $TotalCount;
    $sql_statement = "SELECT * FROM media_images ORDER BY ImageId DESC LIMIT $OffSet,12;";
  }
  else {
    $UploadLink = "<a href=\"#\" onClick=\"UploadGalleryLink('$FolderName','$UserId');\">Add Images to <b>$FolderName</b><img src=\"../images/site_admin/upload.gif\" alt=\"Add images to '$FolderName'\" width=\"32\" height=\"32\" hspace=\"2\" border=\"0\" align=\"absmiddle\"></a>";
    $sql_statement = "SELECT * FROM media_images WHERE FolderName = '$FolderName' ORDER BY ImageId DESC LIMIT $OffSet,12;";
  }
  $ImageCount = $OffSet;
  $SplitFlag = "0";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($ImageId, $XStatFlag, $XTimeStamp, $XFolderName, $OriginalPhile, $NewPhile, $PhileSize, $PhileX, $PhileY) = @arr;
    $ThumbName = $NewPhile;
    $ImageCount++;
    if (index($NewPhile,".png") > -1) { $ThumbName =~ s/\.png/\.jpg/gi; }
    if (index($NewPhile,".gif") > -1) { $ThumbName =~ s/\.gif/\.jpg/gi; }
    
    &convert_timestamp($XTimeStamp);
    $TableTempListing = $TableTempListing."<td align=\"center\" class=\"ListCell\"><table width=\"100\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">\n";
    $TableTempListing = $TableTempListing."<tr>\n<td>$ImageCount</td>\n<td align=\"right\"><a href=\"javascript:AddToClipBoard('I','$ImageId');\"><img src=\"../images/site_admin/paste.png\" alt=\"Clipboard '".$ThumbName."'\" border=\"0\" hspace=\"2\" vspace=\"2\"></a><!--<a href=\"#\" onClick=\"UploadGalleryLink('$XFolderName','$uid','$ImageId');\"><img src=\"../images/site_admin/file_edit.png\" alt=\"Edit Image\" width=\"16\" height=\"16\" hspace=\"2\" vspace=\"2\" border=\"0\"></a>--><a href=\"#\" onClick=\"DeleteImage('$ImageId','$NewPhile','$FolderName','$OffSet');\"><img src=\"../images/site_admin/remove.png\" alt=\"Delete Image\" width=\"16\" height=\"16\" vspace=\"2\" border=\"0\"></a></td>\n</tr>\n";
    $TableTempListing = $TableTempListing."<tr>\n<td colspan=\"2\" align=\"center\"><a href=\"#\" onmouseover=\"ddrivetip('<div align=center><img src=../user/$XFolderName/$ThumbName vspace=2 border=1><br><b>$NewPhile</b><br>[$OriginalPhile]</div>','#F2F2F2',400)\" ;=\"\" onmouseout=\"hideddrivetip()\" class=\"ImageBorder\"><img src=\"../user/thumbs/$ThumbName\" width=\"100\" height=\"100\" border=\"1\"></a></td>\n</tr>\n";
    $TableTempListing = $TableTempListing."<tr>\n<td colspan=\"2\" align=\"center\" nowrap><span class=\"LowLightText\">$ConvTimeStamp</span><br>$PhileSize Kb<br>$PhileX x $PhileY </td>\n</tr>\n";
    $TableTempListing = $TableTempListing."</table></td>\n";  

    if ($SplitFlag eq "0") { $TableListing = $TableListing."<tr>".$TableTempListing; $SplitFlag++; }
    elsif ($SplitFlag eq "1") { $TableListing = $TableListing.$TableTempListing; $SplitFlag++; }
    elsif ($SplitFlag eq "2") { $TableListing = $TableListing.$TableTempListing; $SplitFlag++; }
    elsif ($SplitFlag eq "3") { $TableListing = $TableListing.$TableTempListing."</tr>\n"; $SplitFlag = "0"; }
    $TableTempListing = "";
  }
  if ($TableListing eq "") { $TableListing = "<tr><td colspan=\"4\"><br>No Images found in '<b>$FolderName</b>'</td></tr>\n"; }
  else {
    if ($SplitFlag eq "1") { $TableListing = $TableListing."<td>&nbsp;</td>\n<td>&nbsp;</td>\n<td>&nbsp;</td>\n</tr>\n"; }
    if ($SplitFlag eq "2") { $TableListing = $TableListing."<td>&nbsp;</td>\n<td>&nbsp;</td>\n</tr>\n"; }
    if ($SplitFlag eq "3") { $TableListing = $TableListing."<td>&nbsp;</td>\n</tr>\n"; }
  }
    
  $StartRecord = $OffSet + 1;
  $ResultText = "Displaying Items <b>$StartRecord</b> to <b>$ImageCount</b> of <b>$ResultCount</b> Items...";
  $CurrOffSet = $OffSet;
  $PrevLink = $OffSet - 12;
  $OffSet = $OffSet + 12;
  $RNavLink = "Pages";

  if ($OffSet > 12) { $RNavLink = $RNavLink."<a href=\"dbadmin.pl?f=image&s=$step&ifn=".$FolderName."&fs=".$PrevLink."\" class=\"PageLinks\">&laquo;</a> "; }
  for ($a=0; $a <= 30; $a++) {
    $TestOffSet = $a * 12;
    $LinkLoop = $a + 1;
    if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<span class=\"PageLinksSelected\"><b>$LinkLoop</b></span>\n"; }
    elsif ($TestOffSet < $ResultCount) { $RNavLink = $RNavLink."<a href=\"dbadmin.pl?f=image&s=".$step."&ifn=".$FolderName."&fs=".$TestOffSet."\" class=\"PageLinks\">$LinkLoop</a>\n"; }
  }
  if ($OffSet < $ResultCount) { $RNavLink = $RNavLink." <a href=\"dbadmin.pl?f=image&s=".$step."&ifn=".$FolderName."&fs=".$OffSet."\" class=\"PageLinks\" title=\"NextPage\">&raquo;</a>"; }
  if ($FolderName eq "") { $FolderName = "Recent Images"; }

  
  $FolderListing = $FolderListing."<tr>\n <td class=\"ListCellRight\">Total</td>\n<td class=\"ListCellCenter\">$TotalCount</td>\n <td class=\"ListCellRight\">$FolderTotal</td>\n</tr>";
  $PageHeader = "Image Gallery Manager";
  $page = "gallery_view";
  &display_page_requested;

}
#--------------------------------------
sub display_config_function {
  if ($step eq "savevars") {
    &parse_system_config;
    $sql_statement = "UPDATE system_variables SET VarText = '$CsInsert' WHERE VarName = 'InvoiceDetails';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE system_variables SET VarMax = '$FixedDelCharge' WHERE VarName = 'FixedDelCharge';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE system_variables SET VarMax = '$CurrencyMark' WHERE VarName = 'CurrencyMark';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE system_variables SET VarMax = '$VatRate' WHERE VarName = 'VatRate';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE system_variables SET VarText = '$SupportMail' WHERE VarName = 'SupportMail';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE system_variables SET VarText = '$ServiceMail' WHERE VarName = 'ServiceMail';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE system_variables SET VarText = '$InfoMail' WHERE VarName = 'InfoMail';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE system_variables SET VarText = '$SalesMail' WHERE VarName = 'SalesMail';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE system_variables SET VarText = '$MailSender' WHERE VarName = 'MailSender';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;


#  if ($VarName eq "AdminTestMode") { $TestMode = $VarMax; }
#  if ($VarName eq "AdminDebugMode") { $DebugMode = $VarMax; }
#  if ($VarName eq "DefAdminOffset") { $DefProdOffset = $VarMax; }
#  if ($VarName eq "DefSessionTime") { $DefSessionTime = $VarMax; }

    $StatusMessage = "0|The System variables where updated successfully!";
  }
  if ($step eq "edsite") {
    $PageTitle = $form{'PageTitle'};
    $PageDescript = $form{'PageDescript'};
    $PageName = $form{'PageName'};
    $PageKeys = $form{'PageKeys'};
  
    $PageDescript =~ s/\cM//g;
    $PageDescript =~ s/\n/ /g;
    $PageDescript =~ s/  / /g;
    $sql_statement = "UPDATE system_meta SET PageTitle = '$PageTitle',PageDescript = '$PageDescript',PageKeys = '$PageKeys' WHERE PageName = '$PageName';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $StatusMessage = "0|Page '$PageName' updated successfully!";
  }

  $PageCount = "0";
  $sql_statement = "SELECT * FROM system_meta WHERE StatFlag = '1' ORDER BY PageName;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($MetaId, $StatFlag, $LastUpdate, $PageName, $PageTitle, $PageDescript, $PageKeys, $PageHistory) = @arr;

  	if (length($PageTitle) > 48) {
      $LongTitle = $PageTitle;
      &shorten_text_string("$PageTitle|48");
      $PageTitle = $ShortString."...";
    }
    $DetailImage = "<a href=\"#\" onMouseOver=\"ddrivetip('<div align=left><span class=LowLightText>Page Description</span><br>$PageDescript<br><span class=LowLightText>Page Keywords</span><br>$PageKeys</div>','#F2F2F2',400)\"; onMouseOut=\"hideddrivetip()\" class=\"ImageBorder\"><img src=\"../images/site_admin/cal.png\" border=\"0\"></a>";
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    if (($XMetaId eq $MetaId) || ($PageName eq "default")) { $BgClass = "ListStyle3"; }
    $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $TableListing = $TableListing."<td class=\"ListCell\">$PageName</td>\n";
    $TableListing = $TableListing."<td class=\"ListCell\">$PageTitle &nbsp;</td>\n";
    $TableListing = $TableListing."<td class=\"ListCellCenter\">$DetailImage<a href=\"javascript:EditPageMeta('$PageCount');\"><img src=\"../images/site_admin/file_edit.png\" border=\"0\" alt=\"Edit Page Data\" hspace=\"2\"></a></td>\n</tr>\n";
  
    $PageDescript =~ s/\"/\&quot;/g;
    $PageDescript =~ s/\'/\&apos;/g;

    $JavaArray_1 = $JavaArray_1."SetPageName[$PageCount] = \"$PageName\";\n";
    $JavaArray_2 = $JavaArray_2."SetPageTitle[$PageCount] = \"$LongTitle\";\n";
    $JavaArray_3 = $JavaArray_3."SetPageDescript[$PageCount] = \"$PageDescript\";\n";
    $JavaArray_4 = $JavaArray_4."SetPageKeys[$PageCount] = \"$PageKeys\";\n";
    
    $PageCount++;
  }

  $CsPhysical =~ s/<br>/\n/g;
  $CsPostal =~ s/<br>/\n/g;
  $CsBank =~ s/<br>/\n/g;
  
  $PageHeader = "System Configuration Options";
  $page = "system_config";
  &display_page_requested;
}

sub parse_system_config {
  $CurrencyMark = $form{'setCurrencyMark'};
  $FixedDelCharge = $form{'setFixedDelCharge'};
  $VatRate = $form{'setVatRate'};
  $SupportMail = $form{'setSupportMail'};
  $ServiceMail = $form{'setServiceMail'};
  $InfoMail = $form{'setInfoMail'};
  $SalesMail = $form{'setSalesMail'};
  $MailSender = $form{'setMailSender'};
  $CsLogo = $form{'CsImage'};
  $CsName = $form{'CsName'};
  $CsRegNum = $form{'CsRegNum'};
  $CsVatNum = $form{'CsVatNum'};
  $CsPhysical = $form{'CsPhysical'};
  $CsPostal = $form{'CsPostal'};
  $CsTele = $form{'CsTele'};
  $CsFax = $form{'CsFax'};
  $CsEmail = $form{'CsEmail'};
  $CsUrl = $form{'CsUrl'};
  $CsUrlEx = $CsUrl;
  $CsBank = $form{'CsBank'};
  $CsSlogan = $form{'CsSlogan'};

  $CsPhysical =~ s/\n/<br>/g;
  $CsPhysical =~ s/\cM//g;
  $CsPostal =~ s/\n/<br>/g;
  $CsPostal =~ s/\cM//g;
  if ($CsRegNum ne "") {
    $CsRegNum =~ s/Reg: //g; 
    $CsRegNum = "Reg: ".$CsRegNum;
  }
  if ($CsVatReg ne "") {
    $CsVatReg =~ s/VAT: //g;
    $CsVatReg = "VAT: ".$CsVatReg;
  }
  $CsBank =~ s/\n/<br>/g;
  $CsBank =~ s/\cM//g;
  
  $CsInsert = "$CsImage|$CsName|$CsVatNum|$CsRegNum|$CsPostal|$CsPhysical|$CsTele|$CsFax|$CsEmail|$CsUrl|$CsUrlEx|$CsBank|$CsSlogan";
  
}

sub display_pending_function {
  $StatusMessage = "1|The selected function is currently not available.";
  $func = "home";
  &display_admin_home;
}

sub display_payment_info {

  $PageHeader = "Manual Credit Card Payment";
  if ($step ne "pass") { $page = "payment_manual"; } else { $page = "payment_success"; }
  &display_page_requested;
}

#--------------------------------------
sub display_user_settings {

  if ($step eq "setpass") {
    $PassWord = $form{'PassWord'};
    $RepPass = $form{'RepPass'};
    $NewPass = $form{'NewPass'};

    $sql_statement = "SELECT UserName FROM admin_users WHERE AdminId = '$UserId' AND PassWord = '$PassWord';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    $SetUserName = @arr[0];
    if ($SetUserName eq "") { $StatusMessage = "1|Error: Your current Password is invalid! Please try again!"; }
    if (length($NewPass) < 6) { $StatusMessage = "1|Error: New Password must be longer than 5 characters in length!\\nPlease try again!"; }
    if ($NewPass ne $RepPass) { $StatusMessage = "1|Error: New Password and Repeat Password do not match!\\nPlease try again!"; }
    if ($StatusMessage eq "") {
      $sql_statement = "UPDATE admin_users SET PassWord = '$NewPass' WHERE AdminId = '$UserId';";
      $sth = $dbh->query($sql_statement);
      $StatusMessage = "0|Password for '$SetUserName' was changed successfully!";
    }
  }
  if ($step eq "enable") {
    $DelAdminId = $info{'aid'};
    $sql_statement = "SELECT UserName FROM admin_users WHERE AdminId = '$DelAdminId';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    $SetUserName = @arr[0];
    $sql_statement = "UPDATE admin_users SET StatFlag = '1' WHERE AdminId = '$DelAdminId';";
    $sth = $dbh->query($sql_statement);
    $StatusMessage = "0|User <b>$SetUserName</b> has been enabled successfully!";    
  }
  if ($step eq "disable") {
    $DelAdminId = $info{'aid'};
    $sql_statement = "SELECT UserName FROM admin_users WHERE AdminId = '$DelAdminId';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    $SetUserName = @arr[0];
    $sql_statement = "UPDATE admin_users SET StatFlag = '0' WHERE AdminId = '$DelAdminId';";
    $sth = $dbh->query($sql_statement);
    $StatusMessage = "1|User <b>$SetUserName</b> has been disabled successfully!";    
  }
  if ($step eq "delete") {
    $DelAdminId = $info{'aid'};
    $sql_statement = "SELECT UserName FROM admin_users WHERE AdminId = '$DelAdminId';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    $SetUserName = @arr[0];
    $sql_statement = "DELETE FROM admin_users WHERE AdminId = '$DelAdminId' AND AdminLevel != '8';";
    $sth = $dbh->query($sql_statement);    
    $StatusMessage = "1|User <b>$SetUserName</b> was deleted successfully!";    
  }
  if ($step eq "adduser") {
    $PassWord = $form{'PassWord'};
    $RepPass = $form{'RepPass'};
    $NewPass = $form{'NewPass'};
    $NewUser = $form{'NewUser'};
    $NewFirstName = $form{'NewFirstName'};
    $NewSurName = $form{'NewSurName'};
    $EmailAddy = $form{'EmailAddy'};
    $AccessLevel = $form{'AccessLevel'};

    $sql_statement = "SELECT UserName FROM admin_users WHERE AdminId = '$UserId' AND PassWord = '$PassWord';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    $SetUserName = @arr[0];
    if ($SetUserName eq "") { $StatusMessage = "1|Error: Your current Password is invalid! Please try again!"; }
    if (length($NewPass) < 6) { $StatusMessage = "1|Error: New Password must be longer than 5 characters in length! Please try again!"; }
    if ($NewPass ne $RepPass) { $StatusMessage = "1|Error: New Password and Repeat Password do not match! Please try again!"; }
    if (length($NewUser) < 6) { $StatusMessage = "1|Error: New UserName must be longer than 5 characters in length! Please try again!"; }
    $sql_statement = "SELECT COUNT(*) FROM admin_users WHERE UserName = '$NewUser';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    $TestCNT = @arr[0];
    if ($TestCNT > 0) { $StatusMessage = "1|Error: UserName '$NewUser' already exists! Please choose a unique username!"; }
    if ($StatusMessage eq "") {
      $sql_statement = "INSERT INTO admin_users VALUES ('','$AccessLevel','$NewUser','$NewPass','','','$NewFirstName','$NewSurName','$NewEmailAddy','1');";
      $sth = $dbh->query($sql_statement);
      $StatusMessage = "0|User '$NewUser' was created successfully!";
    }
  }

  $sql_statement = "SELECT VarMax,VarMin FROM system_variables WHERE VarName = 'AccessLevel' ORDER BY VarMax DESC;";
  $sth = $dbh->query($sql_statement);
  while (@arr = $sth->fetchrow) {
    ($VarMax,$VarMin) = @arr;
    if ($AccessLevel eq $VarMax) { $AccessList = $AccessList."<option value=\"$VarMax\" selected>$VarMin</option>\n"; }
    else { $AccessList = $AccessList."<option value=\"$VarMax\">$VarMin</option>\n"; }
  }
  $sql_statement = "SELECT AdminId FROM admin_users ORDER BY AdminLevel DESC;";
  $sth = $dbh->query($sql_statement);
  while (@arr = $sth->fetchrow) {
    ($XUserId) = @arr;
    push(@users,$XUserId);
  }
  foreach $XUserId(@users) {
    $sql_statement = "SELECT UserName,FirstName,SurName,EmailAddy,AdminLevel,StatFlag FROM admin_users WHERE AdminId = '$XUserId';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    ($XUserName,$XFirstName,$XSurName,$XEmailAddy,$XAdminLevel,$XStatFlag) = @arr;
    if ($XStatFlag eq "0") {
      $XUserName = "<span class=\"StrikeText\">$XUserName</span>";
      $DisUserLink = "<a href=\"../cgi-bin/dbadmin.pl?f=luser&s=enable&aid=$XUserId\"><img src=\"../images/site_admin/user_add.png\" border=\"0\" hspace=\"2\"></a>";
      $XStatus = "Disabled";
    }
    else {
      $DisUserLink = "<a href=\"../cgi-bin/dbadmin.pl?f=luser&s=disable&aid=$XUserId\"><img src=\"../images/site_admin/user_remove.png\" border=\"0\" hspace=\"2\"></a>";
      $XStatus = "Active";
    }
    $sql_statement = "SELECT VarMin FROM system_variables WHERE VarName = 'AccessLevel' AND VarMax = '$AdminLevel';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
    ($XAdminLevel) = @arr;
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    if ($XUserId eq $ZUserId) { $BgClass = "ListStyle3"; }
    $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $TableListing = $TableListing."<td class=\"ListCell\">$XUserId</td>\n";
    $TableListing = $TableListing."<td class=\"ListCell\">$XUserName</td>\n";
    $TableListing = $TableListing."<td class=\"ListCell\">$XFirstName $XSurName </td>\n";
    $TableListing = $TableListing."<td class=\"ListCellCenter\">$XAdminLevel</td>\n";
    $TableListing = $TableListing."<td class=\"ListCellCenter\">$XStatus</td>\n";
    if ($XUserName eq "Ninja") { $TableListing = $TableListing."<td class=\"ListCell\">---</td></tr>\n"; }
    else { $TableListing = $TableListing."<td class=\"ListCell\"><a href=\"mailto:".$XEmailAddy."\"><img src=\"../images/site_admin/email2.png\" border=\"0\" hspace=\"2\"></a>$DisUserLink<a href=\"../cgi-bin/dbadmin.pl?f=luser&s=delete&aid=".$XUserId."\"><img src=\"../images/site_admin/stop.png\" border=\"0\" hspace=\"2\"></a></td></tr>\n"; }
  }
  
  $PageHeader = "Users : Change My Password";
  $page = "luser_listuser";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------

sub fetch_delivery_options {
  &parse_delivery_options;
  if ($step eq "disable") {
    $DelId = $info{'did'};
    $sql_statement = "SELECT OptionName FROM deliver_options WHERE DelId = '$DelId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($OptionName) = @arr;    
    $sql_statement = "UPDATE deliver_options SET StatFlag = '0' WHERE DelId = '$DelId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $StatusMessage = "1|Disabled '$OptionName' successfully";
  }
  if ($step eq "enable") {
    $DelId = $info{'did'};
    $sql_statement = "SELECT OptionName FROM deliver_options WHERE DelId = '$DelId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($OptionName) = @arr;    
    $sql_statement = "UPDATE deliver_options SET StatFlag = '1' WHERE DelId = '$DelId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $StatusMessage = "0|Enabled '$OptionName' successfully";
  }
  if ($step eq "addedit") {
    if ($EditOption eq "1") {
      $sql_statement = "UPDATE deliver_options SET TimeStamp = '$TimeStamp',MinWeight = '$MinWeight',MaxWeight = '$MaxWeight',OptionName = '$OptionName',DeliverRate = '$DeliverRate',InsureRate = '$InsureRate',DeliverTime = '$DeliverTime',DeliverMax = '$DeliverMax' WHERE DelId = '$DelId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $StatusMessage = "0|Updated '$OptionName' successfully";
    }
    elsif ($SaveOption eq "1") {
      $sql_statement = "INSERT INTO deliver_options VALUES ('','1','$TimeStamp','$MinWeight','$MaxWeight','$OptionName','$DeliverRate','$InsureRate','$DeliverTime','$DeliverMax');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $StatusMessage = "0|Saved New '$OptionName' successfully";
      $sql_statement = "SELECT DelId FROM deliver_options WHERE TimeStamp = '$TimeStamp' AND OptionName = '$OptionName' LIMIT 0,1;";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      ($DelId) = @arr;      
    }
  }

  $sql_statement = "SELECT * FROM deliver_options ORDER BY StatFlag DESC,OptionName,MinWeight;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while(@arr = $sth->fetchrow) {
    ($XDelId, $StatFlag, $TimeStamp, $MinWeight, $MaxWeight, $OptionName, $DeliverRate, $InsureRate, $DeliverTime, $DeliverMax) = @arr;
    $MinWeight = sprintf("%.1f",$MinWeight);
    $MaxWeight = sprintf("%.1f",$MaxWeight);
    $MinWeight = sprintf("%.1f",$MinWeight);
    $InsureRate = $InsureRate * 100;
    $DeliverMax = $DeliverMax/86400;

    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    if ($XDelId eq $DelId) { $BgClass = "ListStyle3"; }
    $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $TableListing = $TableListing." <td class=\"ListCell\">$OptionName</td>\n";
    $TableListing = $TableListing." <td class=\"ListCellCenter\" nowrap>$MinWeight - $MaxWeight</td>\n";
    $TableListing = $TableListing." <td class=\"ListCellRight\">$DeliverRate</td>\n";
    $TableListing = $TableListing." <td class=\"ListCellRight\">$InsureRate %</td>\n";
    $TableListing = $TableListing." <td class=\"ListCell\" nowrap>$DeliverTime</td>\n";
    $TableListing = $TableListing." <td class=\"ListCellCenter\"><a href=\"javascript:EditDeliveryOption('$XDelId','$OptionName','$MinWeight','$MaxWeight','$DeliverRate','$InsureRate','$DeliverTime','$DeliverMax','$uid');\"><img src=\"../images/site_admin/file_edit.png\" alt=\"Edit\" width=\"16\" height=\"16\" border=\"0\"></a>";
    if ($StatFlag eq "1") { $TableListing = $TableListing."<a href=\"javascript:DisableDeliveryOption('$XDelId','$OptionName');\"><img src=\"../images/site_admin/stop.png\" alt=\"Disable\" width=\"16\" height=\"16\" hspace=\"3\" border=\"0\"></a></td>\n</tr>\n"; }
    else { $TableListing = $TableListing."<a href=\"../cgi-bin/dbadmin.pl?fn=deliver&st=enable&did=$XDelId&uid=$uid\"><img src=\"../images/site_admin/dbase_ok.gif\" alt=\"Enable\" width=\"16\" height=\"16\" hspace=\"3\" border=\"0\"></a></td>\n</tr>\n"; }
  }

  $PageHeader = "Manage Delivery Options";
  $page = "deliver_options";
  &display_page_requested;
}

sub parse_delivery_options {
  $DelId = $form{'DelId'};
  $MinWeight = $form{'MinWeight'};
  $MaxWeight = $form{'MaxWeight'};
  $OptionName = $form{'OptionName'};
  $DeliverRate = $form{'DeliverRate'};
  $InsureRate = $form{'InsureRate'};
  $DeliverTime = $form{'DeliverTime'};
  $DeliverMax = $form{'DeliverMax'};
  $EditOption = $form{'EditOption'};
  $SaveOption = $form{'SaveOption'};
  
  $InsureRate =~ tr/0-9\./ /cs;
  $InsureRate =~ s/ //g;
  $DeliverRate =~ tr/0-9\./ /cs;
  $DeliverRate =~ s/ //g;
  $MinWeight =~ tr/0-9\./ /cs;
  $MinWeight =~ s/ //g;
  $MaxWeight =~ tr/0-9\./ /cs;
  $MaxWeight =~ s/ //g;
  if ($InsureRate > 0) { $InsureRate = $InsureRate/100; } else { $InsureRate = "0"; }
  $InsureRate = sprintf("%.3f",$InsureRate);
  $DeliverRate = sprintf("%.2f",$DeliverRate);
  $MinWeight = sprintf("%.2f",$MinWeight);
  $MaxWeight = sprintf("%.2f",$MaxWeight);
  $DeliverMax = $DeliverMax * 86400;

}

#--------------------------------------

sub display_links_info {
  $LinkId = $info{'i'};
  $LinkName = $form{'LinkName'};
  $LinkURL = $form{'LinkURL'};
  $LinkDescript = $form{'LinkDescript'};
  $LinkURL =~ s/http:\/\///gi;
  $LinkDescript =~ s/\cM//g;
  $LinkDescript =~ s/\n/ /g;

  if ($step eq "del") {
    $sql_statement = "SELECT LinkName FROM content_links WHERE LinkId = '$LinkId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $XLinkName = @arr[0];
    $sql_statement = "DELETE FROM content_links WHERE LinkId = '$LinkId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $StatusMessage = "1|Link '$XLinkName' was deleted successfully!";
  }

  if ($step eq "add") {
    $sql_statement = "SELECT COUNT(*) FROM content_links WHERE LinkName LIKE '$LinkName';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $TestCNT = @arr[0];
    
    if ($TestCNT == 0) {
      $sql_statement = "INSERT INTO content_links VALUES ('','1','$TimeStamp','$LinkName','$LinkURL','0','$LinkDescript');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    }
    $StatusMessage = "0|Link '$LinkName' was added successfully!";
  }
  if ($step eq "edit") {
    $sql_statement = "SELECT * FROM content_links WHERE LinkId = '$LinkId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($XLinkId,$XStatFlag,$XTimeStamp,$LinkName,$LinkURL,$ViewCount,$LinkDescript) = @arr;
  }
  if ($step eq "edsave") {
    $LinkId = $form{'LinkId'};
    $sql_statement = "UPDATE content_links SET TimeStamp = '$TimeStamp',LinkName = '$LinkName',LinkURL = '$LinkURL',LinkDescript = '$LinkDescript' WHERE LinkId = '$LinkId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $StatusMessage = "0|Link '$LinkName' was updated successfully!";
  }

  $LinkCount = "0";
  $sql_statement = "SELECT * FROM content_links WHERE StatFlag = '1' ORDER BY LinkName;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($XLinkId,$XStatFlag,$XTimeStamp,$XLinkName,$XLinkURL,$ViewCount,$XLinkDescript) = @arr;
    &convert_timestamp($XTimeStamp);
    if (length($XLinkDescript) > 48) { $XLinkDescript = substr($XLinkDescript,0,48); $XLinkDescript = $XLinkDescript."..."; }
    
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $TableListing = $TableListing."  <td class=\"ListCell\"><a href=\"index.pl?f=links&s=get&i=$XLinkId\" target=\"_blank\">$XLinkName</a><br>\n";
    $TableListing = $TableListing."  <span class=\"LowLightText\">$ConvTimeStamp</span> $XLinkDescript</td>\n";
    $TableListing = $TableListing."  <td valign=\"top\" nowrap class=\"ListCellCenter\">$ViewCount&nbsp;</td>\n";
    $TableListing = $TableListing."  <td valign=\"top\" class=\"ListCell\"><a href=\"javascript:AddToClipBoard('L','$XLinkId');\"><img src=\"../images/site_admin/paste.png\" alt=\"Clipboard '".$LinkName."'\" border=\"0\" hspace=\"1\"></a><a href=\"index.pl?f=links&s=get&i=$XLinkId\" target=\"_blank\"><img src=\"../images/site_admin/www2.png\" width=\"16\" height=\"16\" border=\"0\"></a><a href=\"javascript:EditLink($LinkCount);\"><img src=\"../images/site_admin/file_edit.png\" width=\"16\" height=\"16\" border=\"0\" hspace=\"1\"></a><a href=\"javascript:DeleteLink('$XLinkId');\"><img src=\"../images/site_admin/stop.png\" width=\"16\" height=\"16\" border=\"0\"></a></td>\n";
    $TableListing = $TableListing." </tr>\n";
    
    $XLinkDescript =~ s/\"/&quot;/g;
    $XLinkDescript =~ s/\'/&apos;/g;
    $XLinkDescript =~ s/\\//g;
    $XLinkName =~ s/\"/&quot;/g;
    $XLinkName =~ s/\'/&apos;/g;
    $XLinkName =~ s/\\//g;

    $LinkArray = $LinkArray."SetLinkURL[$LinkCount] = \"$XLinkURL\";\n";
    $NameArray = $NameArray."SetLinkName[$LinkCount] = \"$XLinkName\";\n";
    $DescArray = $DescArray."SetLinkDesc[$LinkCount] = \"$XLinkDescript\";\n";
    $IdentArray = $IdentArray."SetLinkId[$LinkCount] = \"$XLinkId\";\n";
    $LinkCount++;
    
  }

  $PageHeader = "External Link Manager";
  if ($step ne "edit") { $page = "links_show"; } else { $page = "links_edit"; }
  &display_page_requested;
}

sub display_under_construct {
    $PageHeader = "Feature not Available";
    $page = "admin_undercon";
    &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------

sub display_forex_page {
  if ($step eq "save") {
    $UsdVal = $form{'UsdVal'};
    $GbpVal = $form{'GbpVal'};
    $EurVal = $form{'EurVal'};
    $sql_statement = "UPDATE exchange_rate SET ConversionRate = '$UsdVal',TimeStamp = '$DateNow' WHERE Currency = 'USD';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE exchange_rate SET ConversionRate = '$GbpVal',TimeStamp = '$DateNow' WHERE Currency = 'GBP';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "UPDATE exchange_rate SET ConversionRate = '$EurVal',TimeStamp = '$DateNow' WHERE Currency = 'EUR';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $ForexDate = $DateNow;

    
  }
  else {
    $sql_statement = "SELECT * FROM exchange_rate WHERE Currency = 'USD';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($RateId,$XTimeStamp,$Currency,$UsdVal,$ForexDate) = @arr;
    $sql_statement = "SELECT * FROM exchange_rate WHERE Currency = 'GBP';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($RateId,$XTimeStamp,$Currency,$GbpVal,$ForexDate) = @arr;
    $sql_statement = "SELECT * FROM exchange_rate WHERE Currency = 'EUR';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($RateId,$XTimeStamp,$Currency,$EurVal,$ForexDate) = @arr;
    #if ($UsdVal > 0) { $UsdVal = 1/$UsdVal; }
    #if ($GbpVal > 0) { $GbpVal = 1/$GbpVal; }
    #if ($EurVal > 0) { $EurVal = 1/$EurVal; }
    $UsdVal = sprintf("%.2f",$UsdVal);
    $GbpVal = sprintf("%.2f",$GbpVal);
    $EurVal = sprintf("%.2f",$EurVal);
  }

  $PageHeader = "Adjust Exchange Rates";
  $page = "forex_edit";
  &display_page_requested;
}

#--------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------
sub display_resellers_page {
  $SortFlag = "ResId DESC ";
  $SearchFlag = " ";
  $SortData = $info{'sd'};
  $SortType = $info{'sr'};
  &get_reseller_history;

  if ($step eq "update") {
    $OrderId = $info{'oid'};
    $UpdateStatus = $form{'UpdateStatus'};
    $WayBillNumber = $form{'WayBillNumber'};
    $AdminComment = $form{'AdminComment'};
    $WayBillNumber =~ s/- Waybill Number -//g;
    $AdminComment =~ s/- Comments\/Reason -//g;
    $AdminComment =~ s/\cM//g;
    $AdminComment =~ s/\n/ /g;
    $sql_statement = "UPDATE reseller_order SET DeliverDate = '$TimeStamp',OrderStat = '$UpdateStatus',WayBillNumber = '$WayBillNumber',AdminComment = 'Updated by $UserName $DateNow : $AdminComment' WHERE OrderId = '$OrderId' AND ResId = '$ResId';";
    $TestString = $TestString."\n".$sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "reshow";
    $func = "order";
    $AlertPrompt = "The status of this order has been updated successfully!";
    &display_orders_page;
  }
  if ($step eq "edsave") {
    &parse_reseller_form;
    $sql_statement = "SELECT PassWord FROM admin_users WHERE AdminId = '$UserId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($CheckPass) = @arr;
    push(@debugstring,"VALIDATE||$PassWord:$CheckPass");
    
    if (($PassWord ne $CheckPass) || (length($PassWord) < 6)) { $StatusMessage = "1|The admin password you entered is invalid! Please enter it again..."; }
    elsif ($EmailAddress !~ /.+\@.+\..+/) { $StatusMessage = "1|The email address you entered is invalid! Please enter it again..."; }
    elsif ($NewPassWord ne "") {
      if ($NewPassWord ne $RepPass) { $StatusMessage = "1|The new password and repeat passwords do not match! Please enter it again..."; }
      elsif (length($NewPassWord) < 6) { $StatusMessage = "1|The new password you entered is too short! Please enter a new password that is 6 characters or longer"; }
      else {
        $sql_statement = "UPDATE reseller_details SET CompanyName = '$CompanyName',CompanyReg = '$CompanyReg',VatNumber = '$VatNumber',Title = '$Title',FirstName = '$FirstName',SurName = '$SurName',IdNumber = '$IdNumber',EmailAddress = '$EmailAddress',TelArea = '$TelArea',Telephone = '$Telephone',FaxArea = '$FaxArea',FaxNum = '$FaxNum',Mobile = '$Mobile',PhysicalAddress = '$PhysicalAddress',PostalAddress = '$PostalAddress',CityTown = '$CityTown',Province = '$Province',Country = '$Country',WebURL = '$WebURL',PassWord = '$NewPassWord',BusinessDescript = '$BusinessDescript' WHERE ResId = '$ResId';";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        $PassWord = $NewPassWord;
        &send_reseller_update;
        $StatusMessage = "0|Reseller profile has been updated and <b>password changed</b>! An email detailing the changes has been sent to $EmailAddress";
        $sql_statement = "INSERT INTO reseller_history VALUES ('','1','$TimeStamp','$ResId','$current_user','1004','Profile Updated, Password Changed');";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        $sql_statement = "INSERT INTO reseller_admin VALUES ('','1','$TimeStamp','$UserId','$ResId','$DateNow: $UserName updated the resellers details|$EmailAddress has been notified');";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        $step = "view";
      }
    }
    else {
      $sql_statement = "UPDATE reseller_details SET CompanyName = '$CompanyName',CompanyReg = '$CompanyReg',VatNumber = '$VatNumber',Title = '$Title',FirstName = '$FirstName',SurName = '$SurName',IdNumber = '$IdNumber',EmailAddress = '$EmailAddress',TelArea = '$TelArea',Telephone = '$Telephone',FaxArea = '$FaxArea',FaxNum = '$FaxNum',Mobile = '$Mobile',PhysicalAddress = '$PhysicalAddress',PostalAddress = '$PostalAddress',CityTown = '$CityTown',Province = '$Province',Country = '$Country',WebURL = '$WebURL',BusinessDescript = '$BusinessDescript' WHERE ResId = '$ResId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $StatusMessage = "0|Reseller profile has been updated successfully!";
      $sql_statement = "INSERT INTO reseller_history VALUES ('','1','$TimeStamp','$ResId','$current_user','1004','Profile Updated');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $sql_statement = "INSERT INTO reseller_admin VALUES ('','1','$TimeStamp','$UserId','$ResId','$DateNow: $UserName updated the resellers company/contact details');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $step = "view";
    }
    if ($step ne "view") {
      $PageHeader = "Reseller Information : $ResId";
      $page = "reseller_edit";
      &display_page_requested;
    }
  }
  
  if ($step eq "disable") {
    $sql_statement = "UPDATE reseller_details SET StatFlag = '0' WHERE ResId = '$ResId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "view";
    $StatusMessage = "0|Reseller account '$ResId _COMPANYNAME_' has been disabled!";
  }
  if ($step eq "approve") {
    $DiscountRate = $form{'DiscountRate'};

    $sql_statement = "SELECT AccountNumber,FirstName,EmailAddress,PassWord FROM reseller_details WHERE ResId = '$ResId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($AccountNumber,$RFirstName,$REmailAddress,$RPassWord) = @arr;
    
    if ($AccountNumber eq "") {
      $sql_statement = "SELECT AccountNumber FROM account_table WHERE StatFlag = '0' LIMIT 0,1";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      ($AccountNumber) = @arr;
      $sql_statement = "UPDATE account_table SET StatFlag = '1',CustId = '$ResId' WHERE AccountNumber = '$AccountNumber';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      &send_reseller_approved;
      $sql_statement = "INSERT INTO reseller_admin VALUES ('','1','$TimeStamp','$UserId','$ResId','$DateNow: Account Approved by $UserName|New Account number Assigned: $AccountNumber|Email notification sent to $REmailAddress');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $sql_statement = "UPDATE reseller_details SET StatFlag = '3',DiscountRate = '$DiscountRate',AccountNumber = '$AccountNumber' WHERE ResId = '$ResId'";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $sql_statement = "INSERT INTO reseller_admin VALUES ('','1','$TimeStamp','$UserId','$ResId','$DateNow: $UserName changed discount rate to $DiscountRate');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $StatusMessage = "0|Reseller account '$ResId / $AccountNumber _COMPANYNAME_' was approved successfully! A notification email was sent to $REmailAddress.";
    }
    else {
      $sql_statement = "UPDATE reseller_details SET StatFlag = '3',DiscountRate = '$DiscountRate' WHERE ResId = '$ResId'";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $sql_statement = "INSERT INTO reseller_admin VALUES ('','1','$TimeStamp','$UserId','$ResId','$DateNow: $UserName changed discount rate to $DiscountRate');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $StatusMessage = "0|Reseller account '$ResId _COMPANYNAME_' was updated successfully!";
    }
    $step = "view";
  }
  if ($step eq "setrate") {
    $DiscountRate = $info{'dir'};
    $sql_statement = "UPDATE reseller_details SET DiscountRate = '$DiscountRate' WHERE ResId = '$ResId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "view";
    $StatusMessage = "0|Discount Rate for Reseller account '$ResId _COMPANYNAME_' was updated successfully!";
  }
  if (($step eq "view") || ($step eq "edit")) {
    $sql_statement = "SELECT * FROM reseller_details WHERE ResId = '$ResId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($ResId, $XStatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $DiscountRate, $AcceptTerms, $AccountNumber, $BusinessDescript) = @arr;
      $WebURL =~ s/http:\/\///gi;
    &convert_timestamp($SignDate);
    $SignDate = $ConvTimeStamp;
    if ($XStatFlag eq "1") { $Disable_1 = " class=\"DisableImage\" disabled"; $Disable_2 = $Disable_1; $ResStatus = "Not Activated"; }
    if ($XStatFlag eq "3") { $Disable_1 = " class=\"DisableImage\" disabled"; $ResStatus = "Approved"; }    
    if ($XStatFlag eq "2") { $ResStatus = "Pending Approval"; }    
    if ($XStatFlag eq "0") { $Disable_2 = " class=\"DisableImage\" disabled";$ResStatus = "Disabled"; }    
    $sql_statement = "SELECT CountryName FROM countrycodes WHERE CountryCode = '$Country'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $CountryName = @arr[0];
    $PurchaseTotal = "0";
    $sql_statement = "SELECT * FROM reseller_order WHERE ResId = '$ResId' ORDER BY OrderId DESC;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      #($OrderId, $OrderStat, $PayOption, $BuyerId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderTotal, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $CurrencyMark, $WayBillNumber) = @arr;
      ($OrderId, $OrderStat, $PayOption, $XResId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderNumber, $DeliverOption, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $DeliverAddress, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
      $RowCount++;
      $OrderCount = $RowCount + $OffSet;
      #if ($step eq "search") { $TableListing =~ s/$SearchKey/\<span class=\"highlightsearch\"\>$SearchKey\<\/span\>/gi; }
      if ($BgFlag eq "1") { $BgFlag = "0"; $BgColor = "#F2F2F2"; } else { $BgFlag = "1"; $BgColor = "#FFFFFF"; }
      if ($OrderStat eq "0") { $OrderStatus = "Incomplete<img hspace=\"1\" src=\"../images/site_admin/lock.png\" border=\"0\" alt=\"Incomplete\" align=\"absmiddle\">"; }
      elsif ($OrderStat eq "1") { $OrderStatus = "Pending<img hspace=\"1\" src=\"../images/site_admin/waiting.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
      elsif ($OrderStat eq "2") { $OrderStatus = "Delivered<img hspace=\"1\" src=\"../images/site_admin/delivery.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
      elsif ($OrderStat eq "3") { $OrderStatus = "On-Hold<img hspace=\"1\" src=\"../images/site_admin/on_hold.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
      elsif ($OrderStat eq "4") { $OrderStatus = "Cancelled<img hspace=\"1\" src=\"../images/site_admin/cancel.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }  
      &convert_timestamp($XTimeStamp);
      $InvoiceDate = $ConvTimeStamp;
      if ($WayBillNumber eq "") { $WayBillNumber = "---"; }
      if ($PayOption eq "TX") { $InvoiceNum = "PF".$InvoiceNum; }
      $PurchaseTotal = $PurchaseTotal + $OrderTotal;
      $PurchaseHistory = $PurchaseHistory."<tr onmouseover=\"setPointer(this, $RowCount, 'over', '".$BgColor."', '#CCFFCC', '#FFCC99');\" onmouseout=\"setPointer(this, $RowCount, 'out', '".$BgColor."', '#CCFFCC', '#FFCC99');\" onmousedown=\"setPointer(this, $RowCount, 'click', '".$BgColor."', '#CCFFCC', '#FFCC99');\">\n ";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" class=\"ListCell\">&nbsp;".$RowCount.".</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" class=\"ListCell\">&nbsp;<a href=\"../cgi-bin/dbadmin.pl?f=order&s=reshow&oid=".$OrderId."&fs=".$OffSet."\">".$InvoiceNum."</a></td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" class=\"ListCell\">&nbsp;".$InvoiceDate."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" align=\"center\" class=\"ListCell\">".$WayBillNumber."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" align=\"right\" class=\"ListCell\">".$OrderTotal."&nbsp;</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" align=\"center\" class=\"ListCell\">".$PayOption."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td bgcolor=\"".$BgColor."\" class=\"ListCellRight\">&nbsp;".$OrderStatus."</td>\n</tr>\n";
    }
    if ($PurchaseHistory eq "") { $PurchaseHistory = "<tr><td colspan=\"7\" class=\"ListCellCenter\">No Purchases to Display</td></tr>\n"; }
    $PurchaseTotal = sprintf("%.2f",$PurchaseTotal);
    $RateVar = "0";
    $DiscountRate = sprintf("%.1f",$DiscountRate);
    for ($a=0; $a <= 100; $a++) {
      if ($DiscountRate eq $RateVar) { $DiscRateListing = $DiscRateListing."<option value=\"$RateVar\" selected>$RateVar %</option>\n"; }
      else { $DiscRateListing = $DiscRateListing."<option value=\"$RateVar\">$RateVar %</option>\n"; }
      $RateVar = $RateVar + 0.5;
      $RateVar = sprintf("%.1f",$RateVar);
    }
    $PageHeader = "Reseller Information : $ResId";
    if ($step eq "view") { $page = "reseller_show"; } else { $page = "reseller_edit"; } 
    &display_page_requested;
  }

  if ($SortType eq "sort") {
    if ($SortData eq "") { $SortData = $form{'SortOption'}; }
    ($SortBy,$SortDirect) = split(/\^/,$SortData);
    if ($SortBy eq "OrderStat") { $SearchFlag = "WHERE OrderStat = '".$SortDirect."' "; }
    else { $SortFlag = "$SortBy $SortDirect "; }
  }
  if ($SortType eq "search") {
    $SearchField = $form{'SearchField'};
    $SearchKey2 = $form{'SearchKey'};
    $SearchKey2 =~ s/- Keyword -//g;
    if (($SearchField ne "") && (length($SearchKey2) > 0)) {
      $SearchFlag = "WHERE $SearchField LIKE '%".$SearchKey2."%' ";
      $SortData = $SearchField."^".$SearchKey2;
    }
    else {
      ($SearchField,$SearchKey2) = split(/\^/,$SortData);
      $SearchFlag = "WHERE $SearchField LIKE '%".$SearchKey2."%' ";
    }
  }

  if ($step eq "summ") {
    $sql_statement = "SELECT COUNT(*) FROM reseller_details $SearchFlag;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ResultCount = @arr[0];
    $BuyerCount = "0";

    $sql_statement = "SELECT * FROM reseller_details ".$SearchFlag."ORDER BY ".$SortFlag."LIMIT ".$OffSet.",".$OrderDisplayLimit.";";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($ResId, $StatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $DiscountRate, $BusinessDescript) = @arr;
      $RowCount++;
      $BuyerCount = $RowCount + $OffSet;
      if ($StatFlag eq "1") { $StatusMsg = "Not Activated"; $StatusIcon = "pending.png"; }
      if ($StatFlag eq "2") { $StatusMsg = "Pending Approval"; $StatusIcon = "alert.png"; }
      if ($StatFlag eq "3") { $StatusMsg = "Approved";  $StatusIcon = "ok.png";}
      if ($StatFlag eq "0") { $StatusMsg = "Disabled";  $StatusIcon = "stop.png";}
      &convert_timestamp($SignDate);
      $SignDate = $ConvTimeDate;
      $DiscountRate = sprintf("%.1f",$DiscountRate);

      $WebURL =~ s/http:\/\///gi;
      if ($WebURL ne "") { $WebIcon = "<a href=\"http://$WebURL\" target=\"_blank\"><img src=\"../images/site_admin/www2.png\" border=\"0\"></a>"; }
      else { $WebIcon = "<a href=\"#\" class=\"DisableImage\"><img src=\"../images/site_admin/www2.png\" border=\"0\"></a>"; }

      if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
      $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$RowCount."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=reseller&s=view&rid=".$ResId."&fs=".$OffSet."\">".$ResId."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=reseller&s=view&rid=".$ResId."&fs=".$OffSet."\">".$Title." ".$FirstName." ".$SurName."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$CompanyName."</td>\n";
      #$TableListing = $TableListing." <td class=\"ListCell\">".$Country."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$SignDate."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellRight\">".$StatusMsg."</td>\n<td align=\"right\" class=\"ListCell\"><img src=\"../images/site_admin/$StatusIcon\"></td>\n <td class=\"ListCellRight\">".$DiscountRate."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><a href=\"mailto:$EmailAddress\"><img src=\"../images/site_admin/email2.png\" hspace=\"2\" border=\"0\" alt=\"$EmailAddress\"></a><a href=\"../cgi-bin/dbadmin.pl?fn=reseller&st=view&rid=".$ResId."&fs=".$OffSet."&uid=".$uid."\" onmouseover=\"ddrivetip('<div align=center>Telephone: <b>($TelArea) $Telephone</b><br>Fax: <b>($FaxArea) $FaxNum</b><br>Mobile: <b>$Mobile</b><br><br>Physical Address:<br>$PhysicalAddress<br><br>Postal Address<br>$PostalAddress</div>','#F7F7F7',300)\"; onmouseout=\"hideddrivetip()\"><img src=\"../images/site_admin/user_green.png\" hspace=\"2\" border=\"0\" alt=\"View\"></a>$WebIcon</td>\n</tr>\n";
    }
    if ($ResultCount < 1) { $TableListing = $TableListing."<tr><td class=\"ListCellCenter\" colspan=\"12\"><br><b>No records found matching your search criteria!</b><br>&nbsp;</td></tr>\n"; }
  
    $StartRecord = $OffSet + 1;
    $ResultText = "Displaying Items <b>$StartRecord</b> to <b>$OrderCount</b> of <b>$ResultCount</b> Items...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $OrderDisplayLimit;
    $OffSet = $OffSet + $OrderDisplayLimit;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $OrderDisplayLimit) { $RNavLink = $RNavLink."&laquo; <a href=\"dbadmin.pl?fn=buyer&st=summ&fs=".$PrevLink."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $OrderDisplayLimit;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ResultCount) { $RNavLink = $RNavLink."<a href=\"dbadmin.pl?fn=buyer&st=summ&fs=".$TestOffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ResultCount) { $RNavLink = $RNavLink." <a href=\"dbadmin.pl?fn=buyer&st=summ&fs=".$OffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
  }
  &populate_reseller_options;
  $PageHeader = "Reseller Administration";
  $page = "reseller_view";
  &display_page_requested;

}
sub populate_reseller_options {
    $sql_statement = "SELECT VarName,VarMax FROM system_variables WHERE VarGroup = '7'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($VarName,$VarMax) = @arr;
      if ($SearchField eq $VarName) { $SearchFieldList = $SearchFieldList."<option value=\"".$VarName."\" selected> ".$VarMax." </option>\n"; }
      else { $SearchFieldList = $SearchFieldList."<option value=\"".$VarName."\"> ".$VarMax." </option>\n"; }
    }
    $sql_statement = "SELECT VarName,VarMax FROM system_variables WHERE VarGroup = '8'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($VarName,$VarMax) = @arr;
      if ($SortData eq $VarName) { $SortOptionList = $SortOptionList."<option value=\"".$VarName."\" selected> ".$VarMax." </option>\n"; }
      else { $SortOptionList = $SortOptionList."<option value=\"".$VarName."\"> ".$VarMax." </option>\n"; }
    }
}
sub get_reseller_history {
  $sql_statement = "SELECT * FROM reseller_admin WHERE ResId = '$ResId' AND StatFlag = '1' ORDER BY LogId DESC LIMIT 0,20;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($ALogId, $AStatFlag, $ATimeStamp, $AAdminId, $AResId, $AAdminNotes) = @arr;
    push(@adnotes,"$ALogId||$AStatFlag||$ATimeStamp||$AAdminId||$AResId||$AAdminNotes");
  }
  foreach $Temp(@adnotes) {
    ($ALogId, $AStatFlag, $ATimeStamp, $AAdminId, $AResId, $AAdminNotes) = split(/\|\|/,$Temp);
    $sql_statement = "SELECT UserName FROM admin_users WHERE AdminId = '$AAdminId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($AUserName) = @arr;
    $AAdminNotes =~ s/\|/<br>/g;
    
    &convert_timestamp($ATimeStamp);
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    $ResellerNotes = $ResellerNotes."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $ResellerNotes = $ResellerNotes." <td class=\"ListCell\">".$ConvTimeDate."</td>\n";
    $ResellerNotes = $ResellerNotes." <td class=\"ListCell\">".$AUserName."</td>\n";
    $ResellerNotes = $ResellerNotes." <td class=\"ListCellRight\"><a href=\"#\" onMouseOver=\"ddrivetip('<div align=left>$AAdminNotes</div>','#F2F2F2',400)\"; onMouseOut=\"hideddrivetip()\" class=\"ImageBorder\"><img src=\"../images/site_admin/tool.png\" border=\"0\"></a></td>\n</tr>\n";
  }
}

sub parse_reseller_form {
  $CompanyName = $form{'CompanyName'};
  $CompanyReg = $form{'CompanyReg'};
  $VatNumber = $form{'VatNumber'};
  $Title = $form{'Title'};
  $FirstName = $form{'FirstName'};
  $SurName = $form{'SurName'};
  $IdNumber = $form{'IdNumber'};
  $EmailAddress = $form{'EmailAddress'};
  $TelArea = $form{'TelArea'};
  $Telephone = $form{'Telephone'};
  $FaxArea = $form{'FaxArea'};
  $FaxNum = $form{'FaxNum'};
  $Mobile = $form{'Mobile'};
  $PhysicalAddress = $form{'PhysicalAddress'};
  $PostalAddress = $form{'PostalAddress'};
  $CityTown = $form{'CityTown'};
  $Province = $form{'Province'};
  $Country = $form{'Country'};
  $WebURL = $form{'WebURL'};
  $PassWord = $form{'PassWord'};
  $RepPass = $form{'RepPass'};
  $NewPassWord = $form{'NewPassWord'};
  $ActiveCode = $form{'ActiveCode'};
  $BusinessDescript = $form{'BusinessDescript'};
  
  $EmailAddress =~ tr/A-Z/a-z/;
  $WebURL =~ s/http:\/\///gi;

}

#----------------------------------------------

sub send_reseller_approved {
  $MailTemplate = $mailroot."reseller_approved.msg";
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
    $line =~ s/_RES_ID_/$ResId/g;
    $line =~ s/_ACCOUNTNUMBER_/$AccountNumber/g;
    $line =~ s/_EMAILADDRESS_/$REmailAddress/g;
    $line =~ s/_PASSWORD_/$RPassWord/g;
    $line =~ s/_FIRSTNAME_/$RFirstName/g;
  	$MailText = $MailText.$line;
  }
  $RecipMail = $REmailAddress;
  $MailSubject = "Reseller Account Approved - www.Toner.co.za";
  &send_email_message;
}

sub send_reseller_update {
  $MailTemplate = $mailroot."reseller_reminder.msg";
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
	$line =~ s/_RES_ID_/$ResId/g;
	$line =~ s/_EMAILADDRESS_/$EmailAddress/g;
	$line =~ s/_PASSWORD_/$PassWord/g;
	$line =~ s/_FIRSTNAME_/$FirstName/g;
	$MailText = $MailText.$line;
  }
  $RecipMail = $EmailAddress;
  $MailSubject = "Your Reseller Account Password Update from www.Toner.co.za";
  &send_email_message;
}

sub send_email_message {
  $MailText =~ s/\\'/\'/g;
  $MailText =~ s/\\"/\"/g;
  $MailText =~ s/\\,/\,/g;
  if ($TestMode ne "Y") { open (MAIL, "|$mail_prog -t"); }
  else { open (MAIL, ">$mailtemp"); }
  print MAIL "To: $RecipMail\n";
  print MAIL "Bcc: file13\@w3b.co.za\n";
  print MAIL "Reply-to: $MailSender\n";
  print MAIL "From: $MailSender\n";
  print MAIL "Subject: $MailSubject\n";
  print MAIL $MailText."\n\n";
  close(MAIL);
}
#--------------------------------------------------------------------------------------------------------------
sub display_buyers_page {
  $SortFlag = "BuyerId DESC ";
  $SearchFlag = "WHERE BuyFlag != '0' ";
  $SortData = $info{'sd'};
  $SortType = $info{'sr'};

  if ($step eq "view") {
    $sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $SurName, $DateOfBirth, $TelAreaCode, $Telephone, $FaxAreaCode, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostalCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DelDayFrom, $DelDayTo) = @arr;
    &convert_timestamp($SignDate);
    $SignDate = $ConvTimeStamp;
    $sql_statement = "SELECT CountryName FROM countrycodes WHERE CountryCode = '$Country'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $CountryName = @arr[0];
    $PurchaseTotal = "0";
    $sql_statement = "SELECT * FROM order_main WHERE BuyerId = '$BuyerId' ORDER BY OrderId DESC;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($OrderId, $OrderStat, $PayOption, $BuyerId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderWeight, $OptionDel, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
      #($OrderId, $OrderStat, $PayOption, $BuyerId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderTotal, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $CurrencyMark, $WayBillNumber) = @arr;
      $RowCount++;
      $OrderCount = $RowCount + $OffSet;
      if ($OrderStat eq "1") { $OrderStatus = "Pending"; }
      if ($OrderStat eq "2") { $OrderStatus = "Delivered"; }
      if ($OrderStat eq "3") { $OrderStatus = "On-Hold"; }
      if ($OrderStat eq "4") { $OrderStatus = "Cancelled"; }
      &convert_timestamp($XTimeStamp);
      $InvoiceDate = $ConvTimeStamp;
      if ($WayBillNumber eq "") { $WayBillNumber = "---"; }
      if ($PayOption eq "TX") { $InvoiceNum = "PF".$InvoiceNum; }
      $PurchaseTotal = $PurchaseTotal + $OrderTotal;
      if ($Company eq "") { $Company = "<span class=\"LowLightText\">-none-</span>"; }
      if ($VoucherCode eq "") { $VoucherCode = "<span class=\"LowLightText\">-none-</span>"; }
      if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
      $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
      $PurchaseHistory = $PurchaseHistory." <td class=\"ListCell\">".$RowCount.".</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=order&s=show&oid=".$OrderId."&fs=".$OffSet."&uid=".$uid."\">".$InvoiceNum."</a></td>\n";
      $PurchaseHistory = $PurchaseHistory." <td class=\"ListCell\">".$InvoiceDate."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td class=\"ListCellCenter\">".$WayBillNumber."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td class=\"ListCellRight\">".$OrderTotal."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td class=\"ListCellCenter\">".$PayOption."</td>\n";
      $PurchaseHistory = $PurchaseHistory." <td class=\"ListCell\">".$OrderStatus."</td>\n</tr>\n";
    }
    if ($PurchaseHistory eq "") { $PurchaseHistory = "<tr><td colspan=\"7\"><br>No Purchases to Display<br>&nbsp;</td></tr>\n"; }
    $PurchaseTotal = sprintf("%.2f",$PurchaseTotal);
    $PageHeader = "Buyer Information : $BuyerId";
    $page = "buyer_show";
    &display_page_requested;
  }

  if ($SortType eq "sort") {
    if ($SortData eq "") { $SortData = $form{'SortOption'}; }
    ($SortBy,$SortDirect) = split(/\^/,$SortData);
    if ($SortBy eq "OrderStat") { $SearchFlag = "WHERE OrderStat = '".$SortDirect."' "; }
    else { $SortFlag = "$SortBy $SortDirect "; }
  }
  if ($SortType eq "search") {
    $SearchField = $form{'SearchField'};
    $SearchKey2 = $form{'SearchKey'};
    $SearchKey2 =~ s/- Keyword -//g;
    if (($SearchField ne "") && (length($SearchKey2) > 0)) {
      $SearchFlag = "WHERE OrderStat != '0' AND $SearchField LIKE '%".$SearchKey2."%' ";
      $SortData = $SearchField."^".$SearchKey2;
    }
    else {
      ($SearchField,$SearchKey2) = split(/\^/,$SortData);
      $SearchFlag = "WHERE OrderStat != '0' AND $SearchField LIKE '%".$SearchKey2."%' ";
    }
  }

  if ($step eq "summ") {
    $sql_statement = "SELECT COUNT(*) FROM buyer_base $SearchFlag;";
    $TestString = $TestString.$sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ResultCount = @arr[0];
    $BuyerCount = "0";

    $sql_statement = "SELECT BuyerId FROM buyer_base ".$SearchFlag."ORDER BY ".$SortFlag."LIMIT ".$OffSet.",".$OrderDisplayLimit.";";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($BuyerId) = @arr;
      push(@buyers,$BuyerId);
    }
    foreach $BuyerId(@buyers) {
      $sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      ($XBuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $SurName, $DateOfBirth, $TelAreaCode, $Telephone, $FaxAreaCode, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostalCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DelDayFrom, $DelDayTo) = @arr;
      $RowCount++;
      $sql_statement = "SELECT COUNT(*) FROM order_main WHERE BuyerId = '$BuyerId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      ($PurchaseCount) = @arr;

      $BuyerCount = $RowCount + $OffSet;
      if ($BgFlag eq "1") { $BgFlag = "0"; $BgColor = "#F2F2F2"; } else { $BgFlag = "1"; $BgColor = "#FFFFFF"; }
      &convert_timestamp($SignDate);
      $SignDate = $ConvTimeStamp;
      if ($Company eq "") { $Company = "<span class=\"LowLightText\">-none-</span>"; }

      if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
      $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$RowCount."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=buyer&s=view&bid=".$BuyerId."&fs=".$OffSet."\">".$BuyerId."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=buyer&s=view&bid=".$BuyerId."&fs=".$OffSet."\">".$Title." ".$FirstName." ".$SurName."</a>&nbsp;</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$Company."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$PurchaseCount."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$Country."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellRight\" nowrap>".$SignDate."&nbsp;</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\" nowrap><a href=\"mailto:$MailAddy\"><img src=\"../images/site_admin/email2.png\" width=\"16\" height=\"15\" hspace=\"2\" border=\"0\" alt=\"$MailAddy\"></a><a href=\"#\"><img src=\"../images/site_admin/man.png\" hspace=\"2\" border=\"0\" alt=\"Tel: ($TelArea) $Telephone  Fax: ($FaxArea) $FaxNum\"><a><a href=\"../cgi-bin/dbadmin.pl?f=buyer&s=view&bid=".$BuyerId."&fs=".$OffSet."\"><img src=\"../images/site_admin/user_green.png\" border=\"0\" hspace=\"2\"></a></td>\n</tr>\n";
    }
    if ($ResultCount < 1) { $TableListing = $TableListing."<tr><td align=\"center\" class=\"ListCell\" colspan=\"12\"><br><b>No records found matching your search criteria!</b><br>&nbsp;</td></tr>\n"; }
  
    $StartRecord = $OffSet + 1;
    $ResultText = "Displaying Items <b>$StartRecord</b> to <b>$OrderCount</b> of <b>$ResultCount</b> Items...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $OrderDisplayLimit;
    $OffSet = $OffSet + $OrderDisplayLimit;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $OrderDisplayLimit) { $RNavLink = $RNavLink."&laquo; <a href=\"dbadmin.pl?f=buyer&s=summ&fs=".$PrevLink."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $OrderDisplayLimit;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ResultCount) { $RNavLink = $RNavLink."<a href=\"dbadmin.pl?f=buyer&s=summ&fs=".$TestOffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ResultCount) { $RNavLink = $RNavLink." <a href=\"dbadmin.pl?f=buyer&s=summ&fs=".$OffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
  }
  &populate_buyer_options;
  $PageHeader = "Buyer Information";
  $page = "buyer_view";
  &display_page_requested;

}

sub populate_buyer_options {
    $sql_statement = "SELECT VarName,VarMax FROM system_variables WHERE VarGroup = '5'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($VarName,$VarMax) = @arr;
      if ($SearchField eq $VarName) { $SearchFieldList = $SearchFieldList."<option value=\"".$VarName."\" selected> ".$VarMax." </option>\n"; }
      else { $SearchFieldList = $SearchFieldList."<option value=\"".$VarName."\"> ".$VarMax." </option>\n"; }
    }
    $sql_statement = "SELECT VarName,VarMax FROM system_variables WHERE VarGroup = '6'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($VarName,$VarMax) = @arr;
      if ($SortData eq $VarName) { $SortOptionList = $SortOptionList."<option value=\"".$VarName."\" selected> ".$VarMax." </option>\n"; }
      else { $SortOptionList = $SortOptionList."<option value=\"".$VarName."\"> ".$VarMax." </option>\n"; }
    }
}

#--------------------------------------------------------------------------------------------------------------

sub display_orders_page {
  #$OffSet = "0";
  $OrderId = $info{'oid'};
  $SortFlag = "OrderId DESC ";
  $SearchFlag = "WHERE OrderStat != '0' ";
  $SortData = $info{'sd'};
  $SortType = $info{'sr'};

  if ($step eq "update") {
    $sql_statement = "SELECT AdminComment FROM order_main WHERE OrderId = '$OrderId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($AdminComment) = @arr;    
    $UpdateStatus = $form{'UpdateStatus'};
    $WayBillNumber = $form{'WayBillNumber'};
    $NewAdminComment = $form{'AdminComment'};
    $WayBillNumber =~ s/- Waybill Number -//g;
    $NewAdminComment =~ s/- Comments\/Reason -//g;
    $NewAdminComment =~ s/\cM//g;
    $NewAdminComment =~ s/\n/ /g;
    if ($UpdateStatus eq "1") { $OrderStatus = "Pending"; }
    if ($UpdateStatus eq "2") { $OrderStatus = "Delivered"; }
    if ($UpdateStatus eq "3") { $OrderStatus = "On-Hold"; }
    if ($UpdateStatus eq "4") { $OrderStatus = "Cancelled"; }

    if ($NewAdminComment ne "") { $AdminComment = "$DateNow||$UserName||$OrderStatus||$WayBillNumber||$NewAdminComment||\n".$AdminComment; }
    
    $sql_statement = "UPDATE order_main SET DeliverDate = '$TimeStamp',OrderStat = '$UpdateStatus',WayBillNumber = '$WayBillNumber',AdminComment = '$AdminComment' WHERE OrderId = '$OrderId';";
    $TestString = $TestString."\n".$sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "show";
    $StatusMessage = "0|The status of this order has been updated successfully!";

  }
  if ($step eq "resupdate") {
    $sql_statement = "SELECT AdminComment FROM reseller_order WHERE OrderId = '$OrderId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($AdminComment) = @arr;    
    $UpdateStatus = $form{'UpdateStatus'};
    $WayBillNumber = $form{'WayBillNumber'};
    $NewAdminComment = $form{'AdminComment'};
    $WayBillNumber =~ s/- Waybill Number -//g;
    $NewAdminComment =~ s/- Comments\/Reason -//g;
    $NewAdminComment =~ s/\cM//g;
    $NewAdminComment =~ s/\n/ /g;
    if ($UpdateStatus eq "1") { $OrderStatus = "Pending"; }
    if ($UpdateStatus eq "2") { $OrderStatus = "Delivered"; }
    if ($UpdateStatus eq "3") { $OrderStatus = "On-Hold"; }
    if ($UpdateStatus eq "4") { $OrderStatus = "Cancelled"; }

    if ($NewAdminComment ne "") { $AdminComment = "$DateNow||$UserName||$OrderStatus||$WayBillNumber||$NewAdminComment||\n".$AdminComment; }
    
    $sql_statement = "UPDATE reseller_order SET DeliverDate = '$TimeStamp',OrderStat = '$UpdateStatus',WayBillNumber = '$WayBillNumber',AdminComment = '$AdminComment' WHERE OrderId = '$OrderId';";
    $TestString = $TestString."\n".$sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "reshow";
    $StatusMessage = "0|The status of this order has been updated successfully!";

  }
  if ($step eq "show") {
    $sql_statement = "SELECT * FROM order_main WHERE OrderId = '$OrderId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($OrderId, $OrderStat, $PayOption, $BuyerId, $XSessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderWeight, $OptionDel, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
    #($OrderId, $OrderStat, $PayOption, $BuyerId, $XSessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderWeight, $OptionDel, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;

    &convert_timestamp($XTimeStamp);
    $InvoiceDate = $ConvTimeStamp;
    if ($OrderStat eq "2") { &convert_timestamp($DeliverDate); $DeliverDate = $ConvTimeStamp; }
    else { $DeliverDate = "---"; }
    $sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($BuyerId, $BuyFlag, $BSessionId, $BSignDate, $MailAddy, $PassWord, $Title, $FirstName, $SurName, $DateOfBirth, $TelAreaCode, $Telephone, $FaxAreaCode, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostalCode, $Country, $BPayOption, $BPayNotes, $BDeliverFrom, $BDeliverTo, $DelBDayFrom, $BDelDayTo) = @arr;
    $sql_statement = "SELECT CountryName FROM countrycodes WHERE CountryCode = '$Country'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $CountryName = @arr[0];
    
    $sql_statement = "SELECT SafePayRefNr,BankRefNr FROM safe_shop WHERE BuyerId = '$BuyerId' AND LogRefNr = '$InvoiceNum';";
    $TestString = $sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($SafePayRefNr,$BankRefNr) = @arr;
    
    @comments = split(/\n/,$AdminComment);
    $AdminComment = "";
    foreach $Comment(@comments) {
      ($DateThen,$XUserName,$XOrderStatus,$XWayBillNumber,$XComments) = split(/\|\|/,$Comment);
      if ($XUserName ne "") { $AdminComment = $AdminComment."User: <b>$XUserName</b> Date: $DateThen<br>Status Changed: $XOrderStatus $XWayBillNumber<br><span class=\"LowLightText\">$XComments</span><br>----------<br>"; }
      else { $AdminComment = $AdminComment."<span class=\"LowLightText\">$Comment</span><br>----------<br>"; }
    }
    
    if ($OrderStat eq "0") { $OrderStat = "Incomplete<img hspace=\"1\" src=\"../images/site_admin/lock.png\" border=\"0\" alt=\"Incomplete\" align=\"absmiddle\">"; }
    elsif ($OrderStat eq "1") { $OrderStat = "Pending<img hspace=\"1\" src=\"../images/site_admin/waiting.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($OrderStat eq "2") { $OrderStat = "Delivered<img hspace=\"1\" src=\"../images/site_admin/delivery.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($OrderStat eq "3") { $OrderStat = "On-Hold<img hspace=\"1\" src=\"../images/site_admin/on_hold.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($OrderStat eq "4") { $OrderStat = "Cancelled<img hspace=\"1\" src=\"../images/site_admin/cancel.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }  

    if ($PayOption eq "TX") { $InvoiceNum = "PF".$InvoiceNum; }
    $sql_statement = "SELECT * FROM order_items WHERE OrderId = '$OrderId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($ItemId, $BuyerId, $OrderId, $TimeStamp, $Level1, $Level2, $Level3, $ProdId, $OrderCode, $ProdName, $OrderQty, $OrderPrice, $OrderWeight, $DelCharge, $ItemFlag) = @arr;
      $ItemTotal = $OrderPrice * $OrderQty;
      $ItemTotal = sprintf("%.2f",$ItemTotal);
      $InvoiceString = $InvoiceString."<tr>\n <td class=\"ListCell\">$OrderCode</td>\n";
      $InvoiceString = $InvoiceString." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=prods&s=show&pid=".$ProdId."\">".$ProdName."</a></td>\n";
      $InvoiceString = $InvoiceString." <td class=\"ListCellCenter\">$OrderQty</td>\n";
      $InvoiceString = $InvoiceString." <td class=\"ListCellRight\">$OrderPrice</td>\n";
      $InvoiceString = $InvoiceString." <td class=\"ListCellRight\">$ItemTotal</td>\n</tr>\n";
    }

  	$sql_statement = "SELECT OptionName,DeliverTime,DeliverMax FROM deliver_options WHERE DelId = '$OptionDel';";
    $sth = $dbh->query($sql_statement);
    @arr = $sth->fetchrow;
  	($OptionName,$DeliverTime,$DeliverMax) = @arr;
  	$EstDeliver = $XTimeStamp + $DeliverMax;
  	&convert_timestamp($EstDeliver);
  	$EstDeliver = $ConvTimeStampShort;
    
    $PageHeader = "Displaying Invoice : $InvoiceNum";
    $page = "order_show";
    &display_page_requested;    
  }
  if ($step eq "reshow") {
    $sql_statement = "SELECT * FROM reseller_order WHERE OrderId = '$OrderId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($OrderId, $OrderStat, $PayOption, $ResId, $XSessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderNumber, $DeliverOption, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $DeliverAddress, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
    &convert_timestamp($XTimeStamp);
    $InvoiceDate = $ConvTimeStamp;
    &convert_timestamp($DeliverDate);
    $DeliverDate = $ConvTimeStamp;
    $sql_statement = "SELECT * FROM reseller_details WHERE ResId = '$ResId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($ResId, $StatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $PassWord, $ActiveCode, $SessionId, $DiscountRate, $AcceptTerms, $AccountNumber, $BusinessDescript) = @arr;
    $sql_statement = "SELECT CountryName FROM countrycodes WHERE CountryCode = '$Country'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $CountryName = @arr[0];
    
    $sql_statement = "SELECT SafePayRefNr,BankRefNr FROM safe_shop WHERE BuyerId = '$BuyerId' AND LogRefNr = '$InvoiceNum';";
    $TestString = $sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($SafePayRefNr,$BankRefNr) = @arr;
    
    if ($OrderStat eq "0") { $OrderStatus = "Incomplete<img hspace=\"1\" src=\"../images/site_admin/lock.png\" border=\"0\" alt=\"Incomplete\" align=\"absmiddle\">"; }
    elsif ($OrderStat eq "1") { $OrderStatus = "Pending<img hspace=\"1\" src=\"../images/site_admin/waiting.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($OrderStat eq "2") { $OrderStatus = "Delivered<img hspace=\"1\" src=\"../images/site_admin/delivery.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($OrderStat eq "3") { $OrderStatus = "On-Hold<img hspace=\"1\" src=\"../images/site_admin/on_hold.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($OrderStat eq "4") { $OrderStatus = "Cancelled<img hspace=\"1\" src=\"../images/site_admin/cancel.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }  
    if ($PayOption eq "TX") { $InvoiceNum = "PF".$InvoiceNum; }

    @comments = split(/\n/,$AdminComment);
    $AdminComment = "";
    foreach $Comment(@comments) {
      ($DateThen,$XUserName,$XOrderStatus,$XWayBillNumber,$XComments) = split(/\|\|/,$Comment);
      if ($XUserName ne "") { $AdminComment = $AdminComment."User: <b>$XUserName</b> Date: $DateThen<br>Status Changed: $XOrderStatus $XWayBillNumber<br><span class=\"LowLightText\">$XComments</span><br>----------<br>"; }
      else { $AdminComment = $AdminComment."<span class=\"LowLightText\">$Comment</span><br>----------<br>"; }
    }

    $sql_statement = "SELECT * FROM reseller_items WHERE OrderId = '$OrderId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($ItemId, $BuyerId, $OrderId, $TimeStamp, $Level1, $Level2, $Level3, $ProdId, $OrderCode, $ProdName, $OrderQty, $OrderPrice, $OrderWeight, $DelCharge, $ItemFlag) = @arr;
      $ItemTotal = $OrderPrice * $OrderQty;
      $ItemTotal = sprintf("%.2f",$ItemTotal);
      $InvoiceString = $InvoiceString."<tr>\n <td class=\"ListCell\">$OrderCode</td>\n";
      $InvoiceString = $InvoiceString." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=prods&s=show&pid=".$ProdId."&uid=".$uid."\">".$ProdName."</a></td>\n";
      $InvoiceString = $InvoiceString." <td class=\"ListCellCenter\">$OrderQty</td>\n";
      $InvoiceString = $InvoiceString." <td class=\"ListCellRight\">$OrderPrice</td>\n";
      $InvoiceString = $InvoiceString." <td class=\"ListCellRight\">$ItemTotal</td>\n</tr>\n";
    }
    
    $PageHeader = "Displaying Invoice : $InvoiceNum";
    $page = "reseller_order";
    &display_page_requested;    
  }
  if ($SortType eq "sort") {
    if ($SortData eq "") { $SortData = $form{'SortOption'}; }
    ($SortBy,$SortDirect) = split(/\^/,$SortData);
    if ($SortBy eq "OrderStat") { $SearchFlag = "WHERE OrderStat = '".$SortDirect."' "; }
    else { $SortFlag = "$SortBy $SortDirect "; }
  }
  if ($SortType eq "search") {
    $SearchField = $form{'SearchField'};
    $SearchKey2 = $form{'SearchKey2'};
    $SearchKey2 =~ s/- Keyword -//g;
    if (($SearchField ne "") && (length($SearchKey2) > 0)) {
      $SearchFlag = "WHERE OrderStat != '0' AND $SearchField LIKE '%".$SearchKey2."%' ";
      $SortData = $SearchField."^".$SearchKey2;
    }
    else {
      ($SearchField,$SearchKey2) = split(/\^/,$SortData);
      $SearchFlag = "WHERE OrderStat != '0' AND $SearchField LIKE '%".$SearchKey2."%' ";
    }
  }

  if ($step eq "view") {
    $sql_statement = "SELECT COUNT(*) FROM order_main $SearchFlag;";
    $TestString = $TestString.$sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ResultCount = @arr[0];
    $OrderCount = "0";

    $sql_statement = "SELECT * FROM order_main ".$SearchFlag."ORDER BY ".$SortFlag."LIMIT ".$OffSet.",".$OrderDisplayLimit.";";
    $TestString = $TestString."\n".$sql_statement;
    #$sql_statement = "SELECT * FROM order_main ORDER BY ".$SortFlag."LIMIT ".$OffSet.",".$OrderDisplayLimit.";";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($OrderId, $OrderStat, $PayOption, $BuyerId, $XSessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderWeight, $OptionDel, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
      #($OrderId, $OrderStat, $PayOption, $BuyerId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderTotal, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $CurrencyMark, $WayBillNumber) = @arr;
      $RowCount++;
      $OrderCount = $RowCount + $OffSet;
      #if ($step eq "search") { $TableListing =~ s/$SearchKey/\<span class=\"highlightsearch\"\>$SearchKey\<\/span\>/gi; }
      if ($OrderStat eq "1") { $PendMark = "mark_gr"; } else { $PendMark = "mark_wh"; }
      if ($OrderStat eq "2") { $DeliverMark = "mark_gr"; } else { $DeliverMark = "mark_wh"; }
      if ($OrderStat eq "3") { $HoldMark = "mark_gr"; } else { $HoldMark = "mark_wh"; }
      if ($OrderStat eq "4") { $CancelMark = "mark_gr"; } else { $CancelMark = "mark_wh"; }
      &convert_timestamp($XTimeStamp);
      $InvoiceDate = $ConvTimeStamp;
      if ($WayBillNumber eq "") { $WayBillNumber = "---"; }
      if ($PayOption eq "TX") { $InvoiceNum = "PF".$InvoiceNum; }
      
      $OptionString = "<a href=\"../cgi-bin/dbadmin.pl?f=order&s=show&oid=".$OrderId."&fs=".$OffSet."&uid=".$uid."\" title=\"View Invoice\"><img src=\"../images/site_admin/blank.png\" border=\"0\" hspace=\"2\" alt=\"View Invoice\"></a>";
      $OptionString = $OptionString."<a href=\"../cgi-bin/dbadmin.pl?f=buyer&s=view&bid=".$BuyerId."&fs=".$OffSet."&uid=".$uid."\" title=\"View Buyer Info\"><img src=\"../images/site_admin/user_green.png\" border=\"0\" hspace=\"2\" alt=\"View Buyer Info\"></a>";
      

      if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
      $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$OrderCount."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=order&s=show&oid=".$OrderId."&fs=".$OffSet."&uid=".$uid."\">".$InvoiceNum."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$InvoiceDate."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=buyer&s=view&bid=".$BuyerId."&fs=".$OffSet."&uid=".$uid."\">".$BuyerId."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellRight\">".$OrderTotal."&nbsp;</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$WayBillNumber."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$PayOption."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><img src=\"../images/site_admin/".$PendMark.".gif\"></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><img src=\"../images/site_admin/".$DeliverMark.".gif\"></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><img src=\"../images/site_admin/".$HoldMark.".gif\"></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><img src=\"../images/site_admin/".$CancelMark.".gif\"></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$OptionString."</td>\n</tr>\n";
      $OptionString = "";
    }
    if ($ResultCount < 1) { $TableListing = $TableListing."<tr><td align=\"center\" class=\"ListCell\" colspan=\"12\"><br><b>No records found matching your search criteria!</b><br>&nbsp;</td></tr>\n"; }
  
    $StartRecord = $OffSet + 1;
    $ResultText = "Displaying Items <b>$StartRecord</b> to <b>$OrderCount</b> of <b>$ResultCount</b> Items...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $OrderDisplayLimit;
    $OffSet = $OffSet + $OrderDisplayLimit;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $OrderDisplayLimit) { $RNavLink = $RNavLink."&laquo; <a href=\"dbadmin.pl?f=order&s=view&fs=".$PrevLink."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $OrderDisplayLimit;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ResultCount) { $RNavLink = $RNavLink."<a href=\"dbadmin.pl?f=order&s=view&fs=".$TestOffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ResultCount) { $RNavLink = $RNavLink." <a href=\"dbadmin.pl?f=order&s=view&fs=".$OffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }

    $PageHeader = "Customer Order Summary";
    $page = "order_view";
  }
  if ($step eq "resview") {
    $sql_statement = "SELECT COUNT(*) FROM reseller_order $SearchFlag;";
    $TestString = $TestString.$sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ResultCount = @arr[0];
    $OrderCount = "0";

    $sql_statement = "SELECT * FROM reseller_order ".$SearchFlag."ORDER BY ".$SortFlag."LIMIT ".$OffSet.",".$OrderDisplayLimit.";";
    $TestString = $TestString."\n".$sql_statement;
    #$sql_statement = "SELECT * FROM order_main ORDER BY ".$SortFlag."LIMIT ".$OffSet.",".$OrderDisplayLimit.";";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($OrderId, $OrderStat, $PayOption, $ResId, $XSessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderNumber, $DeliverOption, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $DeliverAddress, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
      #($OrderId, $OrderStat, $PayOption, $BuyerId, $XSessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderWeight, $OptionDel, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
      #($OrderId, $OrderStat, $PayOption, $BuyerId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderTotal, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $CurrencyMark, $WayBillNumber) = @arr;
      $RowCount++;
      $OrderCount = $RowCount + $OffSet;
      #if ($step eq "search") { $TableListing =~ s/$SearchKey/\<span class=\"highlightsearch\"\>$SearchKey\<\/span\>/gi; }
      if ($OrderStat eq "1") { $PendMark = "mark_gr"; } else { $PendMark = "mark_wh"; }
      if ($OrderStat eq "2") { $DeliverMark = "mark_gr"; } else { $DeliverMark = "mark_wh"; }
      if ($OrderStat eq "3") { $HoldMark = "mark_gr"; } else { $HoldMark = "mark_wh"; }
      if ($OrderStat eq "4") { $CancelMark = "mark_gr"; } else { $CancelMark = "mark_wh"; }
      &convert_timestamp($XTimeStamp);
      $InvoiceDate = $ConvTimeStamp;
      if ($WayBillNumber eq "") { $WayBillNumber = "---"; }
      if ($PayOption eq "TX") { $InvoiceNum = "PF".$InvoiceNum; }
      
      $OptionString = "<a href=\"../cgi-bin/dbadmin.pl?f=order&s=reshow&oid=".$OrderId."&fs=".$OffSet."\" title=\"View Invoice\"><img src=\"../images/site_admin/blank.png\" border=\"0\" hspace=\"2\" alt=\"View Invoice\"></a>";
      $OptionString = $OptionString."<a href=\"../cgi-bin/dbadmin.pl?f=reseller&s=view&rid=".$ResId."&fs=".$OffSet."\" title=\"View Reseller Info\"><img src=\"../images/site_admin/user_green.png\" border=\"0\" hspace=\"2\" alt=\"View Buyer Info\"></a>";
      

      if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
      $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$OrderCount."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=order&s=reshow&oid=".$OrderId."&fs=".$OffSet."\">".$InvoiceNum."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\">".$InvoiceDate."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCell\"><a href=\"../cgi-bin/dbadmin.pl?f=reseller&s=view&rid=".$ResId."&fs=".$OffSet."\">".$ResId."</a></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellRight\">".$OrderTotal."&nbsp;</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$WayBillNumber."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$PayOption."</td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><img src=\"../images/site_admin/".$PendMark.".gif\"></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><img src=\"../images/site_admin/".$DeliverMark.".gif\"></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><img src=\"../images/site_admin/".$HoldMark.".gif\"></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\"><img src=\"../images/site_admin/".$CancelMark.".gif\"></td>\n";
      $TableListing = $TableListing." <td class=\"ListCellCenter\">".$OptionString."</td>\n</tr>\n";
      $OptionString = "";
    }
    if ($ResultCount < 1) { $TableListing = $TableListing."<tr><td align=\"center\" class=\"ListCell\" colspan=\"12\"><br><b>No records found matching your search criteria!</b><br>&nbsp;</td></tr>\n"; }
  
    $StartRecord = $OffSet + 1;
    $ResultText = "Displaying Items <b>$StartRecord</b> to <b>$OrderCount</b> of <b>$ResultCount</b> Items...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $OrderDisplayLimit;
    $OffSet = $OffSet + $OrderDisplayLimit;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $OrderDisplayLimit) { $RNavLink = $RNavLink."&laquo; <a href=\"dbadmin.pl?f=order&s=view&fs=".$PrevLink."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $OrderDisplayLimit;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ResultCount) { $RNavLink = $RNavLink."<a href=\"dbadmin.pl?f=order&s=view&fs=".$TestOffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ResultCount) { $RNavLink = $RNavLink." <a href=\"dbadmin.pl?f=order&s=view&fs=".$OffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&br=&uid=".$uid."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }

    $PageHeader = "Reseller Order Summary";
    $page = "reseller_ordview";
  }
  &populate_order_options;


  &display_page_requested;

}

sub populate_order_options {
    $sql_statement = "SELECT VarName,VarMax FROM system_variables WHERE VarGroup = '3'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($VarName,$VarMax) = @arr;
      if ($SearchField eq $VarName) { $SearchFieldList = $SearchFieldList."<option value=\"".$VarName."\" selected> ".$VarMax." </option>\n"; }
      else { $SearchFieldList = $SearchFieldList."<option value=\"".$VarName."\"> ".$VarMax." </option>\n"; }
    }
    $sql_statement = "SELECT VarName,VarMax FROM system_variables WHERE VarGroup = '4'";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($VarName,$VarMax) = @arr;
      if ($SortData eq $VarName) { $SortOptionList = $SortOptionList."<option value=\"".$VarName."\" selected> ".$VarMax." </option>\n"; }
      else { $SortOptionList = $SortOptionList."<option value=\"".$VarName."\"> ".$VarMax." </option>\n"; }
    }
}

#--------------------------------------------------------------------------------------------------------------
sub display_category_page {

if ($step eq "mvsave") {
  &parse_category_form;
  ($DLevel1,$DLevel2) = split(/\^/,$DestinationCat);
  if ($CLevel2 ne "100") {
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
    $next_sql_statement = "UPDATE prod_base SET Level1 = '$DLevel1',Level2 = '$DLevel2' WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
  }
  else {
    $sql_statement = "SELECT MAX(Level2) FROM cat_base WHERE Level1 = '$DLevel1';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ALevel2 = @arr[0];
    $ALevel2++;
    $sql_statement = "INSERT INTO cat_base VALUES ('$CatId','$DLevel1','$ALevel2','100','New Category','','Temporary Category Created By Move Command');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 != '100';";
    $next_sql_statement = "UPDATE prod_base SET Level1 = '$DLevel1',Level2 = '$ALevel2' WHERE Level1 = '$CLevel1' AND Level2 != '100';";
  }
  $XTestString = $sql_statement;
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $ProdCount = @arr[0];
#  if ($ProdCount > 0) {
    $sql_statement = $next_sql_statement;
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $AlertPrompt = "$ProdCount products were moved successfully!";
    $XTestString = $sql_statement;
#  }
#  else { $AlertPrompt = "$ProdCount products were moved successfully!"; }
  
  $ALevel1 = $DLevel1;
  $ALevel2 = $DLevel2;
  $CLevel1 = $DLevel1;
  $CLevel2 = $DLevel2;
  $NewCatName = "";
  $NewCatDesc = "";
  if ($DLevel2 ne "100") { $step = "show"; } else { $step = "view"; }
}

if ($step eq "move") {

  $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $XCatName = @arr[0];

  if ($CLevel2 ne "100") {
    $sql_statement = "SELECT CatName,CatDescript FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $YCatName = @arr[0];
  
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ProdCount = @arr[0];
  }
  else {
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 != '100';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ProdCount = @arr[0];
  }    
  $MoveCatText = "Move all <b>$ProdCount</b> products in Category <b>$XCatName</b> &raquo; <b>$YCatName</b> to:"; 
  
  $BypassTop = "1";
  &populate_category_list;
  $PageHeader = "Move Products in Category";
  $page = "category_move";
}
if ($step eq "edit") {
  $sql_statement = "SELECT CatName,CatDescript FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' AND Level3 = '$CLevel3';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($NewCatName,$NewCatDesc) = @arr;
  $PageHeader = "Edit Category : $NewCatName";
  $page = "category_edit";
}
if ($step eq "edsave") {
  &parse_category_form;
  $sql_statement = "UPDATE cat_base SET CatName = '$EditCatName',CatDescript = '$EditCatDesc',CatImage = '$EditCatImage' WHERE CatId = '$EditCatId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  $ALevel1 = $EditLevel1;
  $ALevel2 = $EditLevel2;
  $ALevel3 = $EditLevel3;
  $NewCatName = "";
  $NewCatDesc = "";
  $StatusMessage = "0|Category '$EditCatName' was updated successfully!";
  if ($CLevel3 ne "100") { $step = "view3"; }
  elsif ($CLevel2 ne "100") { $step = "view2"; }
  else { $step = "view"; }
}
if ($step eq "delete") {
  $sql_statement = "SELECT CatName,CatId FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' LIMIT 0,1;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($CatName,$CatId) = @arr;
  $sql_statement = "DELETE FROM cat_base WHERE CatId = '$CatId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  $StatusMessage = "0|Category '$CatId:$CatName' was deleted successfully!";
  if ($CLevel3 ne "100") { $step = "view3"; }
  elsif ($CLevel2 ne "100") { $step = "view2"; }
  else { $step = "view"; }
}
if ($step eq "add_3") {
  &parse_category_form;
  $sql_statement = "SELECT COUNT(*) FROM cat_base WHERE CatName LIKE '$NewCatName' AND Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $TestCNT = @arr[0];
  if ($TestCNT > 0) { $AlertPrompt = "Error: A category already exists with the name '$NewCatName'\\nPlease enter a unique name for your new category!"; }
  else {
    $sql_statement = "SELECT MAX(Level3) FROM cat_base WHERE Level1 = '$CLevel1' AND  Level2 = '$CLevel2';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ALevel3 = @arr[0];
    if ($ALevel3 < 100) { $ALevel3 = '100'; }
    $ALevel3++;
    $sql_statement = "INSERT INTO cat_base VALUES ('$CatId','$CLevel1','$CLevel2','$ALevel3','$NewCatName','$NewCatImage','$NewCatDesc');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $StatusMessage = "0|Category '$NewCatName' was created successfully!";
    $NewCatName = "";
    $NewCatDesc = "";
    $NewCatIcon = "";
  }
  $step = "view3";
  $RNavLink = "<a href=\"dbadmin.pl?f=cats&s=view2&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\"><img src=\"../images/site_admin/arrow_l.gif\" width=\"7\" height=\"7\" hspace=\"3\" border=\"0\">Back to Top Level Category</a>";
}
if ($step eq "add_2") {
  &parse_category_form;
  $sql_statement = "SELECT COUNT(*) FROM cat_base WHERE CatName LIKE '$NewCatName' AND Level1 = '$CLevel1';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $TestCNT = @arr[0];
  if ($TestCNT > 0) { $AlertPrompt = "Error: A category already exists with the name '$NewCatName'\\nPlease enter a unique name for your new category!"; }
  else {
    $sql_statement = "SELECT MAX(Level2) FROM cat_base WHERE Level1 = '$CLevel1';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ALevel2 = @arr[0];
    if ($ALevel2 < 100) { $ALevel2 = '100'; }
    $ALevel2++;
    $sql_statement = "INSERT INTO cat_base VALUES ('$CatId','$CLevel1','$ALevel2','100','$NewCatName','$NewCatImage','$NewCatDesc');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $StatusMessage = "0|Category '$NewCatName' was created successfully!";
    $NewCatName = "";
    $NewCatDesc = "";
    $NewCatIcon = "";
  }
  $step = "view2";
  $RNavLink = "<a href=\"dbadmin.pl?f=cats&s=view&mct=".$CLevel1."&uid=".$uid."\"><img src=\"../images/site_admin/arrow_l.gif\" width=\"7\" height=\"7\" hspace=\"3\" border=\"0\">Back to Top Level Category</a>";
}
if ($step eq "add_1") {
  &parse_category_form;
  $sql_statement = "SELECT COUNT(*) FROM cat_base WHERE CatName LIKE '$NewCatName' AND Level1 != '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $TestCNT = @arr[0];
  if ($TestCNT > 0) { $AlertPrompt = "Error: A category already exists with the name '$NewCatName'\\nPlease enter a unique name for your new category!"; }
  else {
    $sql_statement = "SELECT MAX(Level1) FROM cat_base WHERE Level1 != '100';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ALevel1 = @arr[0];
    if ($ALevel1 < 100) { $ALevel1 = '100'; }
    $ALevel1++;
    $sql_statement = "INSERT INTO cat_base VALUES ('$CatId','$ALevel1','100','100','$NewCatName','$NewCatImage','$NewCatDesc');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $StatusMessage = "0|Category '$NewCatName' was created successfully!";
    $NewCatName = "";
    $NewCatDesc = "";
    $NewCatIcon = "";
  }
  $step = "view";
  #$RNavLink = "<a href=\"dbadmin.pl?f=cats&s=view&uid=".$uid."\"><img src=\"../images/site_admin/arrow_l.gif\" width=\"7\" height=\"7\" hspace=\"3\" border=\"0\">Back to Top Level Category</a>";
}

if ($step eq "view3") {
  $CLevel3 = "100";
  $sql_statement = "SELECT Level3,CatName,CatDescript,CatId FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' AND Level3 != '100' ORDER BY CatName;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($CLevel3,$CatName,$CatDescript,$CatId) = @arr;
    $Temp = $CLevel3."|".$CatName."|".$CatDescript."|".$CatId;
    push(@mcats,$Temp);
  }
  foreach $Temp(@mcats) {
    ($CLevel3,$CatName,$CatDescript,$CatId) = split(/\|/,$Temp);
    $ProdCount = "0";
    $sql_statement = "SELECT COUNT(*) FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' AND Level3 = '$CLevel3';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $SubCount = @arr[0];
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND  Level2 = '$CLevel2' AND Level3 = '$CLevel3';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ProdCount = @arr[0];
    if ($ALevel3 eq $CLevel3) { $CatNameText = "<b>$CatName</b>"; } else { $CatNameText = $CatName; }
    if ($SubCountX > 0) { $CatNameText = "<img src=\"../images/site_admin/mecl.gif\" align=\"absmiddle\" border=\"0\" hspace=\"2\">".$CatNameText; }
    else { $CatNameText = "<img src=\"../images/site_admin/meop.gif\" align=\"absmiddle\" border=\"0\" hspace=\"2\">".$CatNameText; }
    $RowCount++;
    if ($BgFlag eq "1") { $BgFlag = "0"; $BgColor = "#F2F2F2"; } else { $BgFlag = "1"; $BgColor = "#FFFFFF"; }
    if ($ProdCount eq "0") { $DeleteLink = "<a href=\"javascript:DeleteCategory('".$CLevel1."','".$CLevel2."','".$CLevel3."','".$uid."');\"><img src=\"../images/site_admin/stop.png\" alt=\"Delete '$CatName'\" border=\"0\"></a>"; }
    else { $DeleteLink = "<a class=\"DisableImage\"><img src=\"../images/site_admin/stop.png\" border=\"0\"></a>"; }

    $ImagePath = $CatImagePath.$CLevel1.$CLevel2.".jpg";
    if (-e $ImagePath) { $CatImage = $CLevel1.$CLevel2.".jpg"; } else { $CatImage = "none.gif"; }

    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $TableListing = $TableListing." <td class=\"ListCell\" valign=\"top\"><a href=\"dbadmin.pl?f=cats&s=view3&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\">".$CatNameText."</a></td>\n";
    $TableListing = $TableListing." <td class=\"ListCell\" valign=\"top\">".$CatDescript."&nbsp;</td>\n";
    $TableListing = $TableListing." <td class=\"ListCellCenter\" valign=\"top\">$ProdCount</td>\n";
    $TableListing = $TableListing." <td nowrap class=\"ListCellCenter\" valign=\"top\"><a href=\"javascript:AddToClipBoard('C','$CatId');\"><img src=\"../images/site_admin/paste.png\" alt=\"Clipboard '".$CatName."'\" border=\"0\" hspace=\"1\"></a><a href=\"dbadmin.pl?f=cats&s=view3&mct=".$CLevel1."&sct=".$CLevel2."&pct=100&uid=".$uid."\"><img src=\"../images/site_admin/www2.png\" alt=\"View '$CatName'\" border=\"0\"></a><a href=\"dbadmin.pl?f=cats&s=edit&mct=".$CLevel1."&sct=".$CLevel2."&pct=".$CLevel3."&uid=".$uid."\"><img src=\"../images/site_admin/file_edit.png\" alt=\"Edit '$CatName'\" hspace=\"2\" border=\"0\"></a><img src=\"../images/site_admin/blank.gif\" hspace=\"2\" border=\"0\">".$DeleteLink."</td>\n</tr>\n";
    $CatCount++;


    #else { $DeleteLink = "<img src=\"../images/site_admin/blank.gif\" border=\"0\">"; }
    #$TableListing = $TableListing."<tr onmouseover=\"setPointer(this, $RowCount, 'over', '".$BgColor."', '#CCFFCC', '#FFCC99');\" onmouseout=\"setPointer(this, $RowCount, 'out', '".$BgColor."', '#CCFFCC', '#FFCC99');\" onmousedown=\"setPointer(this, $RowCount, 'click', '".$BgColor."', '#CCFFCC', '#FFCC99');\">\n";
    #$TableListing = $TableListing." <td bgcolor=\"".$BgColor."\">".$CatNameText."</td>\n <td bgcolor=\"".$BgColor."\">".$CatDescript."&nbsp;</td>\n";
    #$TableListing = $TableListing." <td align=\"center\" bgcolor=\"".$BgColor."\">$ProdCount</td>\n <td nowrap bgcolor=\"".$BgColor."\"><a href=\"dbadmin.pl?f=cats&s=edit&mct=".$CLevel1."&sct=".$CLevel2."&pct=".$CLevel3."&uid=".$uid."\"><img src=\"../images/site_admin/file_edit.png\" alt=\"Edit '$CatName'\" hspace=\"2\" border=\"0\"></a><img src=\"../images/site_admin/blank.gif\" hspace=\"2\" border=\"0\">".$DeleteLink."</td>\n</tr>\n";
  }

  $PageHeader = "Level 3 Category Management";
  $page = "category_view";
  $CatStep = "add_3";
  $RNavLink = "<a href=\"dbadmin.pl?f=cats&s=view2&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\"><img src=\"../images/site_admin/arrow_l.gif\" width=\"7\" height=\"7\" hspace=\"3\" border=\"0\">Back to Level 2 Category</a>";
  $CatLevel = "Level 3";
  
  $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $CatText1 = @arr[0];
  $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $CatText2 = @arr[0];
  $CatPath = "Category Path: <b>$CatText1</b> &raquo; <b>$CatText2</b>";
  if ($CatCount == 0) { $TableListing = $TableListing."<tr class=\"ListStyle3\"><td colspan=\"4\" class=\"ListCellCenter\">No Categories found in $CatLevel</td></tr>\n"; }

}

if ($step eq "view2") {
  $CLevel3 = "100";
  $sql_statement = "SELECT CatName,CatDescript,CatId,CatImage FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100' AND Level3 = '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($MainCatName,$MainCatDescript,$MainCatId,$MainCatImage) = @arr;
  if (($MainCatImage eq "") || ($MainCatImage eq "default")) {
    $ImagePath = $CatImagePath.$CLevel1.$CLevel2.".jpg";
    if (-e $ImagePath) { $MainCatImage = $CLevel1.$CLevel2.".jpg"; } else { $MainCatImage = "none.gif"; }
  }

  $sql_statement = "SELECT Level2,CatName,CatDescript,CatId,CatImage FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 != '100' AND Level3 = '100' ORDER BY CatName;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($CLevel2,$CatName,$CatDescript,$CatId,$CatImage) = @arr;
    push(@mcats,"$CLevel2|$CatName|$CatDescript|$CatId|$CatImage");
  }
  foreach $Temp(@mcats) {
    ($CLevel2,$CatName,$CatDescript,$CatId,$CatImage) = split(/\|/,$Temp);
    $ProdCount = "0";
    $sql_statement = "SELECT COUNT(*) FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' AND Level3 != '100';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $SubCount = @arr[0];
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND  Level2 = '$CLevel2';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ProdCount = @arr[0];
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    if ($ALevel2 eq $CLevel2) { $BgClass = "ListStyle3"; $CatNameText = "<b>$CatName</b>"; } else { $CatNameText = $CatName; }
    if ($SubCount > 0) { $CatNameText = "<img src=\"../images/site_admin/folder_add.png\" align=\"absmiddle\" border=\"0\" hspace=\"2\">".$CatNameText; }
    else { $CatNameText = "<img src=\"../images/site_admin/folder.png\" align=\"absmiddle\" border=\"0\" hspace=\"2\">".$CatNameText; }
    $RowCount++;
    if ($BgFlag eq "1") { $BgFlag = "0"; $BgColor = "#F2F2F2"; } else { $BgFlag = "1"; $BgColor = "#FFFFFF"; }
    if ($ProdCount eq "0") {
      $DeleteLink = "<a href=\"javascript:DeleteCategory('".$CLevel1."','".$CLevel2."','".$CLevel3."','".$uid."');\" title=\"Delete '$CatName'\"><img src=\"../images/site_admin/stop.png\" alt=\"Delete '$CatName'\" border=\"0\" hspace=\"2\"></a>";
      $ViewProdLink = "<a class=\"DisableImage\"><img src=\"../images/site_admin/window_cascade.png\" border=\"0\" hspace=\"2\"></a>";
    }
    else {
      $DeleteLink = "<a class=\"DisableImage\"><img src=\"../images/site_admin/stop.png\" border=\"0\" hspace=\"2\"></a>";
      $ViewProdLink = "<a href=\"dbadmin.pl?f=prods&s=sort&fs=0&mk=link&sr=DisplayCat&sd=".$CLevel1."^".$CLevel2."^".$CLevel3."\"><img src=\"../images/site_admin/window_cascade.png\" alt=\"View Products in '$CatName'\" border=\"0\" hspace=\"2\"></a>";
    }
    $PreviewSiteLink = "<a href=\"index.pl?fn=cview&mct=$CLevel1&sct=$CLevel2\" target=\"_blank\" title=\"Preview Site\"><img src=\"../images/site_admin/www2.png\" alt=\"Preview Site\" border=\"0\" hspace=\"2\" hspace=\"2\"></a>";

    if ($CatImage eq "") {
      $ImagePath = $CatImagePath.$CLevel1.$CLevel2.".jpg";
      if (-e $ImagePath) { $CatImage = $CLevel1.$CLevel2.".jpg"; } else { $CatImage = "none.gif"; }
    }

    $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $TableListing = $TableListing." <td class=\"ListCell\" valign=\"top\"><!--<a href=\"dbadmin.pl?f=cats&s=view3&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\">-->".$CatNameText."</td>\n";
    $TableListing = $TableListing." <td class=\"ListCell\" valign=\"top\">".$CatDescript."&nbsp;</td>\n";
    $TableListing = $TableListing." <td class=\"ListCellCenter\" valign=\"top\">$ProdCount</td>\n";
    $TableListing = $TableListing." <td nowrap class=\"ListCellCenter\" valign=\"top\"><a href=\"javascript:AddToClipBoard('C','$CatId');\"><img src=\"../images/site_admin/paste.png\" alt=\"Clipboard '".$CatName."'\" border=\"0\" hspace=\"1\"></a>".$ViewProdLink."".$PreviewSiteLink."<a href=\"javascript:EditCategory('editform','$CatName','$CatDescript','$CatImage','$CLevel1','$CLevel2','$CLevel3');\"><img src=\"../images/site_admin/file_edit.png\" alt=\"Edit '$CatName'\" hspace=\"2\" border=\"0\"></a>".$DeleteLink."</td>\n</tr>\n";
    $CatCount++;
  }
  &create_category_iconlist;

  $PageHeader = "Level 2 Category Management";
  $page = "category_view";
  $CatStep = "add_2";
  $RNavLink = "<a href=\"dbadmin.pl?f=cats&s=view&mct=".$CLevel1."&uid=".$uid."\"><img src=\"../images/site_admin/up.png\" align=\"absmiddle\" hspace=\"3\" border=\"0\">Back to Level 1 Category</a>";
  $CatLevel = "Level 2";
  $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $CatText1 = @arr[0];
  $CatPath = "Category Path: <b>$CatText1</b>";
  if ($CatCount == 0) { $TableListing = $TableListing."<tr class=\"ListStyle3\"><td colspan=\"4\" class=\"ListCellCenter\">No Categories found in $CatLevel</td></tr>\n"; }
}

if ($step eq "view") {
  $CatCount = 0;
  $CLevel2 = "100";
  $CLevel3 = "100";
  $MainCatName = "Category Root";
  $MainCatDescript = "---";
  $MainCatImage = "none.gif";
  $sql_statement = "SELECT Level1,CatName,CatDescript,CatId,CatImage FROM cat_base WHERE Level1 != '100' AND Level2 = '100' ORDER BY CatName;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($CLevel1,$CatName,$CatDescript,$CatId,$CatImage) = @arr;
    push(@mcats,"$CLevel1|$CatName|$CatDescript|$CatId|$CatImage");
  }
  foreach $Temp(@mcats) {
    ($CLevel1,$CatName,$CatDescript,$CatId,$CatImage) = split(/\|/,$Temp);
    $ProdCount = "0";
    $sql_statement = "SELECT COUNT(*) FROM cat_base WHERE Level1 != '100';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $SubCount = @arr[0];
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ProdCount = @arr[0];
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    if ($ALevel1 eq $CLevel1) { $BgClass = "ListStyle3"; $CatNameText = "<b>$CatName</b>"; } else { $CatNameText = $CatName; }
    if ($SubCount > 0) { $CatNameText = "<img src=\"../images/site_admin/folder_add.png\" align=\"absmiddle\" border=\"0\" hspace=\"2\">".$CatNameText; }
    else { $CatNameText = "<img src=\"../images/site_admin/folder.png\" align=\"absmiddle\" border=\"0\" hspace=\"2\">".$CatNameText; }
    $RowCount++;
    if ($ProdCount eq "0") {
      $DeleteLink = "<a href=\"javascript:DeleteCategory('".$CLevel1."','".$CLevel2."','".$CLevel3."','".$uid."');\" title=\"Delete '$CatName'\"><img src=\"../images/site_admin/stop.png\" alt=\"Delete '$CatName'\" border=\"0\" hspace=\"2\"></a>";
      $ViewProdLink = "<a class=\"DisableImage\"><img src=\"../images/site_admin/window_cascade.png\" border=\"0\" hspace=\"2\"></a>";
    }
    else {
      $DeleteLink = "<a class=\"DisableImage\"><img src=\"../images/site_admin/stop.png\" border=\"0\" hspace=\"2\"></a>";
      $ViewProdLink = "<a href=\"dbadmin.pl?f=prods&s=sort&fs=0&mk=link&sr=DisplayCat&sd=".$CLevel1."^".$CLevel2."^".$CLevel3."\"><img src=\"../images/site_admin/window_cascade.png\" alt=\"View Products in '$CatName'\" border=\"0\" hspace=\"2\"></a>";
    }
    $PreviewSiteLink = "<a href=\"index.pl?fn=cview&mct=$CLevel1&sct=$CLevel2\" target=\"_blank\" title=\"Preview Site\"><img src=\"../images/site_admin/www2.png\" alt=\"Preview Site\" border=\"0\" hspace=\"2\" hspace=\"2\"></a>";

    if (($CatImage eq "") || ($CatImage eq "default")) {
      $ImagePath = $CatImagePath.$CLevel1.$CLevel2.".jpg";
      if (-e $ImagePath) { $CatImage = $CLevel1.$CLevel2.".jpg"; } else { $CatImage = "none.gif"; }
    }

    $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $TableListing = $TableListing." <td class=\"ListCell\" valign=\"top\"><a href=\"dbadmin.pl?f=cats&s=view2&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\">".$CatNameText."</a></td>\n";
    $TableListing = $TableListing." <td class=\"ListCell\" valign=\"top\">".$CatDescript."&nbsp;</td>\n";
    $TableListing = $TableListing." <td class=\"ListCellCenter\" valign=\"top\">$ProdCount</td>\n";
    $TableListing = $TableListing." <td nowrap class=\"ListCellCenter\" valign=\"top\"><a href=\"javascript:AddToClipBoard('C','$CatId');\"><img src=\"../images/site_admin/paste.png\" alt=\"Clipboard '".$CatName."'\" border=\"0\" hspace=\"1\"></a>".$ViewProdLink."".$PreviewSiteLink."<a href=\"javascript:EditCategory('editform','$CatName','$CatDescript','$CatImage','$CLevel1','$CLevel2','$CLevel3','$CatId');\"><img src=\"../images/site_admin/file_edit.png\" alt=\"Edit '$CatName'\" hspace=\"2\" border=\"0\"></a>".$DeleteLink."</td>\n</tr>\n";
    $CatCount++;
  }

  &create_category_iconlist;

  $PageHeader = "Level 1 Category Management";
  $page = "category_view";
  $CatStep = "add_1";
  $CatLevel = "Level 1";
  $CatPath = "Category Path: <b>*Root*</b>";
  $RNavLink = "<a class=\"DisableImage\"><img src=\"../images/site_admin/up.png\" align=\"absmiddle\" hspace=\"3\" border=\"0\"></a>*Root*";
  if ($CatCount == 0) { $TableListing = $TableListing."<tr class=\"ListStyle3\"><td colspan=\"4\" class=\"ListCellCenter\">No Categories found in $CatLevel</td></tr>\n"; }

}
if ($step eq "show") {
  $sql_statement = "SELECT CatName,CatDescript FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($TopCatName,$TopCatDescript) = @arr;
  $TableListing = $TableListing."<tr><td bgcolor=\"#EEEEEE\" colspan=\"4\">&nbsp;<b>Sub Categories in ".$TopCatName."</b>:</td></tr>\n";
  $SubCatCount = "0";
  $sql_statement = "SELECT Level2,CatName,CatDescript FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 != '100' ORDER BY CatName;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($CLevel2,$CatName,$CatDescript) = @arr;
    $Temp = $CLevel2."|".$CatName."|".$CatDescript;
    push(@mcats,$Temp);
  }
  foreach $Temp(@mcats) {
    ($CLevel2,$CatName,$CatDescript) = split(/\|/,$Temp);
    $ProdCount = "0";
    $sql_statement = "SELECT COUNT(*) FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $SubCount = @arr[0];
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $ProdCount = @arr[0];
    if ($ALevel2 eq $CLevel2) { $CatNameText = "<b>$CatName</b>"; } else { $CatNameText = $CatName; }
    if ($SubCount > 1) { $CatNameText = "<img src=\"../images/site_admin/folder_add.png\" align=\"absmiddle\" border=\"0\" hspace=\"2\">".$CatNameText; }
    else { $CatNameText = "<img src=\"../images/site_admin/folder.png\" align=\"absmiddle\" border=\"0\" hspace=\"2\">".$CatNameText; }
    $RowCount++;
    if ($BgFlag eq "1") { $BgFlag = "0"; $BgColor = "#F2F2F2"; } else { $BgFlag = "1"; $BgColor = "#FFFFFF"; }
    if ($ProdCount eq "0") { $DeleteLink = "<a href=\"javascript:DeleteCategory('".$CLevel1."','".$CLevel2."','".$uid."');\"><img src=\"../images/site_admin/stop.png\" alt=\"Delete '$CatName'\" border=\"0\"></a>"; }
    else { $DeleteLink = "<img src=\"../images/site_admin/blank.gif\" border=\"0\">"; }
    $TableListing = $TableListing."<tr onmouseover=\"setPointer(this, $RowCount, 'over', '".$BgColor."', '#CCFFCC', '#FFCC99');\" onmouseout=\"setPointer(this, $RowCount, 'out', '".$BgColor."', '#CCFFCC', '#FFCC99');\" onmousedown=\"setPointer(this, $RowCount, 'click', '".$BgColor."', '#CCFFCC', '#FFCC99');\">\n";
    $TableListing = $TableListing." <td bgcolor=\"".$BgColor."\"><a href=\"dbadmin.pl?f=cats&s=show&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\">".$CatNameText."</a></td>\n <td bgcolor=\"".$BgColor."\">".$CatDescript."&nbsp;</td>\n";
    $TableListing = $TableListing." <td align=\"center\" bgcolor=\"".$BgColor."\">$ProdCount</td>\n <td nowrap bgcolor=\"".$BgColor."\"><a href=\"dbadmin.pl?f=cats&s=show&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\"><img src=\"../images/site_admin/www2.png\" alt=\"View '$CatName'\" border=\"0\"></a><a href=\"dbadmin.pl?f=cats&s=edit&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\"><img src=\"../images/site_admin/file_edit.png\" alt=\"Edit '$CatName'\" hspace=\"2\" border=\"0\"></a><a href=\"dbadmin.pl?f=cats&s=move&mct=".$CLevel1."&sct=".$CLevel2."&uid=".$uid."\"><img src=\"../images/site_admin/save_copy.png\" alt=\"Move items in '$CatName'\" hspace=\"2\" border=\"0\"></a>".$DeleteLink."</td>\n</tr>\n";
    $SubCatCount++;
  }
  if ($SubCount == 0) { $TableListing = $TableListing."<tr><td bgcolor=\"#FFFFFF\" colspan=\"4\">&nbsp;No Sub Categories found in ".$TopCatName."</td></tr>\n"; }

  $PageHeader = "Sub Level Category Management";
  $page = "category_show";
}
  &display_page_requested;
}

sub create_category_iconlist {
  $sql_statement = "SELECT NewPhile FROM media_images WHERE FolderName = 'cats' ORDER BY NewPhile;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($CatPhile) = @arr;
    $CatPhile =~ s/\.gif/\.jpg/gi;
    $CatPhile =~ s/\.png/\.jpg/gi;
    $CatPhile =~ s/\.jpeg/\.jpg/gi;
    $CatIconListNew = $CatIconListNew."<option value=\"$CatPhile\"> $CatPhile </option>\n";
    $CatIconListEdit = $CatIconListEdit."<option value=\"$CatPhile\"> $CatPhile </option>\n";
  }
}

sub parse_category_form {
  $NewCatName = $form{'NewCatName'};  
  $NewCatDesc = $form{'NewCatDesc'};  
  $NewCatIcon = $form{'NewCatIcon'};  
  $EditCatName = $form{'EditCatName'};  
  $EditCatDesc = $form{'EditCatDesc'};  
  $EditCatIcon = $form{'EditCatIcon'};
  $ListCatIcon = $form{'ListCatIcon'};
  $EditLevel1 = $form{'EditCat_1'};
  $EditLevel2 = $form{'EditCat_2'};
  $EditLevel3 = $form{'EditCat_3'};
  $EditCatId = $form{'EditCatId'};
  
  if ($ListCatIcon ne "default") { $EditCatImage = $ListCatIcon; } else { $EditCatImage = $EditCatIcon; }
  if ($NewCatIcon ne "default") { $NewCatImage = $NewCatIcon; } else { $NewCatImage = ""; }
  
  $DestinationCat = $form{'DestinationCat'};  
  
}
#--------------------------------------------------------------------------------------------------------------
sub display_products_page {
  $SortType = $info{'sr'};
  $SortData = $info{'sd'};
  $SortType = $form{'SetSort'};
  $SortData = $form{$SortType};
  $SortDir = $info{'sdr'};
  $OptionPrice_0 = "0.00";
  $OptionPrice_1 = "0.00";
  $OptionPrice_2 = "0.00";
  $OptionPrice_3 = "0.00";
  $OptionPrice_4 = "0.00";
  $OptionPrice_5 = "0.00";

  if ($step eq "clractive") {
    $sql_statement = "UPDATE prod_base SET ProdFlag = '0' WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "sort";
  }  
  if ($step eq "setactive") {
    $sql_statement = "UPDATE prod_base SET ProdFlag = '1' WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "sort";
  }  
  if ($step eq "clrspecial") {
    $sql_statement = "UPDATE prod_base SET SpecFlag = '0' WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "sort";
  }  
  if ($step eq "setspecial") {
    $sql_statement = "UPDATE prod_base SET SpecFlag = '1' WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "sort";
  }  
  if ($step eq "clrstock") {
    $sql_statement = "UPDATE prod_base SET StockLevel = '0' WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "sort";
  }  
  if ($step eq "setstock") {
    $sql_statement = "UPDATE prod_base SET StockLevel = '1' WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $step = "sort";
  }  

  if ($SortType eq "") { $SortType = $info{'sr'}; $SortData = $info{'sd'}; }
  if ($SortType eq "") {
    $query = new CGI;
    $LastProdSort = $query->cookie('tonLastProdSort');
    push(@debugstring,"RCOOKIE: tonLastProdSort||$LastProdSort");
    if ($LastProdSort ne "") { ($Ckfunc,$Ckstep,$SortType,$SortData,$OffSet) = split(/\,/,$LastProdSort); }
  }
  if ($SortType eq "") { $SortType = "DisplayAlpha"; $SortData = "ProdName"; }
  if ($step eq "view") {
    $SortType = "DisplayAlpha";
    $SortData = "ProdName";
    $CodeStatement = "SELECT COUNT(*) FROM prod_base;";
    $ListStatement = "SELECT ProdId,ProdName,OrderCode,Model,RetailPrice,SpecFlag,ProdFlag,StockLevel,Level1,Level2,Level3,DisplayPriority,MfId,ViewCount FROM prod_base ORDER BY $SortData LIMIT $OffSet,$DefProdOffset;";
    push(@writecookie,"tonLastProdSort|$func\,$step\,$SortType\,$SortData\,$OffSet");
  }

  if ($step eq "delete") {
    $sql_statement = "SELECT ProdName FROM prod_base WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $DProdName = @arr[0];
    $sql_statement = "SELECT COUNT(*) FROM order_items WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $TestCNT = @arr[0];
    if ($TestCNT == 0) {
      $sql_statement = "DELETE FROM prod_base WHERE ProdId = '$ProdId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $AlertPrompt = "Product '$DProdName' was deleted successfully!";
    }
    else {
      $sql_statement = "UPDATE prod_base SET ProdFlag = '0' WHERE ProdId = '$ProdId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $AlertPrompt = "Pending orders exist for this item!\\nProduct '$DProdName' could not be deleted but has been de-activated instead!";
    }
    $step = "sort";
    if ($SortType eq "Search") { $step = "search"; $SearchKey = $SortData; }
  }
  if ($SortType eq "Search") { $SearchKey = $SortData; }
  if (($SortType eq "Search") && ($step eq "sort")) { $step = "search"; }

  if ($step eq "duplicate") {
    $NewLevel = $form{'ProdCat'};
    ($Level1,$Level2,$Level3) = split(/\^/,$NewLevel);
    $sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($XProdId, $OrderCode, $MfId, $ALevel1, $ALevel2, $ALevel3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize, $ProdFlag, $SpecFlag, $RotateFlag, $DisplayPriority, $ProdType, $OptionText_0, $OptionText_1, $OptionText_2, $OptionText_3, $OptionText_4, $OptionText_5, $OptionPrice_0, $OptionPrice_1, $OptionPrice_2, $OptionPrice_3, $OptionPrice_4, $OptionPrice_5, $OptionSuffix_0, $OptionSuffix_1, $OptionSuffix_2, $OptionSuffix_3, $OptionSuffix_4, $OptionSuffix_5, $OptionWeight_0, $OptionWeight_1, $OptionWeight_2, $OptionWeight_3, $OptionWeight_4, $OptionWeight_5, $OptionStock_0, $OptionStock_1, $OptionStock_2, $OptionStock_3, $OptionStock_4, $OptionStock_5, $ViewCount, $KeyWords) = @arr;
    
    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE OrderCode = '$OrderCode' AND Level1 = '$Level1' AND Level3 = '$Level3' AND Level2 = '$Level2';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $TestCNT = @arr[0];
    
    if ($TestCNT == 0) {
      $sql_statement = "INSERT INTO prod_base VALUES ('','$OrderCode','$MfId','$Level1','$Level2','$Level3','$Model','$ProdName','$ProdSize','$RetailPrice','$MarkupPrice','$CostPrice','$DelCharge','$ProdImage','$ProdNotes','$ProdDate','$AddUser','$FeatureSumm','$ExtraCost','$PackUnit','$StockLevel','$ProdWeight','$MinOrder','$FeatureText','$FeatureList','$ExCostType','$SupplyName','$ExtraSize','$ProdFlag','$SpecFlag','$RotateFlag','$DisplayPriority','$ProdType','$OptionText_0','$OptionText_1','$OptionText_2','$OptionText_3','$OptionText_4','$OptionText_5','$OptionPrice_0','$OptionPrice_1','$OptionPrice_2','$OptionPrice_3','$OptionPrice_4','$OptionPrice_5','$OptionSuffix_0','$OptionSuffix_1','$OptionSuffix_2','$OptionSuffix_3','$OptionSuffix_4','$OptionSuffix_5','$OptionWeight_0','$OptionWeight_1','$OptionWeight_2','$OptionWeight_3','$OptionWeight_4','$OptionWeight_5','$OptionStock_0','$OptionStock_1','$OptionStock_2','$OptionStock_3','$OptionStock_4','$OptionStock_5','$ViewCount','$KeyWords');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    }    
    $step = "show";

  }



  if (($step eq "edit") || ($step eq "show") || ($step eq "copynew")) {
    $sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($ProdId, $OrderCode, $MfId, $Level1, $Level2, $Level3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize, $ProdFlag, $SpecFlag, $RotateFlag, $DisplayPriority, $ProdType, $OptionText_0, $OptionText_1, $OptionText_2, $OptionText_3, $OptionText_4, $OptionText_5, $OptionPrice_0, $OptionPrice_1, $OptionPrice_2, $OptionPrice_3, $OptionPrice_4, $OptionPrice_5, $OptionSuffix_0, $OptionSuffix_1, $OptionSuffix_2, $OptionSuffix_3, $OptionSuffix_4, $OptionSuffix_5, $OptionWeight_0, $OptionWeight_1, $OptionWeight_2, $OptionWeight_3, $OptionWeight_4, $OptionWeight_5, $OptionStock_0, $OptionStock_1, $OptionStock_2, $OptionStock_3, $OptionStock_4, $OptionStock_5, $ViewCount, $KeyWords) = @arr;
    $ProdCat = $Level1."^".$Level2."^".$Level3;
    $ProdCatTest = $Level1."^".$Level2."^".$Level3;
    $TestString = $ProdCatTest;
    $DuplicateCount = "0";
    $FeatureText =~ s/<br>/\n/gi;
    $FeatureText =~ s/   / /gi;
    $FeatureText =~ s/  / /gi;
    $FeatureText =~ s/  / /gi;

    &select_product_options;
    $sql_statement = "SELECT Level1,Level2,Level3,ProdId FROM prod_base WHERE OrderCode = '$OrderCode' AND ProdId != '$ProdId' ORDER BY Level1;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($TLevel1,$TLevel2,$TLevel3,$TProdId) = @arr;
      $Temp = $TLevel1."|".$TLevel2."|".$TLevel3."|".$TProdId;
      push(@duplicates,$Temp);
      $DuplicateCount++;
    }
    foreach $Temp(@duplicates) {
      ($TLevel1,$TLevel2,$TLevel3,$TProdId) = split(/\|/,$Temp);
      $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$TLevel1' AND Level2 = '100' AND Level3 = '100';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      $DupCatName = @arr[0];
      $DupCatLink = $DupCatLink."[<a href=\"dbadmin.pl?f=prods&s=show&pid=".$TProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$TLevel1."&sct=".$TLevel2."&pct=".$TLevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\">View</a>] <a href=\"dbadmin.pl?f=prods&s=sort&sr=DisplayCat&sd=".$TLevel1."^100^100&uid=".$uid."\">".$DupCatName."</a>";
      
      if ($TLevel2 > 100) {
        $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$TLevel1' AND Level2 = '$TLevel2' AND Level3 = '100';";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        @arr = $sth->fetchrow;
        $DupCatName = @arr[0];
        $DupCatLink = $DupCatLink." &raquo; <a href=\"dbadmin.pl?f=prods&s=sort&sr=DisplayCat&sd=".$TLevel1."^".$TLevel2."^100&uid=".$uid."\">".$DupCatName."</a>";        
      }
      if ($TLevel3 > 100) {
        $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$TLevel1' AND Level2 = '$TLevel2' AND Level3 = '$TLevel3';";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        @arr = $sth->fetchrow;
        $DupCatName = @arr[0];
        $DupCatLink = $DupCatLink." &raquo; <a href=\"dbadmin.pl?f=prods&s=sort&sr=DisplayCat&sd=".$TLevel1."^".$TLevel2."^".$TLevel3."&uid=".$uid."\">".$DupCatName."</a>";        
      }

      $DupCatLink = $DupCatLink."<br>";
    }
    
    if ($SpecFlag eq "1") { $SpecSet = " checked"; }
    if ($ProdFlag eq "1") { $ProdSet = " checked"; }
    $ImagePath = $FullImagePath.$OrderCode.".jpg";
    push(@debugstring,"PATH IMG||$ImagePath");
    if (-e $ImagePath) { $ProdImage = $OrderCode.".jpg"; } else { $ProdImage = "none.jpg"; }
    if ($step eq "show") {
      $page = "product_show";
      if ($SpecFlag eq "1") { $SpecConf = "tickbox.gif"; } else { $SpecConf = "tickblank.gif"; }
      if ($ProdFlag eq "1") { $ProdConf = "tickbox.gif"; } else { $ProdConf = "tickblank.gif"; }
      $FeatureText =~ s/\n/<br>/g;
    }
    elsif ($step eq "copynew") {
      $PageHeader = "Product Database : Copy Existing Product to New Product";
      $page = "product_add";
      $OrderCode = "";
      $Model = "";
    }
    else { $PageHeader = "Product Database : Edit Existing Product"; $page = "product_edit"; }
      
      &populate_category_list;
      &populate_product_options;
      &display_page_requested;
    }

  &populate_product_options;
  &populate_category_list;

  if ($step eq "editsave") {
    &parse_product_form;

    #if (index($ProdCat,"^100^100") > -1) {
    #  $AlertPrompt = "The Category Level you selected is invalid!\\nPlease select a Level 2 or Level 3 Category to place your product in.";
    #  $PageHeader = "Product Database : Add new Product";
    #  $page = "product_edit";
    #  &display_page_requested;
    #}
    ($CLevel1,$CLevel2,$CLevel3) = split(/\^/,$ProdCat);
    $DuplicateChange = $form{'DuplicateChange'};
    $DuplicateCount = "0";
    if ($DuplicateChange eq "Y") {
      $sql_statement = "SELECT OrderCode FROM prod_base WHERE ProdId = '$ProdId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      $SetOrderCode = @arr[0];
      $sql_statement = "SELECT ProdId FROM prod_base WHERE OrderCode = '$SetOrderCode' ORDER BY ProdId;";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      while (@arr = $sth->fetchrow) {
        $TProdId = @arr[0];
        push(@duplicates,$TProdId);
        $DuplicateCount++;
      }
      foreach $TProdId(@duplicates) {
        if ($TProdId eq $ProdId) { $sql_statement = "UPDATE prod_base SET KeyWords = '$KeyWords',DisplayPriority = '$DisplayPriority',OrderCode = '$OrderCode',MfId = '$MfId',Level1 = '$CLevel1',Level2 = '$CLevel2',Level3 = '$CLevel3',Model = '$Model',ProdName = '$ProdName',ProdSize = '$ProdSize',RetailPrice = '$RetailPrice',MarkupPrice = '$MarkupPrice',CostPrice = '$CostPrice',DelCharge = '$DelCharge',ProdImage = '$ProdImage',ProdNotes = 'Updated by $UserName on $DateNow',FeatureSumm = '$FeatureSumm',ExtraCost = '$ExtraCost',PackUnit = '$PackUnit',StockLevel = '$StockLevel',ProdWeight = '$ProdWeight',MinOrder = '$MinOrder',FeatureText = '$FeatureText',SupplyName = '$SupplyName',ProdFlag = '$ProdFlag',SpecFlag = '$SpecFlag',OptionText_0 = '$OptionText_0',OptionText_1 = '$OptionText_1',OptionText_2 = '$OptionText_2',OptionText_3 = '$OptionText_3',OptionText_4 = '$OptionText_4',OptionText_5 = '$OptionText_5',OptionPrice_0 = '$OptionPrice_0',OptionPrice_1 = '$OptionPrice_1',OptionPrice_2 = '$OptionPrice_2',OptionPrice_3 = '$OptionPrice_3',OptionPrice_4 = '$OptionPrice_4',OptionPrice_5 = '$OptionPrice_5',OptionSuffix_0 = '$OptionSuffix_0',OptionSuffix_1 = '$OptionSuffix_1',OptionSuffix_2 = '$OptionSuffix_2',OptionSuffix_3 = '$OptionSuffix_3',OptionSuffix_4 = '$OptionSuffix_4',OptionSuffix_5 = '$OptionSuffix_5',OptionWeight_0 = '$OptionWeight_0',OptionWeight_1 = '$OptionWeight_1',OptionWeight_2 = '$OptionWeight_2',OptionWeight_3 = '$OptionWeight_3',OptionWeight_4 = '$OptionWeight_4',OptionWeight_5 = '$OptionWeight_5',OptionStock_0 = '$OptionStock_0',OptionStock_1 = '$OptionStock_1',OptionStock_2 = '$OptionStock_2',OptionStock_3 = '$OptionStock_3',OptionStock_4 = '$OptionStock_4',OptionStock_5 = '$OptionStock_5' WHERE ProdId = '$TProdId';"; }
        else { $sql_statement = "UPDATE prod_base SET KeyWords = '$KeyWords',DisplayPriority = '$DisplayPriority',OrderCode = '$OrderCode',MfId = '$MfId',Model = '$Model',ProdName = '$ProdName',ProdSize = '$ProdSize',RetailPrice = '$RetailPrice',MarkupPrice = '$MarkupPrice',CostPrice = '$CostPrice',DelCharge = '$DelCharge',ProdImage = '$ProdImage',ProdNotes = 'Updated by $UserName on $DateNow',FeatureSumm = '$FeatureSumm',ExtraCost = '$ExtraCost',PackUnit = '$PackUnit',StockLevel = '$StockLevel',ProdWeight = '$ProdWeight',MinOrder = '$MinOrder',FeatureText = '$FeatureText',SupplyName = '$SupplyName',ProdFlag = '$ProdFlag',SpecFlag = '$SpecFlag',OptionText_0 = '$OptionText_0',OptionText_1 = '$OptionText_1',OptionText_2 = '$OptionText_2',OptionText_3 = '$OptionText_3',OptionText_4 = '$OptionText_4',OptionText_5 = '$OptionText_5',OptionPrice_0 = '$OptionPrice_0',OptionPrice_1 = '$OptionPrice_1',OptionPrice_2 = '$OptionPrice_2',OptionPrice_3 = '$OptionPrice_3',OptionPrice_4 = '$OptionPrice_4',OptionPrice_5 = '$OptionPrice_5',OptionSuffix_0 = '$OptionSuffix_0',OptionSuffix_1 = '$OptionSuffix_1',OptionSuffix_2 = '$OptionSuffix_2',OptionSuffix_3 = '$OptionSuffix_3',OptionSuffix_4 = '$OptionSuffix_4',OptionSuffix_5 = '$OptionSuffix_5',OptionWeight_0 = '$OptionWeight_0',OptionWeight_1 = '$OptionWeight_1',OptionWeight_2 = '$OptionWeight_2',OptionWeight_3 = '$OptionWeight_3',OptionWeight_4 = '$OptionWeight_4',OptionWeight_5 = '$OptionWeight_5',OptionStock_0 = '$OptionStock_0',OptionStock_1 = '$OptionStock_1',OptionStock_2 = '$OptionStock_2',OptionStock_3 = '$OptionStock_3',OptionStock_4 = '$OptionStock_4',OptionStock_5 = '$OptionStock_5' WHERE ProdId = '$TProdId';"; }        
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      }
      if ($DuplicateCount > 1) { $StatusMessage = "0|<b>".$DuplicateCount."</b> Duplicate items were updated successfully!"; }
    }
    else {
      $sql_statement = "UPDATE prod_base SET KeyWords = '$KeyWords',DisplayPriority = '$DisplayPriority',OrderCode = '$OrderCode',MfId = '$MfId',Level1 = '$CLevel1',Level2 = '$CLevel2',Level3 = '$CLevel3',Model = '$Model',ProdName = '$ProdName',ProdSize = '$ProdSize',RetailPrice = '$RetailPrice',MarkupPrice = '$MarkupPrice',CostPrice = '$CostPrice',DelCharge = '$DelCharge',ProdImage = '$ProdImage',ProdNotes = 'Updated by $UserName on $DateNow',FeatureSumm = '$FeatureSumm',ExtraCost = '$ExtraCost',PackUnit = '$PackUnit',StockLevel = '$StockLevel',ProdWeight = '$ProdWeight',MinOrder = '$MinOrder',FeatureText = '$FeatureText',SupplyName = '$SupplyName',ProdFlag = '$ProdFlag',SpecFlag = '$SpecFlag',OptionText_0 = '$OptionText_0',OptionText_1 = '$OptionText_1',OptionText_2 = '$OptionText_2',OptionText_3 = '$OptionText_3',OptionText_4 = '$OptionText_4',OptionText_5 = '$OptionText_5',OptionPrice_0 = '$OptionPrice_0',OptionPrice_1 = '$OptionPrice_1',OptionPrice_2 = '$OptionPrice_2',OptionPrice_3 = '$OptionPrice_3',OptionPrice_4 = '$OptionPrice_4',OptionPrice_5 = '$OptionPrice_5',OptionSuffix_0 = '$OptionSuffix_0',OptionSuffix_1 = '$OptionSuffix_1',OptionSuffix_2 = '$OptionSuffix_2',OptionSuffix_3 = '$OptionSuffix_3',OptionSuffix_4 = '$OptionSuffix_4',OptionSuffix_5 = '$OptionSuffix_5',OptionWeight_0 = '$OptionWeight_0',OptionWeight_1 = '$OptionWeight_1',OptionWeight_2 = '$OptionWeight_2',OptionWeight_3 = '$OptionWeight_3',OptionWeight_4 = '$OptionWeight_4',OptionWeight_5 = '$OptionWeight_5',OptionStock_0 = '$OptionStock_0',OptionStock_1 = '$OptionStock_1',OptionStock_2 = '$OptionStock_2',OptionStock_3 = '$OptionStock_3',OptionStock_4 = '$OptionStock_4',OptionStock_5 = '$OptionStock_5' WHERE ProdId = '$ProdId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $StatusMessage = "0|Product item '$ProdName' was updated successfully!";
    }
    $sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($ProdId, $OrderCode, $MfId, $Level1, $Level2, $Level3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize, $ProdFlag, $SpecFlag, $RotateFlag, $DisplayPriority, $ProdType, $OptionText_0, $OptionText_1, $OptionText_2, $OptionText_3, $OptionText_4, $OptionText_5, $OptionPrice_0, $OptionPrice_1, $OptionPrice_2, $OptionPrice_3, $OptionPrice_4, $OptionPrice_5, $OptionSuffix_0, $OptionSuffix_1, $OptionSuffix_2, $OptionSuffix_3, $OptionSuffix_4, $OptionSuffix_5, $OptionWeight_0, $OptionWeight_1, $OptionWeight_2, $OptionWeight_3, $OptionWeight_4, $OptionWeight_5, $OptionStock_0, $OptionStock_1, $OptionStock_2, $OptionStock_3, $OptionStock_4, $OptionStock_5, $ViewCount, $KeyWords) = @arr;
    &select_product_options;
    $ProdCat = $Level1."^".$Level2."^".$Level3;
    $ProdCatTest = $Level1."^".$Level2."^".$Level3;
    $SortData = $ProdCatTest;
    &populate_category_list;

    $DuplicateCount = "0";
    $sql_statement = "SELECT Level1,Level2,Level3,ProdId FROM prod_base WHERE OrderCode = '$OrderCode' AND ProdId != '$ProdId' ORDER BY Level1;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($TLevel1,$TLevel2,$TLevel3,$TProdId) = @arr;
      $Temp = $TLevel1."|".$TLevel2."|".$TLevel3."|".$TProdId;
      push(@showduplicates,$Temp);
      $DuplicateCount++;
    }
    foreach $Temp(@showduplicates) {
      ($TLevel1,$TLevel2,$TLevel3,$TProdId) = split(/\|/,$Temp);
      $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$TLevel1' AND Level2 = '100' AND Level3 = '100';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      $DupCatName = @arr[0];
      $DupCatLink = $DupCatLink."[<a href=\"dbadmin.pl?f=prods&s=show&pid=".$TProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$TLevel1."&sct=".$TLevel2."&pct=".$TLevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\">View</a>] <a href=\"dbadmin.pl?f=prods&s=sort&sr=DisplayCat&sd=".$TLevel1."^100^100&uid=".$uid."\">".$DupCatName."</a>";
      
      if ($TLevel2 > 100) {
        $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$TLevel1' AND Level2 = '$TLevel2' AND Level3 = '100';";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        @arr = $sth->fetchrow;
        $DupCatName = @arr[0];
        $DupCatLink = $DupCatLink." &raquo; <a href=\"dbadmin.pl?f=prods&s=sort&sr=DisplayCat&sd=".$TLevel1."^".$TLevel2."^100&uid=".$uid."\">".$DupCatName."</a>";        
      }
      if ($TLevel3 > 100) {
        $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$TLevel1' AND Level2 = '$TLevel2' AND Level3 = '$TLevel3';";
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        @arr = $sth->fetchrow;
        $DupCatName = @arr[0];
        $DupCatLink = $DupCatLink." &raquo; <a href=\"dbadmin.pl?f=prods&s=sort&sr=DisplayCat&sd=".$TLevel1."^".$TLevel2."^".$TLevel3."&uid=".$uid."\">".$DupCatName."</a>";        
      }

      $DupCatLink = $DupCatLink."<br>";
    }

    $ImagePath = $FullImagePath.$OrderCode.".jpg";
	if (-e $ImagePath) { $ProdImage = $OrderCode.".jpg"; } else { $ProdImage = "none.jpg"; }
	if ($SpecFlag eq "1") { $SpecConf = "tickbox.gif"; } else { $SpecConf = "tickblank.gif"; }
	if ($ProdFlag eq "1") { $ProdConf = "tickbox.gif"; } else { $ProdConf = "tickblank.gif"; }
    $FeatureText =~ s/\n/<br>/g;

    $PageHeader = "Product Database : Product Update Saved";
    $page = "product_editsave";
    &display_page_requested;
  }  
  if ($step eq "addsave") {
    &parse_product_form;

    $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE OrderCode = '$OrderCode';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $TestCNT = @arr[0];
    if ($TestCNT > 0) {
      $StatusMessage = "2|A product already exists with Order Code '$OrderCode' - Please use a unique Order Code";
      $PageHeader = "Product Database : Add new Product";
      &select_product_options;
      &populate_product_options;
      $page = "product_add";
      &display_page_requested;
    }
    #if (index($ProdCat,"^100^100") > -1) {
    #  $AlertPrompt = "The Category Level you selected is invalid!\\nPlease select a Level 2 or Level 3 Category to place your product in.";
    #  $PageHeader = "Product Database : Add new Product";
    #  $page = "product_add";
    #  &display_page_requested;
    #}
    ($CLevel1,$CLevel2,$CLevel3) = split(/\^/,$ProdCat);
    $sql_statement = "INSERT INTO prod_base VALUES ('','$OrderCode','$MfId','$CLevel1','$CLevel2','$CLevel3','$Model','$ProdName','$ProdSize','$RetailPrice','$MarkupPrice','$CostPrice','$DelCharge','$ProdImage','Added by $UserName','$DateNow','$UserName','$FeatureSumm','$ExtraCost','$PackUnit','$StockLevel','$ProdWeight','$MinOrder','$FeatureText','$FeatureList','$ExCostType','$SupplyName','$ExtraSize','$ProdFlag','$SpecFlag','0','$DisplayPriority','$ProdType','$OptionText_0','$OptionText_1','$OptionText_2','$OptionText_3','$OptionText_4','$OptionText_5','$OptionPrice_0','$OptionPrice_1','$OptionPrice_2','$OptionPrice_3','$OptionPrice_4','$OptionPrice_5','$OptionSuffix_0','$OptionSuffix_1','$OptionSuffix_2','$OptionSuffix_3','$OptionSuffix_4','$OptionSuffix_5','$OptionWeight_0','$OptionWeight_1','$OptionWeight_2','$OptionWeight_3','$OptionWeight_4','$OptionWeight_5','$OptionStock_0','$OptionStock_1','$OptionStock_2','$OptionStock_3','$OptionStock_4','$OptionStock_5','$ViewCount','$KeyWords');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    sleep(1);
    $sql_statement = "SELECT * FROM prod_base WHERE OrderCode = '$OrderCode' ORDER BY ProdId DESC LIMIT 0,1;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($ProdId, $OrderCode, $MfId, $CLevel1, $CLevel2, $CLevel3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize, $ProdFlag, $SpecFlag, $RotateFlag, $DisplayPriority, $ProdType, $OptionText_0, $OptionText_1, $OptionText_2, $OptionText_3, $OptionText_4, $OptionText_5, $OptionPrice_0, $OptionPrice_1, $OptionPrice_2, $OptionPrice_3, $OptionPrice_4, $OptionPrice_5, $OptionSuffix_0, $OptionSuffix_1, $OptionSuffix_2, $OptionSuffix_3, $OptionSuffix_4, $OptionSuffix_5, $OptionWeight_0, $OptionWeight_1, $OptionWeight_2, $OptionWeight_3, $OptionWeight_4, $OptionWeight_5, $OptionStock_0, $OptionStock_1, $OptionStock_2, $OptionStock_3, $OptionStock_4, $OptionStock_5, $ViewCount, $KeyWords) = @arr;

    $ImagePath = $FullImagePath.$OrderCode.".jpg";
  	if (-e $ImagePath) { $ProdImage = $OrderCode.".jpg"; } else { $ProdImage = "none.jpg"; }
  	if ($SpecFlag eq "1") { $SpecConf = "tickbox.gif"; } else { $SpecConf = "tickblank.gif"; }
  	if ($ProdFlag eq "1") { $ProdConf = "tickbox.gif"; } else { $ProdConf = "tickblank.gif"; }
    $FeatureText =~ s/\n/<br>/g;

    &select_product_options;
    $ProdCat = $CLevel1."^".$CLevel2."^".$CLevel3;
    $ProdCatTest = $CLevel1."^".$CLevel2."^".$CLevel3;
    $SortData = $ProdCatTest;
    &populate_category_list;
    &populate_product_options;
    
    $PageHeader = "Product Database : New Product Added $UserName";
    $page = "product_addsave";
    &display_page_requested;
  }
  if ($step eq "add") {
    $RetailPrice = "0.00";
    $DelCharge = "0.00";
    $CostPrice = "0.00";
    $PackUnit = "1";
    $StockLevel = "1";
    $ProdWeight = "1";
    $MinOrder = "1";
    &populate_product_options;

    $PageHeader = "Product Database : Add new Product";
    $page = "product_add";
    &display_page_requested;
  }
  if ($step eq "sort") {
    push(@writecookie,"tonLastProdSort|$func\,$step\,$SortType\,$SortData\,$OffSet");
    if ($SortType eq "DisplayCat") {
      ($CLevel1,$CLevel2,$CLevel3) = split(/\^/,$SortData);
      if ($CLevel2 eq "100") {
        $CodeStatement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' ORDER BY ProdName;";
        $ListStatement = "SELECT ProdId,ProdName,OrderCode,Model,RetailPrice,SpecFlag,ProdFlag,StockLevel,Level1,Level2,Level3,DisplayPriority,MfId,ViewCount,OptionText_0,ProdImage FROM prod_base WHERE Level1 = '$CLevel1' ORDER BY ProdName LIMIT $OffSet,$DefProdOffset;";
      }
      elsif ($CLevel3 eq "100") {
        $CodeStatement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' ORDER BY ProdName;";
        $ListStatement = "SELECT ProdId,ProdName,OrderCode,Model,RetailPrice,SpecFlag,ProdFlag,StockLevel,Level1,Level2,Level3,DisplayPriority,MfId,ViewCount,OptionText_0,ProdImage FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' ORDER BY ProdName LIMIT $OffSet,$DefProdOffset;";
      }
      else {
        $CodeStatement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' AND Level3 = '$CLevel3' ORDER BY ProdName;";
        $ListStatement = "SELECT ProdId,ProdName,OrderCode,Model,RetailPrice,SpecFlag,ProdFlag,StockLevel,Level1,Level2,Level3,DisplayPriority,MfId,ViewCount,OptionText_0,ProdImage FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' AND Level3 = '$CLevel3' ORDER BY ProdName LIMIT $OffSet,$DefProdOffset;";
      }
    }
    elsif ($SortType eq "DisplayAlpha") {
      ($SortData,$SortDir) = split(/\^/,$SortData);
      if (($SortDir eq "") && ($info{'sdr'} eq "")) { $SortDir = "ASC"; }
      elsif ($info{'sdr'} ne "") { $SortDir = $info{'sdr'}; }
      $CodeStatement = "SELECT COUNT(*) FROM prod_base;";
      $ListStatement = "SELECT ProdId,ProdName,OrderCode,Model,RetailPrice,SpecFlag,ProdFlag,StockLevel,Level1,Level2,Level3,DisplayPriority,MfId,ViewCount,OptionText_0,ProdImage FROM prod_base ORDER BY $SortData $SortDir LIMIT $OffSet,$DefProdOffset;";
    }
    elsif ($SortType eq "DisplayStatus") {
      ($VarName,$VarValue) = split(/\^/,$SortData);
      $CodeStatement = "SELECT COUNT(*) FROM prod_base WHERE $VarName = '$VarValue';";
      $ListStatement = "SELECT ProdId,ProdName,OrderCode,Model,RetailPrice,SpecFlag,ProdFlag,StockLevel,Level1,Level2,Level3,DisplayPriority,MfId,ViewCount,OptionText_0,ProdImage FROM prod_base WHERE $VarName = '$VarValue' ORDER BY ProdName LIMIT $OffSet,$DefProdOffset;";
    }
  }
  if ($step eq "search") {
    push(@writecookie,"tonLastProdSort|$func\,$step\,$SortType\,$SortData\,$OffSet");
    if ($SortData eq "") { $SearchKey = $form{'SearchKey'}; $SortData = $SearchKey; }
    $SortType = "Search";
    $CodeStatement = "SELECT COUNT(*) FROM prod_base WHERE  ProdName LIKE '%".$SearchKey."%' OR OrderCode LIKE '%".$SearchKey."%' OR Model LIKE '%".$SearchKey."%' OR FeatureSumm LIKE '%".$SearchKey."%';";
    $ListStatement = "SELECT ProdId,ProdName,OrderCode,Model,RetailPrice,SpecFlag,ProdFlag,StockLevel,Level1,Level2,Level3,DisplayPriority,MfId,ViewCount,OptionText_0,ProdImage FROM prod_base WHERE ProdName LIKE '%".$SearchKey."%' OR OrderCode LIKE '%".$SearchKey."%' OR Model LIKE '%".$SearchKey."%' OR FeatureSumm LIKE '%".$SearchKey."%' ORDER BY ProdName LIMIT $OffSet,20;";
  }
  $sql_statement = $CodeStatement;
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $ResultCount = @arr[0];
  $TestString = $CodeStatement."^".$ResultCount;


  $sql_statement = $ListStatement;
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($ProdId,$ProdName,$OrderCode,$Model,$RetailPrice,$SpecFlag,$ProdFlag,$StockLevel,$ALevel1,$ALevel2,$ALevel3,$DisplayPriority,$MfId,$ViewCount,$OptionText_0,$ProdImage) = @arr;
    $RowCount++;
    $ProdCount = $RowCount + $OffSet;
    #if ($step eq "search") { $TableListing =~ s/$SearchKey/\<span class=\"highlightsearch\"\>$SearchKey\<\/span\>/gi; }
  	if (length($ProdName) > 32) {
      &shorten_text_string("$ProdName|32");
      $ProdName = $ShortString."...";
    }

    if ($ProdImage eq "") { $ProdImage = $OrderCode.".jpg"; }
    $ImagePath = $ThumbNailPath.$ProdImage;
    if (-e $ImagePath) { $PathOK = "1"; $ImageLink = "<a href=\"javascript:UploadProductLink('$ProdId','$OrderCode','$uid');\" onMouseOver=\"ddrivetip('<div align=center><img src=../user/products/$ProdImage vspace=2 border=1><br><b>$ProdName</b></div>','#F2F2F2',400)\"; onMouseOut=\"hideddrivetip()\" class=\"ImageBorder\"><img src=\"../images/site_admin/nb_image.gif\" border=\"0\"></a>"; } else { $PathOK = "0"; $ImageLink = "<a href=\"javascript:UploadProductLink('$ProdId','$OrderCode','$uid');\" title=\"Upload Product Images\"><img src=\"../images/site_admin/nb_broken.gif\" border=\"0\" alt=\"Upload Image\"></a>"; }
    push(@debugstring,"PATH||$ImagePath - $OrderCode - $PathOK");

    if ($ProdFlag eq "0") { $ActiveLink = "<a href=\"dbadmin.pl?f=prods&s=setactive&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel1."&pct=".$ALevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\"><img src=\"../images/site_admin/mark_wh.gif\" border=\"0\" alt=\"Make Active\"></a>"; }
    else { $ActiveLink = "<a href=\"dbadmin.pl?f=prods&s=clractive&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel1."&pct=".$ALevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\"><img src=\"../images/site_admin/mark_gr.gif\" border=\"0\" alt=\"Make Active\"></a>"; }
    
    if ($SpecFlag eq "0") { $SpecialLink = "<a href=\"dbadmin.pl?f=prods&s=setspecial&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel1."&pct=".$ALevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\"><img src=\"../images/site_admin/mark_wh.gif\" border=\"0\" alt=\"Make Active\"></a>"; }
    else { $SpecialLink = "<a href=\"dbadmin.pl?f=prods&s=clrspecial&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel1."&pct=".$ALevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\"><img src=\"../images/site_admin/mark_or.gif\" border=\"0\" alt=\"Make Active\"></a>"; }
    
    if ($StockLevel eq "0") { $StockLink = "<a href=\"dbadmin.pl?f=prods&s=setstock&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel1."&pct=".$ALevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\"><img src=\"../images/site_admin/mark_wh.gif\" border=\"0\" alt=\"Make Active\"></a>"; }
    else { $StockLink = "<a href=\"dbadmin.pl?f=prods&s=clrstock&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel1."&pct=".$ALevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\"><img src=\"../images/site_admin/mark_gr.gif\" border=\"0\" alt=\"Make Active\"></a>"; }
    

    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }

    $TableListing = $TableListing."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $TableListing = $TableListing."<td class=\"ListCell\">".$ProdCount."</td>\n";
    $TableListing = $TableListing."<td class=\"ListCell\">".$OrderCode."</td>\n";
    #$TableListing = $TableListing."<td class=\"ListCellCenter\">&nbsp;".$MfId."</td>\n";
    $TableListing = $TableListing."<td class=\"ListCellCenter\">".$DisplayPriority."</td>\n";
    $TableListing = $TableListing."<td class=\"ListCell\">".$Model."</td>\n";
    $TableListing = $TableListing."<td class=\"ListCell\"><a href=\"dbadmin.pl?f=prods&s=show&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel1."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\">".$ProdName."</a></td>\n";
    $TableListing = $TableListing."<td class=\"ListCellRight\" align=\"right\">".$RetailPrice."&nbsp;</td>\n";
    $TableListing = $TableListing."<td class=\"ListCellCenter\">$ActiveLink</td>\n";
    $TableListing = $TableListing."<td class=\"ListCellCenter\">$SpecialLink</td>\n";
    $TableListing = $TableListing."<td class=\"ListCellCenter\">$StockLink</td>\n";
    $TableListing = $TableListing."<td class=\"ListCellCenter\">$ImageLink</td>\n";
    $TableListing = $TableListing."<td class=\"ListCell\"><a href=\"javascript:AddToClipBoard('P','$ProdId');\"><img src=\"../images/site_admin/paste.png\" alt=\"Clipboard '".$ProdName."'\" border=\"0\" hspace=\"1\"></a><a href=\"index.pl?fn=spbrand&mct=$ALevel1&sct=$ALevel2&pct=$ALevel3&st=view&pid=$ProdId\" target=\"_blank\" title=\"Preview '".$ProdName."'\"><img src=\"../images/site_admin/www2.png\" alt=\"Preview '".$ProdName."'\" border=\"0\" hspace=\"1\"></a>";
    $TableListing = $TableListing."<a href=\"dbadmin.pl?f=prods&s=edit&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel2."&pct=".$ALevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\"><img src=\"../images/site_admin/file_edit.png\" alt=\"Edit '".$ProdName."'\" hspace=\"1\" border=\"0\"></a>";
    $TableListing = $TableListing."<a href=\"dbadmin.pl?f=prods&s=copynew&pid=".$ProdId."&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$ALevel1."&sct=".$ALevel2."&pct=".$ALevel3."&fs=".$OffSet."&br=".$BrandId."&uid=".$uid."\"><img src=\"../images/site_admin/save_copy.png\" alt=\"Copy '".$ProdName."' to New Item\" hspace=\"1\" border=\"0\"></a>";
    $TableListing = $TableListing."<a href=\"javascript:DeleteProduct('".$ProdId."','".$SortType."','".$SortData."','".$uid."','".$OffSet."');\"><img src=\"../images/site_admin/stop.png\" alt=\"Delete '".$ProdName."'\" border=\"0\" hspace=\"1\"></a></td>\n";
    $TableListing = $TableListing."<td class=\"ListCellRight\">".$ViewCount."&nbsp;</td></tr>\n";
  }
  
  $StartRecord = $OffSet + 1;
  $ResultText = "Displaying Items <b>$StartRecord</b> to <b>$ProdCount</b> of <b>$ResultCount</b> Items...";
  $CurrOffSet = $OffSet;
  $PrevLink = $OffSet - $DefProdOffset;
  $OffSet = $OffSet + $DefProdOffset;
  #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

  if ($OffSet > $DefProdOffset) { $RNavLink = $RNavLink."&laquo; <a href=\"dbadmin.pl?f=prods&s=sort&fs=".$PrevLink."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$CLevel1."&sct=".$CLevel2."&br=&uid=".$uid."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
  $RNavLink = $RNavLink."| ";
  for ($a=0; $a <= 30; $a++) {
    $TestOffSet = $a * $DefProdOffset;
    $LinkLoop = $a + 1;
    if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
    elsif ($TestOffSet < $ResultCount) { $RNavLink = $RNavLink."<a href=\"dbadmin.pl?f=prods&s=sort&fs=".$TestOffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$CLevel1."&sct=".$CLevel2."&br=&uid=".$uid."\">$LinkLoop</a> \n"; }
  }
  $RNavLink = $RNavLink."| ";
  if ($OffSet < $ResultCount) { $RNavLink = $RNavLink." <a href=\"dbadmin.pl?f=prods&s=sort&fs=".$OffSet."&mk=link&sr=".$SortType."&sd=".$SortData."&sdr=".$SortDir."&mct=".$CLevel1."&sct=".$CLevel2."&br=&uid=".$uid."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
  $PageHeader = "Product Database";
  $page = "product_view";
  &display_page_requested;
}

sub populate_product_options {

$sql_statement = "SELECT * FROM system_variables;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
while (@arr = $sth->fetchrow) {
  ($SysId,$VarGroup,$VarName,$VarMax,$VarMin,$VarText) = @arr;
  if ($VarGroup eq "01") {
    if ($SortData eq $VarName) { $ProdAlphaList = $ProdAlphaList."<option value=\"".$VarName."\" selected>".$VarMax."</option>\n"; }
    else { $ProdAlphaList = $ProdAlphaList."<option value=\"".$VarName."\">".$VarMax."</option>\n"; }
  }
  if ($VarGroup eq "02") {
    if ($SortData eq $VarName) { $ProdStatusList = $ProdStatusList."<option value=\"".$VarName."\" selected>".$VarMax."</option>\n"; }
    else { $ProdStatusList = $ProdStatusList."<option value=\"".$VarName."\">".$VarMax."</option>\n"; }
  }
  if ($VarGroup eq "90") {
    $DefaultProdKeys = $VarText;
  }
  
}
for ($a=1; $a <= 99; $a++) {
  if ($DisplayPriority eq $a) { $DisplayPriorityList = $DisplayPriorityList."<option value=\"".$a."\" selected> Level ".$a."</option>\n"; }
  else { $DisplayPriorityList = $DisplayPriorityList."<option value=\"".$a."\"> Level ".$a."</option>\n"; }
}
}

sub select_product_options {
  $OrderOptions = "";
  if ($OptionStock_0 == 0) { $StockImage_0 = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\">"; }
  else { $StockImage_0 = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\">"; }
  if ($OptionStock_1 == 0) { $StockImage_1 = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\">"; }
  else { $StockImage_1 = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\">"; }
  if ($OptionStock_2 == 0) { $StockImage_2 = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\">"; }
  else { $StockImage_2 = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\">"; }
  if ($OptionStock_3 == 0) { $StockImage_3 = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\">"; }
  else { $StockImage_3 = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\">"; }
  if ($OptionStock_4 == 0) { $StockImage_4 = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\">"; }
  else { $StockImage_4 = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\">"; }
  if ($OptionStock_5 == 0) { $StockImage_5 = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\">"; }
  else { $StockImage_5 = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\">"; }
  
  $OrderOptions = $OrderOptions."<tr>\n<td class=\"ListCell\">".$OrderCode."-".$OptionSuffix_0."</td>\n<td class=\"ListCell\">$ProdName $OptionText_0</td><td class=\"ListCellCenter\">$OptionWeight_0</td><td class=\"ListCellCenter\">$StockImage_0</td>\n<td class=\"ListCellRight\" nowrap>$OptionPrice_0</td>\n</tr>\n";
  if ($OptionText_1 ne "") { $OrderOptions = $OrderOptions."<tr>\n<td class=\"ListCell\">".$OrderCode."-".$OptionSuffix_1."</td>\n<td class=\"ListCell\">$ProdName $OptionText_1</td><td class=\"ListCellCenter\">$OptionWeight_1</td><td class=\"ListCellCenter\">$StockImage_1</td>\n<td class=\"ListCellRight\" nowrap>$OptionPrice_1</td>\n</tr>\n"; }
	if ($OptionText_2 ne "") { $OrderOptions = $OrderOptions."<tr>\n<td class=\"ListCell\">".$OrderCode."-".$OptionSuffix_2."</td>\n<td class=\"ListCell\">$ProdName $OptionText_2</td><td class=\"ListCellCenter\">$OptionWeight_2</td><td class=\"ListCellCenter\">$StockImage_2</td>\n<td class=\"ListCellRight\" nowrap>$OptionPrice_2</td>\n</tr>\n"; }
  if ($OptionText_3 ne "") { $OrderOptions = $OrderOptions."<tr>\n<td class=\"ListCell\">".$OrderCode."-".$OptionSuffix_3."</td>\n<td class=\"ListCell\">$ProdName $OptionText_3</td><td class=\"ListCellCenter\">$OptionWeight_3</td><td class=\"ListCellCenter\">$StockImage_3</td>\n<td class=\"ListCellRight\" nowrap>$OptionPrice_3</td>\n</tr>\n"; }
  if ($OptionText_4 ne "") { $OrderOptions = $OrderOptions."<tr>\n<td class=\"ListCell\">".$OrderCode."-".$OptionSuffix_4."</td>\n<td class=\"ListCell\">$ProdName $OptionText_4</td><td class=\"ListCellCenter\">$OptionWeight_4</td><td class=\"ListCellCenter\">$StockImage_4</td>\n<td class=\"ListCellRight\" nowrap>$OptionPrice_4</td>\n</tr>\n"; }
  if ($OptionText_5 ne "") { $OrderOptions = $OrderOptions."<tr>\n<td class=\"ListCell\">".$OrderCode."-".$OptionSuffix_5."</td>\n<td class=\"ListCell\">$ProdName $OptionText_5</td><td class=\"ListCellCenter\">$OptionWeight_5</td><td class=\"ListCellCenter\">$StockImage_5</td>\n<td class=\"ListCellRight\" nowrap>$OptionPrice_5</td>\n</tr>\n"; }
}

sub populate_category_list {

if ($ProdCat eq "") { $ProdCat = $form{'ProdCat'}; }
if (($ProdCat ne "") && ($SortType eq "DisplayCat")) { $SortData = $ProdCat; }
$sql_statement = "SELECT CatName,Level1 FROM cat_base WHERE Level1 != '100' AND Level2 = '100' ORDER BY CatName;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
while (@arr = $sth->fetchrow) {
  ($CatName,$XLevel1) = @arr;
  $Temp = $CatName."|".$XLevel1;
  push(@lcats,$Temp);
}
foreach $Temp(@lcats) {
  ($TopCatName,$XLevel1) = split(/\|/,$Temp);
  $TestLevel = $XLevel1."^100^100";
  $TestString = $TestString."|".$TestLevel;
  $ProdCategoryList = $ProdCategoryList."<option value=\"\"></option>\n";
  if ($BypassTop eq "1") { 
    if ($SortData eq $TestLevel) { $ProdCategoryList = $ProdCategoryList."<option value=\"\" selected>".$TopCatName."</option>\n"; }
    elsif (($XLevel1 eq $Level1) || ($XLevel1 eq $CLevel1)) { $ProdCategoryList = $ProdCategoryList."<option value=\"\" selected>".$TopCatName."</option>\n"; }
    else { $ProdCategoryList = $ProdCategoryList."<option value=\"\">".$TopCatName."</option>\n"; }
  }
  else {
    if ($SortData eq $TestLevel) { $ProdCategoryList = $ProdCategoryList."<option value=\"".$XLevel1."^100^100\" selected>".$TopCatName."</option>\n"; }
    elsif (($XLevel1 eq $Level1) || ($XLevel1 eq $CLevel1)) { $ProdCategoryList = $ProdCategoryList."<option value=\"".$XLevel1."^100^100\" selected>".$TopCatName."</option>\n"; }
    else { $ProdCategoryList = $ProdCategoryList."<option value=\"".$XLevel1."^100^100\">".$TopCatName."</option>\n"; }    
  }
  @scats = ();
  $Temp2 = "";
  $sql_statement = "SELECT CatName,Level2 FROM cat_base WHERE Level1 = '$XLevel1' AND Level2 != '100' AND Level3 = '100' ORDER BY CatName;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($CatName,$XLevel2) = @arr;
    $Temp2 = $CatName."|".$XLevel2;  
    push(@scats,$Temp2);
  }
  foreach $Temp2(@scats) {
    ($MidCatName,$XLevel2) = split(/\|/,$Temp2);
    $TestLevel = $XLevel1."^".$XLevel2."^100";
    if ($ProdCatTest eq $TestLevel) { $ProdLinkList = "<a href=\"dbadmin.pl?f=prods&s=sort&sr=DisplayCat&sd=".$SortData."&sdr=".$SortDir."&uid=".$uid."\">$TopCatName &raquo; $MidCatName</a>"; }

    if ($BypassTop eq "1") { 
      if ($SortData eq $TestLevel) { $ProdCategoryList = $ProdCategoryList."<option value=\"\" selected>- ".$MidCatName."</option>\n"; }
      else { $ProdCategoryList = $ProdCategoryList."<option value=\"\">- ".$MidCatName."</option>\n"; }
    }
    else {
      if ($SortData eq $TestLevel) { $ProdCategoryList = $ProdCategoryList."<option value=\"".$XLevel1."^".$XLevel2."^100\" selected>- ".$MidCatName."</option>\n"; }
      else { $ProdCategoryList = $ProdCategoryList."<option value=\"".$XLevel1."^".$XLevel2."^100\">- ".$MidCatName."</option>\n"; }    
    }
    $sql_statement = "SELECT CatName,Level3 FROM cat_base WHERE Level1 = '$XLevel1' AND Level2 = '$XLevel2' AND Level3 != '100';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      ($CatName,$XLevel3) = @arr;
      $TestLevel = $XLevel1."^".$XLevel2."^".$XLevel3;
      if ($SortData eq $TestLevel) {
        $ProdCategoryList = $ProdCategoryList."<option value=\"".$TestLevel."\" selected>-- ".$CatName."</option>\n";
        $ProdLinkList = "<a href=\"dbadmin.pl?f=prods&s=sort&sr=DisplayCat&sd=".$SortData."&sdr=".$SortDir."&uid=".$uid."\">$TopCatName &raquo; $MidCatName &raquo; $CatName</a>";  
      }
      else { $ProdCategoryList = $ProdCategoryList."<option value=\"".$TestLevel."\">-- ".$CatName."</option>\n"; }
    }
  }
}  

if ($MfId eq "") { $MfId = $form{'MfId'}; }
$sql_statement = "SELECT MfId,MfCode,MfName FROM brand_base ORDER BY MfName;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
while (@arr = $sth->fetchrow) {
  ($YMfId,$YMfCode,$YBrandName) = @arr;
  if ($MfId eq $YMfCode) { $BrandList = $BrandList."<option value=\"$YMfId\" selected>- $YBrandName</option>\n"; }
  else { $BrandList = $BrandList."<option value=\"$YMfId\">- $YBrandName</option>\n"; }
}
$BrandList = $BrandList."<option value=\"1\">- Other (Not Listed)</option>\n";





}

sub parse_product_form {
  $DisplayPriority = $form{'DisplayPriority'};
  $OrderCode = $form{'OrderCode'};
  $MfId = $form{'MfId'};
  $ProdCat = $form{'ProdCat'};
  $Model = $form{'Model'};
  $ProdName = $form{'ProdName'};
  $ProdSize = $form{'ProdSize'};
  $RetailPrice = $form{'RetailPrice'};
  $MarkupPrice = $form{'MarkupPrice'};
  $CostPrice = $form{'CostPrice'};
  $DelCharge = $form{'DelCharge'};
  $ProdImage = $form{'ProdImage'};
  $FeatureSumm = $form{'FeatureSumm'};
  $ExtraCost = $form{'ExtraCost'};
  $PackUnit = $form{'PackUnit'};
  $StockLevel = $form{'StockLevel'};
  $ProdWeight = $form{'ProdWeight'};
  $MinOrder = $form{'MinOrder'};
  $FeatureText = $form{'FeatureText'};
  $FeatureList = $form{'FeatureList'};
  $ExCostType = $form{'ExCostType'};
  $SupplyName = $form{'SupplyName'};
  $ProdFlag = $form{'ProdFlag'};
  $SpecFlag = $form{'SpecFlag'};
  $Model =~ tr/a-z/A-Z/;

  $OptionSuffix_0 = $form{'OptionSuffix_0'};
  $OptionSuffix_1 = $form{'OptionSuffix_1'};
  $OptionSuffix_2 = $form{'OptionSuffix_2'};
  $OptionSuffix_3 = $form{'OptionSuffix_3'};
  $OptionSuffix_4 = $form{'OptionSuffix_4'};
  $OptionSuffix_5 = $form{'OptionSuffix_5'};

  $OptionText_0 = $form{'OptionText_0'};
  $OptionText_1 = $form{'OptionText_1'};
  $OptionText_2 = $form{'OptionText_2'};
  $OptionText_3 = $form{'OptionText_3'};
  $OptionText_4 = $form{'OptionText_4'};
  $OptionText_5 = $form{'OptionText_5'};

  $OptionPrice_0 = $form{'OptionPrice_0'};
  $OptionPrice_1 = $form{'OptionPrice_1'};
  $OptionPrice_2 = $form{'OptionPrice_2'};
  $OptionPrice_3 = $form{'OptionPrice_3'};
  $OptionPrice_4 = $form{'OptionPrice_4'};
  $OptionPrice_5 = $form{'OptionPrice_5'};

  $OptionWeight_0 = $form{'OptionWeight_0'};
  $OptionWeight_1 = $form{'OptionWeight_1'};
  $OptionWeight_2 = $form{'OptionWeight_2'};
  $OptionWeight_3 = $form{'OptionWeight_3'};
  $OptionWeight_4 = $form{'OptionWeight_4'};
  $OptionWeight_5 = $form{'OptionWeight_5'};

  $OptionStock_0 = $form{'OptionStock_0'};
  $OptionStock_1 = $form{'OptionStock_1'};
  $OptionStock_2 = $form{'OptionStock_2'};
  $OptionStock_3 = $form{'OptionStock_3'};
  $OptionStock_4 = $form{'OptionStock_4'};
  $OptionStock_5 = $form{'OptionStock_5'};
  

  $KeyWords = $form{'KeyWords'};

  $FeatureText =~ s/\cM//g;
  $FeatureText =~ s/\n/<br>/g;
  $RetailPrice =~ tr/0-9\./ /cs;
  $RetailPrice =~ s/ //gi;
  $CostPrice =~ tr/0-9\./ /cs;
  $CostPrice =~ s/ //gi;
  $DelCharge =~ tr/0-9\./ /cs;
  $DelCharge =~ s/ //gi;
  $OptionPrice_0 =~ tr/0-9\./ /cs;
  $OptionPrice_0 =~ s/ //gi;
  $OptionPrice_1 =~ tr/0-9\./ /cs;
  $OptionPrice_1 =~ s/ //gi;
  $OptionPrice_2 =~ tr/0-9\./ /cs;
  $OptionPrice_2 =~ s/ //gi;
  $OptionPrice_3 =~ tr/0-9\./ /cs;
  $OptionPrice_3 =~ s/ //gi;
  $OptionPrice_4 =~ tr/0-9\./ /cs;
  $OptionPrice_4 =~ s/ //gi;
  $OptionPrice_5 =~ tr/0-9\./ /cs;
  $OptionPrice_5 =~ s/ //gi;

  $OptionWeight_0 =~ tr/0-9\./ /cs;
  $OptionWeight_0 =~ s/ //gi;
  $OptionWeight_1 =~ tr/0-9\./ /cs;
  $OptionWeight_1 =~ s/ //gi;
  $OptionWeight_2 =~ tr/0-9\./ /cs;
  $OptionWeight_2 =~ s/ //gi;
  $OptionWeight_3 =~ tr/0-9\./ /cs;
  $OptionWeight_3 =~ s/ //gi;
  $OptionWeight_4 =~ tr/0-9\./ /cs;
  $OptionWeight_4 =~ s/ //gi;
  $OptionWeight_5 =~ tr/0-9\./ /cs;
  $OptionWeight_5 =~ s/ //gi;

  $OptionStock_0 =~ tr/0-9\./ /cs;
  $OptionStock_0 =~ s/ //gi;
  $OptionStock_1 =~ tr/0-9\./ /cs;
  $OptionStock_1 =~ s/ //gi;
  $OptionStock_2 =~ tr/0-9\./ /cs;
  $OptionStock_2 =~ s/ //gi;
  $OptionStock_3 =~ tr/0-9\./ /cs;
  $OptionStock_3 =~ s/ //gi;
  $OptionStock_4 =~ tr/0-9\./ /cs;
  $OptionStock_4 =~ s/ //gi;
  $OptionStock_5 =~ tr/0-9\./ /cs;
  $OptionStock_5 =~ s/ //gi;
  
  $OptionWeight_0 = sprintf("%.2f",$OptionWeight_0);
  $OptionWeight_1 = sprintf("%.2f",$OptionWeight_0);
  $OptionWeight_2 = sprintf("%.2f",$OptionWeight_0);
  $OptionWeight_3 = sprintf("%.2f",$OptionWeight_0);
  $OptionWeight_4 = sprintf("%.2f",$OptionWeight_0);
  $OptionWeight_5 = sprintf("%.2f",$OptionWeight_0);

  $OptionPrice_0 = sprintf("%.2f",$OptionPrice_0);
  $OptionPrice_1 = sprintf("%.2f",$OptionPrice_1);
  $OptionPrice_2 = sprintf("%.2f",$OptionPrice_2);
  $OptionPrice_3 = sprintf("%.2f",$OptionPrice_3);
  $OptionPrice_4 = sprintf("%.2f",$OptionPrice_4);
  $OptionPrice_5 = sprintf("%.2f",$OptionPrice_5);

  $OrderCode =~ tr/a-zA-Z0-9\-\#\/\\/ /cs;
  $OrderCode =~ tr/a-z/A-Z/;
  $OrderCode =~ s/ //gi;
  $KeyWords =~ s/\, /\,/gi;
  $KeyWords =~ s/^\s+//;
  $KeyWords =~ s/\s+$//;
}

#--------------------------------------------------------------------------------------------------------------
sub display_system_info {
  if ($step eq "purge") {
    $PurgeDate = $TimeStamp - 604800;
    $sql_statement = "DELETE FROM admin_accesslog WHERE LogDate < '$PurgeDate';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "DELETE FROM bench_mark WHERE BenchDate < '$PurgeDate';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "DELETE FROM shopping_basket WHERE SessionDate < '$PurgeDate' OR StatFlag = '0';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "DELETE FROM user_session WHERE ExpireTime < '$PurgeDate';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;

    $sql_statement = "optimize table admin_accesslog;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "optimize table bench_mark;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "optimize table shopping_basket;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "optimize table user_session;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;

  }
  if ($step eq "optimize") {
    $sql_statement = "show table status from $database;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      $TableName = @arr[0];
      push(@optim,$TableName);
    }
    foreach $TableName(@optim) {
      $TableCount++;
      $sql_statement = "optimize table $TableName;";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $TableResult = $sth->as_string;
      if ((index($TableResult,"status") > -1) && (index($TableResult,"OK") > -1) || (index($TableResult,"already up to date") > -1)) {
        $OkCount++;
        $TableState = "dbase_ok.gif";
      }
      else {
        $ErrorCount++;
        $TableState = "dbase_error.gif";
      }
      $DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\">$TableName</td><td class=\"ListCellRight\"><img src=\"../images/site_admin/".$TableState."\"></td></tr>\n";    
      $StatReport = $StatReport.$TableResult;
    }
    if ($ErrorCount > 0) { $StatusMessage = "2|$TableCount tables where checked - $ErrorCount errors found<br>Please run the table repair option"; }
    else { $StatusMessage = "0|$TableCount tables where checked - 0 errors found"; }
    #$StatusMessage = "0|$TableCount tables where optimized - no errors";
  }
  if ($step eq "check") {
    $DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\"><b>Table Name</b></td><td class=\"ListCellRight\"><b>Status<b></td></tr>\n";
    $sql_statement = "show table status from $database;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      $TableName = @arr[0];
      push(@optim,$TableName);
    }
    foreach $TableName(@optim) {
      $TableCount++;
      $sql_statement = "check table $TableName;";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      #@arr = $sth->info();
      $TableResult = $sth->as_string;
      if ((index($TableResult,"status") > -1) && (index($TableResult,"OK") > -1)) {
        $OkCount++;
        $TableState = "dbase_ok.gif";
      }
      else {
        $ErrorCount++;
        $TableState = "dbase_error.gif";
      }
      $DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\">$TableName</td><td class=\"ListCellRight\"><img src=\"../images/site_admin/".$TableState."\"></td></tr>\n";    
      $StatReport = $StatReport.$TableResult;
    }
    if ($ErrorCount > 0) { $StatusMessage = "2|$TableCount tables where checked - $ErrorCount errors found<br>Please run the table repair option"; }
    else { $StatusMessage = "0|$TableCount tables where checked - 0 errors found"; }
  }
  if ($step eq "repair") {
    $DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\"><b>Table Name</b></td><td class=\"ListCellRight\"><b>Status<b></td></tr>\n";
    $sql_statement = "show table status from $database;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
      $TableName = @arr[0];
      push(@optim,$TableName);
    }
    foreach $TableName(@optim) {
      $TableCount++;
      $sql_statement = "repair table $TableName;";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      #@arr = $sth->info();
      $TableResult = $sth->as_string;
      if ((index($TableResult,"status") > -1) && (index($TableResult,"OK") > -1)) {
        $OkCount++;
        $TableState = "dbase_ok.gif";
      }
      else {
        $ErrorCount++;
        $TableState = "dbase_error.gif";
      }
      $DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\">$TableName</td><td class=\"ListCellRight\"><img src=\"../images/site_admin/".$TableState."\"></td></tr>\n";
      $StatReport = $StatReport.$TableResult;
    }
    if ($ErrorCount > 0) { $StatusMessage = "2|$TableCount tables where repaired - $ErrorCount errors still exist! An email has been sent to tech support detailing the nature of the error."; }
    else { $StatusMessage = "0|$TableCount tables where repaired - all errors were repaired successfully"; }
  }
  sleep(2);
  $func = "home";
  &display_admin_home;
}

sub display_admin_home {
  $sql_statement = "show table status from $database;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    $TableName = @arr[0];
    $DataLength = @arr[4];
    $IndexLength = @arr[5];
    $DataUsage = (($DataLength * $IndexLength) / 1024);
    $DataUsage = sprintf("%.2f",$DataUsage);
    if ($TableName eq "admin_accesslog") { $TempDataUsage = $TempDataUsage + $DataUsage; }
    if ($TableName eq "bench_mark") { $TempDataUsage = $TempDataUsage + $DataUsage; }
    if ($TableName eq "shopping_basket") { $TempDataUsage = $TempDataUsage + $DataUsage; }
    if ($TableName eq "user_session") { $TempDataUsage = $TempDataUsage + $DataUsage; }
    $DataTotal = $DataTotal + $DataUsage;
    #$DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\">$TableName</td><td class=\"ListCellRight\">$DataLength|$DataUsage|$IndexLength&nbsp;</td></tr>\n";
  }
  $TempDataUsage = $TempDataUsage / 1024;
  $TempDataUsage = sprintf("%.2f",$TempDataUsage);
  $DataTotal = $DataTotal / 1024;
  $DataTotal = sprintf("%.2f",$DataTotal);
  $DataCritical = $DataTotal - $TempDataUsage;
  $DataCritical = sprintf("%.2f",$DataCritical);

  $DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\">Temporary Data (MB)</td><td class=\"ListCellRight\">$TempDataUsage</td></tr>\n";
  $DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\">Critical Data (MB)</td><td class=\"ListCellRight\">$DataCritical</td></tr>\n";
  $DatabaseDetail = $DatabaseDetail."<tr><td class=\"ListCell\">Database Total (MB)</td><td class=\"ListCellRight\"><b>$DataTotal</b></td></tr>\n";

  $sql_statement = "select max(ExecTime) from bench_mark where ExecTime < '200' and ExecTime > '0.001';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $MaxProcSpeed = @arr[0];
  $sql_statement = "select min(ExecTime) from bench_mark where ExecTime < '200' and ExecTime > '0.001';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $MinProcSpeed = @arr[0];
  $sql_statement = "select avg(ExecTime) from bench_mark where ExecTime < '200' and ExecTime > '0.001';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $AvgProcSpeed = @arr[0];
  $MaxProcSpeed = sprintf("%.3f",$MaxProcSpeed);
  $MinProcSpeed = sprintf("%.3f",$MinProcSpeed);
  $AvgProcSpeed = sprintf("%.3f",$AvgProcSpeed);

  $ProcessDetail = $ProcessDetail."<tr><td class=\"ListCell\">- Maximum (S)</td><td class=\"ListCellRight\">$MaxProcSpeed</td></tr>\n";
  $ProcessDetail = $ProcessDetail."<tr><td class=\"ListCell\">- Minimum (S)</td><td class=\"ListCellRight\">$MinProcSpeed</td></tr>\n";
  $ProcessDetail = $ProcessDetail."<tr><td class=\"ListCell\">- Average (S)</td><td class=\"ListCellRight\">$AvgProcSpeed</td></tr>\n";

  $UptimeDays = "0";
  $UptimeHours = "0";
  
  $sql_statement = "show status;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($VarName,$VarValue) = @arr;
    if ($VarName eq "Uptime") {
      for ($a=0; $a <= 2500; $a++) {
        $VarValue = $VarValue - 3600;
        if ($VarValue > 0) {
          $UptimeHours++;
          if ($UptimeHours >= 23) { $UptimeHours = "0"; $UptimeDays++; }
        }
      }
      $ProcessDetail = $ProcessDetail."<tr><td class=\"ListCell\">- Uptime</td><td class=\"ListCellRight\">$UptimeDays days $UptimeHours hours&nbsp;</td></tr>\n";
    }
    if ($VarName eq "Connections") { $ProcessDetail = $ProcessDetail."<tr><td class=\"ListCell\">- Connections</td><td class=\"ListCellRight\">$VarValue&nbsp;</td></tr>\n"; }


  }
  
  $sql_statement = "SELECT SearchTerm,ResultCount FROM search_terms ORDER BY TimeStamp DESC LIMIT 0,5;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($SearchTerm,$ResultCount) = @arr;
    $SearchList = $SearchList."<tr><td class=\"ListCell\">$SearchTerm</td><td class=\"ListCellRight\">$ResultCount</td></tr>\n";
  }
  $SearchList = $SearchList."<tr><td class=\"ListHeaderLeft\">Most Popular Search Terms</td><td align=\"right\" class=\"ListHeaderRight\">Count</td></tr>\n";

  $sql_statement = "SELECT SearchTerm,COUNT(*) AS number FROM search_terms GROUP BY SearchTerm ORDER BY number DESC LIMIT 0,10;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($SearchTerm,$SearchCount) = @arr;
    $SearchList = $SearchList."<tr><td class=\"ListCell\">$SearchTerm</td><td class=\"ListCellRight\">$SearchCount</td></tr>\n";
  }
#$SearchList = $SearchList."<tr><td class=\"ListCell\" colspan=\"2\">- Temporarily Disabled -</td></tr>\n";

  $sql_statement = "SELECT ProdId,ProdName,ViewCount FROM prod_base ORDER BY ViewCount DESC LIMIT 0,5;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($RProdId,$RProdName,$RViewCount) = @arr;
    if (length($RProdName) > 28) { $RProdName = substr($RProdName,0,28); $RProdName = $RProdName."..."; }
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    $PopViewList = $PopViewList."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $PopViewList = $PopViewList." <td class=\"ListCell\"><a href=\"dbadmin.pl?f=prods&s=show&pid=$RProdId\">$RProdName</a></td>\n";
    $PopViewList = $PopViewList." <td class=\"ListCellRight\">$RViewCount</td>\n</tr>\n";
  }
  $sql_statement = "SELECT ProdId,ProdName,ViewCount FROM prod_base ORDER BY ProdId DESC LIMIT 0,5;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($RProdId,$RProdName,$RViewCount) = @arr;
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    if (length($RProdName) > 40) { $RProdName = substr($RProdName,0,40); $RProdName = $RProdName."..."; }
    $RecViewList = $RecViewList."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $RecViewList = $RecViewList." <td class=\"ListCell\" colspan=\"2\"><a href=\"dbadmin.pl?f=prods&s=show&pid=$RProdId\">$RProdName</a></td>\n</tr>\n";
  }
  $sql_statement = "SELECT OrderId,InvoiceNum,OrderTotal,TimeStamp,OrderStat FROM order_main ORDER BY OrderId DESC,OrderStat LIMIT 0,5;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($ROrderId,$RInvoiceNum,$ROrderTotal,$RTimeStamp,$ROrderStat) = @arr;
    if ($ROrderStat eq "0") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/lock.png\" border=\"0\" alt=\"Incomplete\" align=\"absmiddle\">"; }
    elsif ($ROrderStat eq "1") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/waiting.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($ROrderStat eq "2") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/delivery.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($ROrderStat eq "3") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/on_hold.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($ROrderStat eq "4") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/cancel.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }  
    &convert_timestamp($RTimeStamp);
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    $RecOrderList = $RecOrderList."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $RecOrderList = $RecOrderList." <td class=\"ListCell\"><a href=\"dbadmin.pl?f=order&s=show&oid=$ROrderId\">$RInvoiceNum</a></td>\n";
    $RecOrderList = $RecOrderList." <td class=\"ListCellRight\">$ConvTimeDate</td>\n";
    $RecOrderList = $RecOrderList." <td class=\"ListCellRight\">$ROrderTotal</td>\n";
    $RecOrderList = $RecOrderList." <td class=\"ListCellRight\">$ROrderStat</td>\n</tr>\n";
  }
  $RecOrderList = $RecOrderList."<tr><td colspan=\"4\" class=\"ListHeaderSub\">Reseller Orders</td></tr>\n";
  $sql_statement = "SELECT OrderId,InvoiceNum,OrderTotal,TimeStamp,OrderStat FROM reseller_order ORDER BY OrderId DESC,OrderStat LIMIT 0,5;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($ROrderId,$RInvoiceNum,$ROrderTotal,$RTimeStamp,$ROrderStat) = @arr;
    if ($ROrderStat eq "0") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/lock.png\" border=\"0\" alt=\"Incomplete\" align=\"absmiddle\">"; }
    elsif ($ROrderStat eq "1") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/waiting.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($ROrderStat eq "2") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/delivery.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($ROrderStat eq "3") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/on_hold.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }
    elsif ($ROrderStat eq "4") { $ROrderStat = "<img hspace=\"1\" src=\"../images/site_admin/cancel.png\" border=\"0\" alt=\"Pending\" align=\"absmiddle\">"; }  
    &convert_timestamp($RTimeStamp);
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    $RecOrderList = $RecOrderList."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $RecOrderList = $RecOrderList." <td class=\"ListCell\"><a href=\"dbadmin.pl?f=order&s=reshow&oid=$ROrderId\">$RInvoiceNum</a></td>\n";
    $RecOrderList = $RecOrderList." <td class=\"ListCellRight\">$ConvTimeDate</td>\n";
    $RecOrderList = $RecOrderList." <td class=\"ListCellRight\">$ROrderTotal</td>\n";
    $RecOrderList = $RecOrderList." <td class=\"ListCellRight\">$ROrderStat</td>\n</tr>\n";
  }
  $sql_statement = "SELECT ResId,CompanyName,SignDate FROM reseller_details WHERE StatFlag = '2' ORDER BY ResId DESC LIMIT 0,5;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($RResId,$RCompanyName,$RSignDate) = @arr;
    &convert_timestamp($RSignDate);
    if ($BgFlag == 1) { $BgFlag = "0"; $BgClass = "ListStyle1"; } else { $BgFlag = "1"; $BgClass = "ListStyle2"; }
    $RecResellList = $RecResellList."<tr class=\"$BgClass\" onMouseOver=\"this.className='ListHighlight'\" onMouseOut=\"this.className='$BgClass'\">\n";
    $RecResellList = $RecResellList." <td class=\"ListCell\" colspan=\"2\"><a href=\"dbadmin.pl?f=reseller&s=view&rid=$RResId\">$RCompanyName</a></td>\n";
    $RecResellList = $RecResellList." <td class=\"ListCellRight\" colspan=\"2\">$ConvTimeDate</td>\n</tr>";
  }
  
  #$WriteHTML =~ s/_RECAFFILS_/$RecAffilList/g;
 

  $PageHeader = "Administrators Home Page [$UserName]";
  $page = "admin_home";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------

sub display_page_requested {

$getpage = $docroot."admin_menu_".$AdminLevel."\.html";
open (INPHILE, "<$getpage");
@indata=<INPHILE>;
close(INPHILE);

foreach $line(@indata) {
    $line =~ s/_UID_/$uid/g;
    $MenuString = $MenuString.$line;
}

$getpage = $docroot.$page."\.html";

if ($FirstVisit eq "") { push(@writecookie,"tonFirstVisit|$TimeStamp"); }
if ($uid ne "") { push(@writecookie,"tonAdUniqueId|$uid"); }

print "Content-type: text/html\n";
foreach $Temp(@writecookie) {
  ($CookieName,$CookieValue) = split(/\|/,$Temp);
  $query = new CGI;
  $cookie = $query->cookie(-name=>$CookieName,-value=>$CookieValue,-expires=>'+12M',-path=>'/');
  $XString = $XString."Set-Cookie: ".$cookie."\n";
  push(@debugstring,"W COOKIE: $CookieName||$CookieValue");
}
print $XString;
$query = new CGI;
$cookie = $query->cookie(-name=>'tonLastView',-value=>$TimeStamp,-expires=>'+12M',-path=>'/');
$CString = $query->header(-cookie=>$cookie);
print $CString;


if ($StatusMessage ne "") {
  ($StatusType,$StatusMessage) = split(/\|/,$StatusMessage);
  if ($StatusType eq "0") { $StatusMessage = "<span class=\"StatusOk\"><img src=\"../images/status_ok.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</span>"; }
  if ($StatusType eq "1") { $StatusMessage = "<span class=\"StatusAlert\"><img src=\"../images/status_alert.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</span>"; }
  if ($StatusType eq "2") { $StatusMessage = "<span class=\"StatusStop\"><img src=\"../images/status_stop.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</span>"; }
}
if ($LoginFlag eq "1") { $LoginString = "Logged in as <b>$MailAddy</b> [<a href=\"../cgi-bin/index.pl?f=logout\">Logout</a>]"; }


print "\n\n<!-- Designed and Powered by W3b.co.za -->\n";

if ($AlertPrompt ne "") { $AlertPrompt = "\nwindow.alert(\"".$AlertPrompt."\");"; }

open (INPHILE, "<$getpage");
@indata=<INPHILE>;
close(INPHILE);

foreach $line(@indata) {
  $WriteHTML = $WriteHTML.$line;
}

#All pages
$WriteHTML =~ s/_PAGELINK_BOTTOM_/$PageLinkBottom \&nbsp;/g;
$WriteHTML =~ s/_CREDITTEXT_/$CreditText/g;
$WriteHTML =~ s/_PAGE_FUNCTION_/$func/g;
$WriteHTML =~ s/_PAGEINSERT_/$PageInsert/g;
$WriteHTML =~ s/_SITENAME_/$SiteName/g;
$WriteHTML =~ s/_ERROR_MESSAGE_/$ErrMsg/g;
$WriteHTML =~ s/_ALERT_PROMPT_/$AlertPrompt/g;
$WriteHTML =~ s/_STATMSG_/$StatusMessage/g;
$WriteHTML =~ s/_SET_FOCUS_/$SetFormFocus/g;
$WriteHTML =~ s/_DATE_TIME_/$DateNow/g;
$WriteHTML =~ s/_UID_/$uid/g;
$WriteHTML =~ s/_USERID_/$UserId/g;
$WriteHTML =~ s/_FIRSTNAME_/$FirstName/g;
$WriteHTML =~ s/_LAST_LOGIN_/$LastLogin/g;
$WriteHTML =~ s/_USERNAME_/$UserName/g;
$WriteHTML =~ s/_ADMINMENU_/$MenuString/g;
$WriteHTML =~ s/_ATTCOUNT_/$AttCount/g;
$WriteHTML =~ s/_PAGEHEADER_/$PageHeader/g;
$WriteHTML =~ s/_OFFSET_/$OffSet/g;
$WriteHTML =~ s/_CONVDATE_/$ConvDate/g;
$WriteHTML =~ s/_ADMINMAIL_/$AdminEmailAddy/g;
$WriteHTML =~ s/_COUNTRYNAME_/$CountryName/g;
$WriteHTML =~ s/_NEXT_ID_/$NextId/g;
$WriteHTML =~ s/_OFFSET_/$OffSet/g;
$WriteHTML =~ s/_ORDERBY_/$OrderBy/g;
$WriteHTML =~ s/_ORDERRANGE_/$OrderRange/g;
$WriteHTML =~ s/_NEXTLINK_/$NextLink/g;
$WriteHTML =~ s/_PREVLINK_/$PrevLink/g;
$WriteHTML =~ s/_TIMESTAMP_/$TimeStamp/g;
$WriteHTML =~ s/_NOTEFLASH_/$NoteFlash/g;
$WriteHTML =~ s/_CLK_/$NotePadCount/g;
$WriteHTML =~ s/_NOTEPADLINK_/$NotePadLink/g;
$WriteHTML =~ s/_SEARCHKEY_/$SearchKey/g;
$WriteHTML =~ s/_SEARCHKEY2_/$SearchKey2/g;
$WriteHTML =~ s/_NAVLINK_/$RNavLink/g;
$WriteHTML =~ s/_CAT_1_/$CLevel1/g;
$WriteHTML =~ s/_CAT_2_/$CLevel2/g;
$WriteHTML =~ s/_CAT_3_/$CLevel3/g;
$WriteHTML =~ s/_PSORTTYPE_/$SortType/g;
$WriteHTML =~ s/_PSORTDATA_/$SortData/g;
$WriteHTML =~ s/_SORTDIR_/$SortDir/g;
$WriteHTML =~ s/_DISPLAYPRIORITY_/$DisplayPriorityList/g;
$WriteHTML =~ s/_DISPLAY_LEVEL_/$DisplayPriority/g;

$WriteHTML =~ s/_TABLELISTING_/$TableListing/g;
$WriteHTML =~ s/_RESULTTEXT_/$ResultText/g;
$WriteHTML =~ s/_DISPLAYCATEGORY_/$ProdCategoryList/g;
$WriteHTML =~ s/_BANNERFRAME_/$BannerFrame/g;

$WriteHTML =~ s/_JAVAARRAY_1_/$JavaArray_1/g;
$WriteHTML =~ s/_JAVAARRAY_2_/$JavaArray_2/g;
$WriteHTML =~ s/_JAVAARRAY_3_/$JavaArray_3/g;
$WriteHTML =~ s/_JAVAARRAY_4_/$JavaArray_4/g;
$WriteHTML =~ s/_JAVAARRAY_5_/$JavaArray_5/g;

if (($func eq "order") || ($func eq "buyer") || ($func eq "reseller")) {
  $WriteHTML =~ s/_DISPLAYFIELDS_/$SearchFieldList/g;
  $WriteHTML =~ s/_DISPLAYSORTS_/$SortOptionList/g;

  $WriteHTML =~ s/_BASKET_LISTING_/$BasketListing/g;
  $WriteHTML =~ s/_SBTT_/$OrderSub/g;
  $WriteHTML =~ s/_VBTT_/$OrderVat/g;
  $WriteHTML =~ s/_DCTT_/$OrderDel/g;
  $WriteHTML =~ s/_ABTT_/$OrderTotal/g;
  $WriteHTML =~ s/_INSCT_/$OrderInsure/g;
  $WriteHTML =~ s/_ABTTX_/$BasketShopTotal/g;
  $WriteHTML =~ s/_ICTT_/$BasketCount/g;
  $WriteHTML =~ s/_CMARK_/$CurrencyMark/g;
  $WriteHTML =~ s/_PURCHASEHIST_/$PurchaseHistory/g;
  $WriteHTML =~ s/_TOTALPURCHASE_/$PurchaseTotal/g;

  $WriteHTML =~ s/_VOUCHERCODE_/$VoucherCode/g;
  $WriteHTML =~ s/_VATNUMBER_/$VatNumber/g;
  $WriteHTML =~ s/_IDNUMBER_/$IdNumber/g;
  $WriteHTML =~ s/_INVDATE_/$InvoiceDate/g;
  $WriteHTML =~ s/_ORDERID_/$OrderId/g;
  $WriteHTML =~ s/_ORDERSTAT_/$OrderStat/g;
  $WriteHTML =~ s/_PAYOPTION_/$PayOption/g;
  $WriteHTML =~ s/_BUYERID_/$BuyerId/g;
  $WriteHTML =~ s/_SESSIONID_/$XSessionId/g;
  $WriteHTML =~ s/_TIMESTAMP_/$XTimeStamp/g;
  $WriteHTML =~ s/_ORDERSUB_/$OrderSub/g;
  $WriteHTML =~ s/_ORDERVAT_/$OrderVat/g;
  $WriteHTML =~ s/_ORDERDEL_/$OrderDel/g;
  $WriteHTML =~ s/_ORDERTOTAL_/$OrderTotal/g;
  $WriteHTML =~ s/_DELIVERFROM_/$DeliverFrom/g;
  $WriteHTML =~ s/_DELIVERTO_/$DeliverTo/g;
  $WriteHTML =~ s/_DELDAYFROM_/$DelDayFrom/g;
  $WriteHTML =~ s/_DELDAYTO_/$DelDayTo/g;
  $WriteHTML =~ s/_DELIVERNOTE_/$DeliverNote/g;
  $WriteHTML =~ s/_INVOICENUM_/$InvoiceNum/g;
  $WriteHTML =~ s/_SUBMITIP_/$SubmitIP/g;
  $WriteHTML =~ s/_TRANSACTID_/$TransactId/g;
  $WriteHTML =~ s/_CMARK_/$CurrencyMark/g;
  $WriteHTML =~ s/_WAYBILLNUMBER_/$WayBillNumber/g;

	$WriteHTML =~ s/_DELWEIGHT_/$XOrderWeight/g;
	$WriteHTML =~ s/_OPTIONNAME_/$OptionName/g;
	$WriteHTML =~ s/_DELIVERTIME_/$DeliverTime/g;
  $WriteHTML =~ s/_ESTDELIVER_/$EstDeliver/g;

    #$line =~ s/_POSTAL_1_/$PostalOne/g;
    #$line =~ s/_POSTAL_2_/$PostalTwo/g;
    #$line =~ s/_POSTAL_3_/$PostalThree/g;


  $WriteHTML =~ s/_MAILADDY_/$MailAddy/g;
  $WriteHTML =~ s/_SIGNDATE_/$SignDate/g;
  $WriteHTML =~ s/_PASSWORD_/$PassWord/g;
  $WriteHTML =~ s/_TITLE_/$Title/g;
  $WriteHTML =~ s/_FIRSTNAME_/$FirstName/g;
  $WriteHTML =~ s/_SURNAME_/$SurName/g;
  $WriteHTML =~ s/_DATEOFBIRTH_/$DateOfBirth/g;
  $WriteHTML =~ s/_TELAREACODE_/$TelAreaCode/g;
  $WriteHTML =~ s/_TELEPHONE_/$Telephone/g;
  $WriteHTML =~ s/_FAXAREACODE_/$FaxAreaCode/g;
  $WriteHTML =~ s/_FAXNUM_/$FaxNum/g;
  $WriteHTML =~ s/_COMPANY_/$Company/g;
  $WriteHTML =~ s/_DELIVERYONE_/$DeliveryOne/g;
  $WriteHTML =~ s/_DELIVERYTWO_/$DeliveryTwo/g;
  $WriteHTML =~ s/_DELIVERYTHREE_/$DeliveryThree/g;
  $WriteHTML =~ s/_CITYTOWN_/$CityTown/g;
  $WriteHTML =~ s/_PROVINCE_/$Province/g;
  $WriteHTML =~ s/_POSTALCODE_/$PostalCode/g;
  $WriteHTML =~ s/_COUNTRYNAME_/$CountryName/g;
  $WriteHTML =~ s/_PAYOPTION_/$PayOption/g;
  $WriteHTML =~ s/_PAYNOTES_/$PayNotes/g;
  $WriteHTML =~ s/_DELIVER_NOTES_/$PayNotes/g;
  $WriteHTML =~ s/_DELIVERFROM_/$DeliverFrom/g;
  $WriteHTML =~ s/_DELIVERTO_/$DeliverTo/g;
  $WriteHTML =~ s/_DELDAYFROM_/$DelDayFrom/g;
  $WriteHTML =~ s/_DELDAYTO_/$DelDayTo/g;

  $WriteHTML =~ s/_OSTATUS_/$OrderStatus/g;
  $WriteHTML =~ s/_PAYREFNR_/$SafePayRefNr/g;
  $WriteHTML =~ s/_BANKREFNR_/$BankRefNr/g;
  $WriteHTML =~ s/_INVOICE_STRING_/$InvoiceString/g;
  $WriteHTML =~ s/_DELIVERDATE_/$DeliverDate/g;
  $WriteHTML =~ s/_ADMINCOMMENT_/$AdminComment/g;
  $WriteHTML =~ s/_SESSION_ID_/$XSessionId/g;
  $WriteHTML =~ s/_BUYSESSION_/$XSessionId/g;


}
if (($func eq "reseller") || ($func eq "order")) {
  $WriteHTML =~ s/_DISPLAYFIELDS_/$SearchFieldList/g;
  $WriteHTML =~ s/_DISPLAYSORTS_/$SortOptionList/g;
  $WriteHTML =~ s/_COMPANYNAME_/$CompanyName/g;
  $WriteHTML =~ s/_COMPANYREG_/$CompanyReg/g;
  $WriteHTML =~ s/_VATNUMBER_/$VatNumber/g;
  $WriteHTML =~ s/_ACCOUNTNUMBER_/$AccountNumber/g;
  $WriteHTML =~ s/_TITLE_/$Title/g;
  $WriteHTML =~ s/_FIRSTNAME_/$FirstName/g;
  $WriteHTML =~ s/_SURNAME_/$SurName/g;
  $WriteHTML =~ s/_IDNUMBER_/$IdNumber/g;
  $WriteHTML =~ s/_EMAILADDRESS_/$EmailAddress/g;
  $WriteHTML =~ s/_TELAREA_/$TelArea/g;
  $WriteHTML =~ s/_TELEPHONE_/$Telephone/g;
  $WriteHTML =~ s/_FAXAREA_/$FaxArea/g;
  $WriteHTML =~ s/_FAXNUM_/$FaxNum/g;
  $WriteHTML =~ s/_MOBILE_/$Mobile/g;
  $WriteHTML =~ s/_PHYSICALADDRESS_/$PhysicalAddress/g;
  $WriteHTML =~ s/_POSTALADDRESS_/$PostalAddress/g;
  $WriteHTML =~ s/_CITYTOWN_/$CityTown/g;
  $WriteHTML =~ s/_COUNTRY_/$Country/g;
  $WriteHTML =~ s/_PROVINCE_/$Province/g;
  $WriteHTML =~ s/_POSTCODE_/$PostalCode/g;
  $WriteHTML =~ s/_WEBURL_/$WebURL/g;
  $WriteHTML =~ s/_PASSWORD_/$PassWord/g;
  $WriteHTML =~ s/_BUSINESSDESCRIPT_/$BusinessDescript/g;
  $WriteHTML =~ s/_RES_ID_/$ResId/g;
  $WriteHTML =~ s/_RESSTAT_/$ResStatus/g;
  $WriteHTML =~ s/_DISCOUNT_RATELIST_/$DiscRateListing/g;
  $WriteHTML =~ s/_CS_LOGO_/$CsImage/g;
  $WriteHTML =~ s/_CS_NAME_/$CsName/g;
  $WriteHTML =~ s/_CS_VATNUM_/$CsVatNum/g;
  $WriteHTML =~ s/_CS_REGNUM_/$CsRegNum/g;
  $WriteHTML =~ s/_CS_POSTAL_/$CsPostal/g;
  $WriteHTML =~ s/_CS_PHYSIC_/$CsPhysical/g;
  $WriteHTML =~ s/_CS_TELE_/$CsTele/g;
  $WriteHTML =~ s/_CS_FAXN_/$CsFax/g;
  $WriteHTML =~ s/_CS_MAIL_/$CsEmail/g;
  $WriteHTML =~ s/_CS_URL_/$CsUrl/g;
  $WriteHTML =~ s/_CS_URLEX_/$CsUrlEx/g;
  $WriteHTML =~ s/_CS_BANK_/$CsBank/g;
  $WriteHTML =~ s/_CS_SLOGAN_/$CsSlogan/g;
  $WriteHTML =~ s/_INSCT_/$OrderInsure/g;
  $WriteHTML =~ s/_ORDER_ID_/$OrderId/g;
  $WriteHTML =~ s/_ACCOUNTNUMBER_/$AccountNumber/g;
  $WriteHTML =~ s/_RESNOTES_/$ResellerNotes/g;
}
if (($func eq "resinvoice") || ($func eq "custinvoice")) {
  $WriteHTML =~ s/_SBTT_/$OrderSub/g;
  $WriteHTML =~ s/_VBTT_/$OrderVat/g;
  $WriteHTML =~ s/_DCTT_/$OrderDel/g;
  $WriteHTML =~ s/_ABTT_/$OrderTotal/g;
  $WriteHTML =~ s/_ABTTX_/$BasketShopTotal/g;
  $WriteHTML =~ s/_ICTT_/$BasketCount/g;
  $WriteHTML =~ s/_INSCT_/$OrderInsure/g;
  $WriteHTML =~ s/_CMARK_/$CurrencyMark/g;
  $WriteHTML =~ s/_DELWEIGHT_/$XOrderWeight/g;
  $WriteHTML =~ s/_OPTIONNAME_/$OptionName/g;
  $WriteHTML =~ s/_DELIVERTIME_/$DeliverTime/g;
  $WriteHTML =~ s/_EMAILADDRESS_/$EmailAddress/g;
  $WriteHTML =~ s/_CTITLE_/$Title/g;
  $WriteHTML =~ s/_FNAME_/$FirstName/g;
  $WriteHTML =~ s/_SNAME_/$SurName/g;
  $WriteHTML =~ s/_TAREA_/$TelArea/g;
  $WriteHTML =~ s/_TELEPHONE_/$Telephone/g;
  $WriteHTML =~ s/_FAREA_/$FaxArea/g;
  $WriteHTML =~ s/_FAX_/$FaxNum/g;
  $WriteHTML =~ s/_COMPANYNAME_/$CompanyName/g;
  $WriteHTML =~ s/_IDNUMBER_/$IdNumber/g;
  $WriteHTML =~ s/_VATNUMBER_/$VatNumber/g;
  $WriteHTML =~ s/_ESTDELIVER_/$EstDeliver/g;
  $WriteHTML =~ s/_COMPANYREG_/$CompanyReg/g;
  $WriteHTML =~ s/_POSTALADDRESS_/$PostalAddress/g;
  $WriteHTML =~ s/_PROVINCE_/$PostProvince/g;
  $WriteHTML =~ s/_DELIVERY_1_/$DeliveryAddress/g;
  $WriteHTML =~ s/_CITYTOWN_/$CityTown/g;
  $WriteHTML =~ s/_PROVINCE_/$Province/g;
  $WriteHTML =~ s/_POSTCODE_/$PostCode/g;
  $WriteHTML =~ s/_COUNTRY_/$Country/g;
  $WriteHTML =~ s/_DELIVER_FROM_/$DeliverFrom/g;
  $WriteHTML =~ s/_DELIVER_TO_/$DeliverTo/g;
  $WriteHTML =~ s/_DELIVER_NOTES_/$DeliverNote/g;
  $WriteHTML =~ s/_DELDAY_FROM_/$DeldayFrom/g;
  $WriteHTML =~ s/_DELDAY_TO_/$DeldayTo/g;
  $WriteHTML =~ s/_PRFNUM_/$InvoiceNumber/g;
  $WriteHTML =~ s/_VOUCHER_CODE_/$VoucherCode/g;
  $WriteHTML =~ s/_PRFNUM_/$InvoiceNumber/g;
  $WriteHTML =~ s/_INVNUM_/$InvoiceNumber/g;
  $WriteHTML =~ s/_ACCOUNTNUMBER_/$AccountNumber/g;
  $WriteHTML =~ s/_INVDATE_/$InvoiceDate/g;
  $WriteHTML =~ s/_INVOICE_STRING_/$InvoiceString/g;
  $WriteHTML =~ s/_DATEBIRTH_/$DateOfBirth/g;
  $WriteHTML =~ s/_TRANSACTID_/$TransactId/g;
  $WriteHTML =~ s/_LOGREFNR_/$LogRefNr/g;
  $WriteHTML =~ s/_MERCHANTREFERENCE_/$MerchantReference/g;
  $WriteHTML =~ s/_RECEIPTURL_/$ReceiptURL/g;
  $WriteHTML =~ s/_TRANSACTIONAMOUNT_/$TransactionAmount/g;
  $WriteHTML =~ s/_TRANSACTIONTYPE_/$TransactionType/g;
  $WriteHTML =~ s/_TRANSACTIONRESULT_/$TransactionResult/g;
  $WriteHTML =~ s/_TRANSACTIONERRORRESPONSE_/$TransactionErrorResponse/g;
  $WriteHTML =~ s/_SAFEPAYREFNR_/$SafePayRefNr/g;
  $WriteHTML =~ s/_BANKREFNR_/$BankRefNr/g;
  $WriteHTML =~ s/_LIVETRANSACTION_/$LiveTransaction/g;
  $WriteHTML =~ s/_SAFETRACK_/$SafeTrack/g;
  $WriteHTML =~ s/_BUYERCREDITCARDNR_/$BuyerCreditCardNr/g;
  $WriteHTML =~ s/_CS_LOGO_/$CsImage/g;
  $WriteHTML =~ s/_CS_NAME_/$CsName/g;
  $WriteHTML =~ s/_CS_VATNUM_/$CsVatNum/g;
  $WriteHTML =~ s/_CS_REGNUM_/$CsRegNum/g;
  $WriteHTML =~ s/_CS_POSTAL_/$CsPostal/g;
  $WriteHTML =~ s/_CS_PHYSIC_/$CsPhysical/g;
  $WriteHTML =~ s/_CS_TELE_/$CsTele/g;
  $WriteHTML =~ s/_CS_FAXN_/$CsFax/g;
  $WriteHTML =~ s/_CS_MAIL_/$CsEmail/g;
  $WriteHTML =~ s/_CS_URL_/$CsUrl/g;
  $WriteHTML =~ s/_CS_URLEX_/$CsUrlEx/g;
  $WriteHTML =~ s/_CS_BANK_/$CsBank/g;
  $WriteHTML =~ s/_CS_SLOGAN_/$CsSlogan/g;
}

if ($func eq "forex") {
  $WriteHTML =~ s/_USDVAL_/$UsdVal/g;
  $WriteHTML =~ s/_GBPVAL_/$GbpVal/g;
  $WriteHTML =~ s/_EURVAL_/$EurVal/g;
  $WriteHTML =~ s/_FOREXDATE_/$ForexDate/g;
}
if ($func eq "cats") {
  $WriteHTML =~ s/_NEWCATNAME_/$NewCatName/g;
  $WriteHTML =~ s/_NEWCATDESC_/$NewCatDesc/g;
  $WriteHTML =~ s/_MOVECATTEXT_/$MoveCatText/g;
  $WriteHTML =~ s/_CATSTEP_/$CatStep/g;
  $WriteHTML =~ s/_CLEVEL_/$CatLevel/g;
  $WriteHTML =~ s/_CATPATH_/$CatPath/g;
  $WriteHTML =~ s/_CAT_IMAGE_/$CatImage/g;
  $WriteHTML =~ s/_CAT_NAME_/$CatName/g;
  $WriteHTML =~ s/_MAINCAT_IMAGE_/$MainCatImage/g;
  $WriteHTML =~ s/_MAINCATNAME_/$CatName/g;
  $WriteHTML =~ s/_MAINCATDESC_/$MainCatDescript/g;

  $WriteHTML =~ s/_CATICONLISTNEW_/$CatIconListNew/g;
  $WriteHTML =~ s/_CATICONLISTEDIT_/$CatIconListEdit/g;
}
if ($func eq "prods") {
  $WriteHTML =~ s/_DISPLAYALPHA_/$ProdAlphaList/g;
  $WriteHTML =~ s/_DISPLAYSTATUS_/$ProdStatusList/g;
  $WriteHTML =~ s/_BRANDID_/$BrandId/g;
  $WriteHTML =~ s/_PRODID_/$ProdId/g;
  $WriteHTML =~ s/_ORDERCODE_/$OrderCode/g;
  $WriteHTML =~ s/_MFID_/$MfId/g;
  $WriteHTML =~ s/_LEVEL1_/$Level1/g;
  $WriteHTML =~ s/_LEVEL2_/$Level2/g;
  $WriteHTML =~ s/_LEVEL3_/$Level3/g;
  $WriteHTML =~ s/_MODEL_/$Model/g;
  $WriteHTML =~ s/_PRODNAME_/$ProdName/g;
  $WriteHTML =~ s/_PRODSIZE_/$ProdSize/g;
  $WriteHTML =~ s/_RETAILPRICE_/$RetailPrice/g;
  $WriteHTML =~ s/_MARKUPPRICE_/$MarkupPrice/g;
  $WriteHTML =~ s/_COSTPRICE_/$CostPrice/g;
  $WriteHTML =~ s/_DELCHARGE_/$DelCharge/g;
  $WriteHTML =~ s/_PROD_IMAGE_/$ProdImage/g;
  $WriteHTML =~ s/_PRODNOTES_/$ProdNotes/g;
  $WriteHTML =~ s/_PRODDATE_/$ProdDate/g;
  $WriteHTML =~ s/_ADDUSER_/$AddUser/g;
  $WriteHTML =~ s/_FEATURESUMM_/$FeatureSumm/g;
  $WriteHTML =~ s/_EXTRACOST_/$ExtraCost/g;
  $WriteHTML =~ s/_PACKUNIT_/$PackUnit/g;
  $WriteHTML =~ s/_STOCKLEVEL_/$StockLevel/g;
  $WriteHTML =~ s/_PRODWEIGHT_/$ProdWeight/g;
  $WriteHTML =~ s/_MINORDER_/$MinOrder/g;
  $WriteHTML =~ s/_FEATURETEXT_/$FeatureText/g;
  $WriteHTML =~ s/_FEATURELIST_/$FeatureList/g;
  $WriteHTML =~ s/_EXCOSTTYPE_/$ExCostType/g;
  $WriteHTML =~ s/_SUPPLYNAME_/$SupplyName/g;
  $WriteHTML =~ s/_EXTRASIZE_/$ExtraSize/g;
  $WriteHTML =~ s/_PRODFLAG_/$ProdFlag/g;
  $WriteHTML =~ s/_SPECFLAG_/$SpecFlag/g;
  $WriteHTML =~ s/_ROTATEFLAG_/$RotateFlag/g;
  $WriteHTML =~ s/_PRODCATLINK_/$ProdLinkList/g;
  $WriteHTML =~ s/_DUPCATLINK_/$DupCatLink/g;
  $WriteHTML =~ s/_DEFAULTKEYS_/$DefaultProdKeys/g;

  $WriteHTML =~ s/_PRODCONF_/$ProdConf/g;
  $WriteHTML =~ s/_SPECCONF_/$SpecConf/g;
  $WriteHTML =~ s/_PRODSET_/$ProdSet/g;
  $WriteHTML =~ s/_SPECSET_/$SpecSet/g;
  $WriteHTML =~ s/_BRANDLIST_/$BrandList/g;

  $WriteHTML =~ s/_OPTIONSUFFIX_0_/$OptionSuffix_0/g;
  $WriteHTML =~ s/_OPTIONSUFFIX_1_/$OptionSuffix_1/g;
  $WriteHTML =~ s/_OPTIONSUFFIX_2_/$OptionSuffix_2/g;
  $WriteHTML =~ s/_OPTIONSUFFIX_3_/$OptionSuffix_3/g;
  $WriteHTML =~ s/_OPTIONSUFFIX_4_/$OptionSuffix_4/g;
  $WriteHTML =~ s/_OPTIONSUFFIX_5_/$OptionSuffix_5/g;

  $WriteHTML =~ s/_OPTIONWEIGHT_0_/$OptionWeight_0/g;
  $WriteHTML =~ s/_OPTIONWEIGHT_1_/$OptionWeight_1/g;
  $WriteHTML =~ s/_OPTIONWEIGHT_2_/$OptionWeight_2/g;
  $WriteHTML =~ s/_OPTIONWEIGHT_3_/$OptionWeight_3/g;
  $WriteHTML =~ s/_OPTIONWEIGHT_4_/$OptionWeight_4/g;
  $WriteHTML =~ s/_OPTIONWEIGHT_5_/$OptionWeight_5/g;

  $WriteHTML =~ s/_OPTIONTEXT_0_/$OptionText_0/g;
  $WriteHTML =~ s/_OPTIONTEXT_1_/$OptionText_1/g;
  $WriteHTML =~ s/_OPTIONTEXT_2_/$OptionText_2/g;
  $WriteHTML =~ s/_OPTIONTEXT_3_/$OptionText_3/g;
  $WriteHTML =~ s/_OPTIONTEXT_4_/$OptionText_4/g;
  $WriteHTML =~ s/_OPTIONTEXT_5_/$OptionText_5/g;
  
  $WriteHTML =~ s/_OPTIONPRICE_0_/$OptionPrice_0/g;
  $WriteHTML =~ s/_OPTIONPRICE_1_/$OptionPrice_1/g;
  $WriteHTML =~ s/_OPTIONPRICE_2_/$OptionPrice_2/g;
  $WriteHTML =~ s/_OPTIONPRICE_3_/$OptionPrice_3/g;
  $WriteHTML =~ s/_OPTIONPRICE_4_/$OptionPrice_4/g;
  $WriteHTML =~ s/_OPTIONPRICE_5_/$OptionPrice_5/g;

  $WriteHTML =~ s/_OPTIONSTOCK_0_/$OptionStock_0/g;
  $WriteHTML =~ s/_OPTIONSTOCK_1_/$OptionStock_1/g;
  $WriteHTML =~ s/_OPTIONSTOCK_2_/$OptionStock_2/g;
  $WriteHTML =~ s/_OPTIONSTOCK_3_/$OptionStock_3/g;
  $WriteHTML =~ s/_OPTIONSTOCK_4_/$OptionStock_4/g;
  $WriteHTML =~ s/_OPTIONSTOCK_5_/$OptionStock_5/g;

  $WriteHTML =~ s/_KEYWORDS_/$KeyWords/g;
  $WriteHTML =~ s/_ORDEROPTIONS_/$OrderOptions/g;
}
if ($func eq "links") {
	$WriteHTML =~ s/_LINKNAME_/$LinkName/g;
	$WriteHTML =~ s/_LINKURL_/$LinkURL/g;
	$WriteHTML =~ s/_LINKDESCRIPT_/$LinkDescript/g;
	$WriteHTML =~ s/_LINKID_/$LinkId/g;
	$WriteHTML =~ s/_LINKARRAY_/$LinkArray/g;
	$WriteHTML =~ s/_NAMEARRAY_/$NameArray/g;
	$WriteHTML =~ s/_DESCARRAY_/$DescArray/g;
	$WriteHTML =~ s/_IDENTARRAY_/$IdentArray/g;

}
if ($func eq "luser") {
	$WriteHTML =~ s/_NFIRSTNAME_/$NewFirstName/g;
	$WriteHTML =~ s/_NSURNAME_/$NewSurName/g;
	$WriteHTML =~ s/_NUSERNAME_/$NewUser/g;
	$WriteHTML =~ s/_NEMAIL_/$EmailAddy/g;
	$WriteHTML =~ s/_ACCESSLEVEL_/$AccessLevel/g;
  $WriteHTML =~ s/_ACCESSLIST_/$AccessList/g;
}
if ($func eq "image") {
	$WriteHTML =~ s/_FOLDERLISTING_/$FolderListing/g;
	$WriteHTML =~ s/_FOLDERNAME_/$FolderName/g;
	$WriteHTML =~ s/_UPLOAD_LINK_/$UploadLink/g;
}
if ($func eq "home") {
	$WriteHTML =~ s/_SPR_/$PendSubs/g;
	$WriteHTML =~ s/_SPRF_/$PendSubsFlash/g;
	$WriteHTML =~ s/_SPA_/$ActSubs/g;
	$WriteHTML =~ s/_SPD_/$DisaSubs/g;
	$WriteHTML =~ s/_SPT_/$TotSubs/g;
	$WriteHTML =~ s/_ASP_/$AlertSubs/g;
	$WriteHTML =~ s/_ASPF_/$AlertSubsFlash/g;
  $WriteHTML =~ s/_DATABASE_DETAIL_/$DatabaseDetail/g;
  $WriteHTML =~ s/_PROCESS_DETAIL_/$ProcessDetail/g;
  $WriteHTML =~ s/_TRANSACT_DETAIL_/$TransactDetail/g;
  $WriteHTML =~ s/_SEARCH_LIST_/$SearchList/g;
  $WriteHTML =~ s/_VIEW_LIST_/$PopViewList/g;
  $WriteHTML =~ s/_RECENT_LIST_/$RecViewList/g;
  $WriteHTML =~ s/_BASKET_LIST_/$BasketList/g;
  $WriteHTML =~ s/_ORDER_LIST_/$RecOrderList/g;
  $WriteHTML =~ s/_RECRESELL_/$RecResellList/g;
  $WriteHTML =~ s/_RECAFFILS_/$RecAffilList/g;
}

if ($func eq "config") {
  $WriteHTML =~ s/_CURR_MARK_/$CurrencyMark/g;
  $WriteHTML =~ s/_FIXED_DEL_/$FixedDelCharge/g;
  $WriteHTML =~ s/_VAT_RATE_/$VatRate/g;
  $WriteHTML =~ s/_SUPPORTMAIL_/$SupportMail/g;
  $WriteHTML =~ s/_SERVICEMAIL_/$ServiceMail/g;
  $WriteHTML =~ s/_INFOMAIL_/$InfoMail/g;
  $WriteHTML =~ s/_SALESMAIL_/$SalesMail/g;
  $WriteHTML =~ s/_SENDERMAIL_/$MailSender/g;
  $WriteHTML =~ s/_CS_LOGO_/$CsImage/g;
  $WriteHTML =~ s/_CS_NAME_/$CsName/g;
  $WriteHTML =~ s/_CS_VATNUM_/$CsVatNum/g;
  $WriteHTML =~ s/_CS_REGNUM_/$CsRegNum/g;
  $WriteHTML =~ s/_CS_POSTAL_/$CsPostal/g;
  $WriteHTML =~ s/_CS_PHYSIC_/$CsPhysical/g;
  $WriteHTML =~ s/_CS_TELE_/$CsTele/g;
  $WriteHTML =~ s/_CS_FAXN_/$CsFax/g;
  $WriteHTML =~ s/_CS_MAIL_/$CsEmail/g;
  $WriteHTML =~ s/_CS_URL_/$CsUrl/g;
  $WriteHTML =~ s/_CS_URLEX_/$CsUrlEx/g;
  $WriteHTML =~ s/_CS_BANK_/$CsBank/g;
  $WriteHTML =~ s/_CS_SLOGAN_/$CsSlogan/g;
}

$WriteHTML =~ s/\\,/\,/g;
$WriteHTML =~ s/\\,/\,/g;
$WriteHTML =~ s/\\'/\'/g;
$WriteHTML =~ s/\\"/\"/g;

if ($AccessType ne "") {
    $sql_statement = "INSERT INTO admin_accesslog VALUES ('','$UserId','$TimeStamp','$QueryStringRep');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
}
if ($EventTrap ne "") {
    $sql_statement = "INSERT INTO system_eventlog VALUES ('','$EventTrap','$TimeStamp','$current_user');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
}

$t0 = [gettimeofday];
($seconds, $microseconds) = gettimeofday;
$EndTime = $seconds.".".$microseconds;
$ProcTime = $EndTime - $StartTime;
$ProcTime = sprintf("%.5f",$ProcTime);
print "\n<!-- Executed in $ProcTime seconds -->\n\n";

$sql_statement = "INSERT INTO bench_mark VALUES ('','$UserId','$TimeStamp','$ProcTime','$SysErrorFlag','$ScriptId','$QueryStringRep');";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;

if ($DebugMode eq "Y") {
  $DebugString = $DebugString."<table width=\"800\" border=\"0\" cellspacing=\"1\" cellpadding=\"1\" align=\"center\">\n";
  $DebugString = $DebugString."<tr><td colspan=\"2\"><b>...Debug Output...</b></td></tr>\n";
  $DebugString = $DebugString."<tr><td width=\"10%\" nowrap><b>Action</b></td><td nowrap><b>Value</b></td></tr>\n";
  $DebugString = $DebugString."<tr><td width=\"10%\" nowrap>Render Time</td><td nowrap>$ProcTime seconds</td></tr>\n";
  $DebugString = $DebugString."<tr><td width=\"10%\" nowrap>Template</td><td nowrap>$getpage</td></tr>\n";
  $DebugString = $DebugString."<tr><td width=\"10%\" nowrap>Query</td><td nowrap>$ENV{QUERY_STRING}</td></tr>\n";
  $DebugString = $DebugString."<tr><td width=\"10%\" nowrap>META</td><td nowrap>$KeyWordMeta<br>$DescriptionMeta</td></tr>\n";
  
  foreach $DebugData(@debugstring) {
    $DebugCount++;
    ($DebugAction,$DebugValue) = split(/\|\|/,$DebugData);
    $DebugString = $DebugString."<tr><td width=\"10%\" nowrap>$DebugCount : $DebugAction</td><td nowrap>$DebugValue</td></tr>\n";
  }
  $DebugString = $DebugString."</table>\n";
}

$WriteHTML =~ s/_DEBUGSTRING_/$DebugString/g;
$RenderTime = "\n<div align=\"center\"><span class=\"CreditText\">&laquo;-- Rendered in $ProcTime seconds --&raquo;</span></div>\n</body>\n</html>\n";
$WriteHTML =~ s/<\/body>//gi;
$WriteHTML =~ s/<\/html>/$RenderTime/gi;
print $WriteHTML;

exit;

}

#--------------------------------------------------------------------------------------------------------------

sub load_system_variables {
$sql_statement = "SELECT * FROM system_variables WHERE VarGroup > '90';";
$sth = $dbh->query($sql_statement);
while (@arr = $sth->fetchrow) {
  ($SysId, $VarGroup, $VarName, $VarMax, $VarMin, $VarText) = @arr;
  if ($VarName eq "AdminTestMode") { $TestMode = $VarMax; }
  if ($VarName eq "AdminDebugMode") { $DebugMode = $VarMax; }
  if ($VarName eq "CurrencyMark") { $CurrencyMark = $VarMax; }
  if ($VarName eq "FixedDelCharge") { $FixedDelCharge = $VarMax; }
  if ($VarName eq "VatRate") { $VatRate = $VarMax; }
  if ($VarName eq "DefAdminOffset") { $DefProdOffset = $VarMax; }
  if ($VarName eq "SupportMail") { $SupportMail = $VarText; }
  if ($VarName eq "ServiceMail") { $ServiceMail = $VarText; }
  if ($VarName eq "InfoMail") { $InfoMail = $VarText; }
  if ($VarName eq "SalesMail") { $SalesMail = $VarText; }
  if ($VarName eq "MailSender") { $MailSender = $VarText; }
  if ($VarName eq "DefSessionTime") { $DefSessionTime = $VarMax; }
}
  $sql_statement = "SELECT VarText FROM system_variables WHERE VarGroup = '99';";
  $sth = $dbh->query($sql_statement);
  @arr = $sth->fetchrow;
	$VarText = @arr[0];
	($CsImage,$CsName,$CsVatNum,$CsRegNum,$CsPostal,$CsPhysical,$CsTele,$CsFax,$CsEmail,$CsUrl,$CsUrlEx,$CsBank,$CsSlogan) = split(/\|/,$VarText);
}

sub convert_timestamp {
    local($e) = @_;
    ($tsec,$tmin,$thour,$tmday,$tmon,$tyear,$twday,$tyday,$tisdst) = gmtime($e);
    $tyear = $tyear + 1900;
    $tmon++;
    if ($tmon < 10) { $tmon = "0".$tmon; }
    if ($tmday < 10) { $tmday = "0".$tmday; }
    if ($tsec < 10) { $tsec = "0".$tsec; }
    if ($tmin < 10) { $tmin = "0".$tmin; }
    if ($thour < 10) { $thour = "0".$thour; }
    $ConvTimeStamp = "$tyear-$tmon-$tmday $thour:$tmin";
    $ConvTimeDate = "$tyear-$tmon-$tmday";
}
sub convert_date_format {
    local($e) = @_;
    ($tsec,$tmin,$thour,$tmday,$tmon,$tyear,$twday,$tyday,$tisdst) = gmtime($e);
    $tyear = $tyear + 1900;
    $tmon++;
    if ($tmon < 10) { $tmon = "0".$tmon; }
    if ($tmday < 10) { $tmday = "0".$tmday; }
    if ($tsec < 10) { $tsec = "0".$tsec; }
    if ($tmin < 10) { $tmin = "0".$tmin; }
    if ($thour < 10) { $thour = "0".$thour; }
    $ConvDate = "$tyear-$tmon-$tmday $thour:$tmin:$tsec";
    $ConvDateShort = "$tyear-$tmon-$tmday";
}
sub system_error {
  print "content-type: text/html\n\n";
	local($e) = @_;
	open (OUTPHILE, ">>$error_log") || print "System Error! :";
	&lock(OUTPHILE);
	print OUTPHILE $the_date."|".$current_user."|".$uid."|".$e."|".$user_agent."|``\n";
	&unlock(OUTPHILE);
	close(OUTPHILE);		
	print "System Error: ".$e."\n";
	exit;
}
sub shorten_text_string {
  $TestWords = "";
  $ShortString = "";
  @stringwords = ();
  local($e) = @_;
  ($TestString,$StringLength) = split(/\|/,$e);
  @stringwords = split(/\ /,$TestString);
  $StringLength++;
  foreach $NextWord(@stringwords) {
    $TestWords = $TestWords." ".$NextWord;
    if (length($TestWords) < $StringLength) { $ShortString = $ShortString." ".$NextWord; }
  }
  $ShortString =~ s/^\s+//;
  $ShortString =~ s/\s+$//;
  
}
sub check_dbase_error {
	$errmsg = $dbh->errmsg();
	if ($errmsg ne "") {
		$error_number = $dbh->errno;
		if ($DebugMode eq "Y") { &system_error("Fatal - $error_number: $errmsg [$sql_statement]"); }
    else { &system_error("Fatal - $error_number: $errmsg [$sql_statement]"); }
	}
}

sub page_error {
	local($e) = @_;
	$getdoc = $docroot."home\.tmpl";
	open (INPHILE, "<$getdoc");
}
#--------------------------------------------------------------------------------------------------------------

sub lookup_country_codes {
    $sql_statement = "SELECT CountryCode,CountryName FROM countrycodes ORDER BY CountryName;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
	$LCountryCode = @arr[0];
	$LCountryName = @arr[1];
	if ($CountryCode eq $LCountryCode) { $CountryListing = $CountryListing."<option value=\"".$LCountryCode."\" selected>".$LCountryName."</option>\n"; $CountryName = $LCountryName; }
	else { $CountryListing = $CountryListing."<option value=\"".$LCountryCode."\">".$LCountryName."</option>\n"; }
    }    
}
#--------------------------------------------------------------------------------------------------------------
sub lock {
  local($file)=@_;
  #flock($file, $LOCK_EX);
}

#---------------------------------------------------------------------------------------------------------------------------
sub unlock {
  local($file)=@_;
  #flock($file, $LOCK_UN);
}
#--------------------------------------------------------------------------------------------------------------


#--------------------------------------------------------------------------------------------------------------
sub set_counter_lockfile {
    
    $lockfile = $temproot."count.lock";
    local ($endtime);                                   
    $endtime = 60;                                      
    $endtime = time + $endtime;                         
    while (-e $lockfile && time < $endtime) {
        $Do_Nothing = 1;                                  
    }                
    if (time >= $endtime) { &error_handler("Counter Busy [File Lock]"); }
    else { open(LOCK_FILE, ">$lockfile"); }
}


sub drop_counter_lockfile {
  close(LOCK_FILE);
  unlink($lockfile);
}

#--------------------------------------------------------------------------------------------------------------
sub error_handler {
    local($e) = @_;
    print "Content-type: text/html\n\n";
    $ErrMsg = "Critical Error: $e";
    print $ErrMsg;
    #$page = "critical_error";
    #&display_page_requested;
    exit;
}

#--------------------------------------------------------------------------------------------------------------

sub resolve_host_name {

$HitIP = $ENV{REMOTE_ADDR};
use Net::hostent;
use Socket;
@ARGV = ($HitIP) unless @ARGV;
for $host ( @ARGV ) {
    unless ($h = gethost($host)) {
       warn "$0: no such host: $host";
       next;
    }
    push (@names, $h->name);
 }

foreach $name(@names) {
	$HitHost = $name;
}
$TrackedUser = $HitHost."[".$HitIP."]";
}