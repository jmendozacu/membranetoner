#!/usr/bin/perl

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
$tst = $info{'test'};

$uid = $info{'uid'};
$func = $info{'fn'};
$page = $info{'pg'};
$step = $info{'st'};
$InvoiceNumber = $info{'inv'};
$BuyerId = $info{'byd'};

use CGI;
$query = new CGI;
$LastView = $query->cookie('tonLastView');
$query = new CGI;
$SessionCid = $query->cookie('tonSessionCid');
$query = new CGI;
$FirstVisit = $query->cookie('tonFirstVisit');
$query = new CGI;
$RemString = $query->cookie('tonRemString');
$query = new CGI;
$uid = $query->cookie('tonUniqueId');
$query = new CGI;
$LastSearchTerm = $query->cookie('tonLastSearch');
$query = new CGI;
$ClearSession = $query->cookie('tonClearSession');

push(@debugstring,"R COOKIE: tonLastView||$LastView");
push(@debugstring,"R COOKIE: tonSessionCid||$SessionCid");
push(@debugstring,"R COOKIE: tonFirstVisit||$FirstVisit");
push(@debugstring,"R COOKIE: tonRemString||$RemString");
push(@debugstring,"R COOKIE: tonUniqueId||$uid");
push(@debugstring,"R COOKIE: tonLastSearch||$LastSearchTerm");
push(@debugstring,"R COOKIE: tonClearSession||$ClearSession");

#--------------------------------------------------------------------------------------------------------------
#print "Content-type: text/html\n\n";

if ($func eq "print") { &fetch_print_page; }
else { &fetch_login_page; }
exit;

#==============================================================================================================

sub fetch_print_page {
  $sql_statement = "SELECT * FROM order_main WHERE BuyerId = '$BuyerId' AND SessionId = '$uid' AND InvoiceNum = '$InvoiceNumber';";
  #print "$sql_statement<br>\n";
  $sth = $dbh->query($sql_statement);
  @arr = $sth->fetchrow;
  ($OrderId, $OrderStat, $PayOption, $XBuyerId, $SessionId, $XTimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $XOrderWeight, $OptionDel, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;

	#($OrderId, $OrderStat, $PayOption, $XBuyerId, $SessionId, $TimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderTotal, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId) = @arr;

  if ($PayOption eq "CC") { $page = "invoice_full"; } else { $page = "invoice_proforma"; }

  if ($OrderTotal < 1) { $uid = ""; &fetch_login_page; }
  else {
	&convert_timestamp($XTimeStamp);
	$InvoiceDate = $ConvTimeStamp;
	$sql_statement = "SELECT SafePayRefNr,BankRefNr,BuyerCreditCardNr FROM safe_shop WHERE TransactId = '$TransactId';";
	$sth = $dbh->query($sql_statement);
	@arr = $sth->fetchrow;
	($SafePayRefNr, $BankRefNr, $BuyerCreditCardNr) = @arr;
	$sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId';";
	$sth = $dbh->query($sql_statement);
	@arr = $sth->fetchrow;
	($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $SurName, $DateOfBirth, $TelAreaCode, $Telephone, $FaxAreaCode, $FaxNum, $IdNumber, $Company, $VatNumber, $PostProvince, $PostalOne, $PostalTwo, $PostalThree, $PostTown, $BillCode, $PostCountry, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DelDayFrom, $DelDayTo, $VoucherCode) = @arr;

	#($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $Surname, $DateOfBirth, $TelAreaCode, $Telephone, $FaxAreaCode, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostalCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DelDayFrom, $DelDayTo, $VoucherCode) = @arr;

	$sql_statement = "SELECT * FROM order_items WHERE OrderId = '$OrderId';";
	$sth = $dbh->query($sql_statement);
	while (@arr = $sth->fetchrow) {
	  ($ItemId, $BuyerId, $OrderId, $TimeStamp, $Level1, $Level2, $Level3, $ProdId, $OrderCode, $ProdName, $OrderQty, $OrderPrice, $OrderWeight, $DelCharge, $ItemFlag) = @arr;
	  $ItemTotal = $OrderPrice * $OrderQty;
	  $ItemTotal = sprintf("%.2f",$ItemTotal);
	  $InvoiceString = $InvoiceString."<tr>\n <td class=\"dotborderlg\">&nbsp;$OrderCode</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\">&nbsp;$ProdName</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" align=\"center\">$OrderQty</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" align=\"right\">$OrderPrice&nbsp;</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlgsh\" align=\"right\">$ItemTotal&nbsp;</td>\n</tr>\n";
	}
  }
	
	$sql_statement = "SELECT OptionName,DeliverTime,DeliverMax FROM deliver_options WHERE DelId = '$OptionDel';";
  $sth = $dbh->query($sql_statement);
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
  &display_page_requested;
}

#--------------------------------------------------------------------------------------------------------------

sub fetch_login_page {
  $page = "static_home";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------

sub display_page_requested {

$getpage = $docroot.$page."\.html";

print "Content-type: text/html\n\n";
#print "<!--GP:$getpage-->\n";
#print "<!--$globe_x:$globe_y:$ImagePath-->\n";
#print "<!--TS:$TestString-->\n";
print "<!-- Powered by W3b.co.za -->\n\n";

if ($AlertPrompt ne "") { $AlertPrompt = "\nwindow.alert(\"".$AlertPrompt."\");"; }
if ($SetFocus ne "") { $SetFocus = "\ndocument.".$FormName.".".$SetFocus.".select();\ndocument.".$FormName.".".$SetFocus.".focus();"; }

open (INPHILE, "<$getpage");
@indata=<INPHILE>;
close(INPHILE);

foreach $line(@indata) {

    $line =~ s/_PAGE_TITLE_/$PageTitle/g;
    $line =~ s/_ALERT_PROMPT_/$AlertPrompt/g;
    $line =~ s/_SET_FOCUS_/$SetFocus/g;
	$line =~ s/_UID_/$uid/g;
	$line =~ s/_CMARK_/$CurrencyMark/g;
		
    $line =~ s/_BASKET_LISTING_/$BasketListing/g;
    $line =~ s/_SBTT_/$OrderSub/g;
    $line =~ s/_VBTT_/$OrderVat/g;
    $line =~ s/_DCTT_/$OrderDel/g;
    $line =~ s/_ABTT_/$OrderTotal/g;
    $line =~ s/_ABTTX_/$BasketShopTotal/g;
		$line =~ s/_ICTT_/$BasketCount/g;
		$line =~ s/_INSCT_/$OrderInsure/g;

		$line =~ s/_DELWEIGHT_/$XOrderWeight/g;
		$line =~ s/_OPTIONNAME_/$OptionName/g;
		$line =~ s/_DELIVERTIME_/$DeliverTime/g;


    $line =~ s/_EMAIL_/$MailAddy/g;
    $line =~ s/_CTITLE_/$Title/g;
    $line =~ s/_FNAME_/$FirstName/g;
    $line =~ s/_SNAME_/$Surname/g;
    $line =~ s/_TAREA_/$TelAreaCode/g;
    $line =~ s/_TELEPHONE_/$Telephone/g;
    $line =~ s/_FAREA_/$FaxArea/g;
    $line =~ s/_FAX_/$FaxNum/g;
    $line =~ s/_COMPANY_/$Company/g;
    $line =~ s/_IDNUMBER_/$IdNumber/g;
    $line =~ s/_VATNUMBER_/$VatNumber/g;
    $line =~ s/_ESTDELIVER_/$EstDeliver/g;

    $line =~ s/_POSTAL_1_/$PostalOne/g;
    $line =~ s/_POSTAL_2_/$PostalTwo/g;
    $line =~ s/_POSTAL_3_/$PostalThree/g;
    $line =~ s/_BILLCODE_/$BillCode/g;
    $line =~ s/_POSTTOWN_/$PostTown/g;
    $line =~ s/_POSTPROVINCE_/$PostProvince/g;


    $line =~ s/_DELIVERY_1_/$DeliveryOne/g;
    $line =~ s/_DELIVERY_2_/$DeliveryTwo/g;
    $line =~ s/_DELIVERY_3_/$DeliveryThree/g;
    $line =~ s/_CITYTOWN_/$CityTown/g;
    $line =~ s/_PROVINCE_/$Province/g;
    $line =~ s/_POSTCODE_/$PostCode/g;
    $line =~ s/_COUNTRY_/$Country/g;
    $line =~ s/_DELIVER_FROM_/$DeliverFrom/g;
    $line =~ s/_DELIVER_TO_/$DeliverTo/g;
    $line =~ s/_DELIVER_NOTES_/$DeliverNote/g;
    $line =~ s/_DELDAY_FROM_/$DeldayFrom/g;
    $line =~ s/_DELDAY_TO_/$DeldayTo/g;
    $line =~ s/_PRFNUM_/$InvoiceNumber/g;
		$line =~ s/_VOUCHER_CODE_/$VoucherCode/g;

  $line =~ s/_PRFNUM_/$InvoiceNumber/g;
  $line =~ s/_INVDATE_/$InvoiceDate/g;
  $line =~ s/_INVOICE_STRING_/$InvoiceString/g;
  $line =~ s/_DATEBIRTH_/$DateOfBirth/g;
  $line =~ s/_TRANSACTID_/$TransactId/g;
  $line =~ s/_LOGREFNR_/$LogRefNr/g;
  $line =~ s/_MERCHANTREFERENCE_/$MerchantReference/g;
  $line =~ s/_RECEIPTURL_/$ReceiptURL/g;
  $line =~ s/_TRANSACTIONAMOUNT_/$TransactionAmount/g;
  $line =~ s/_TRANSACTIONTYPE_/$TransactionType/g;
  $line =~ s/_TRANSACTIONRESULT_/$TransactionResult/g;
  $line =~ s/_TRANSACTIONERRORRESPONSE_/$TransactionErrorResponse/g;
  $line =~ s/_SAFEPAYREFNR_/$SafePayRefNr/g;
  $line =~ s/_BANKREFNR_/$BankRefNr/g;
  $line =~ s/_LIVETRANSACTION_/$LiveTransaction/g;
  $line =~ s/_SAFETRACK_/$SafeTrack/g;
  $line =~ s/_BUYERCREDITCARDNR_/$BuyerCreditCardNr/g;

  $line =~ s/_CS_LOGO_/$CsImage/g;
  $line =~ s/_CS_NAME_/$CsName/g;
  $line =~ s/_CS_VATNUM_/$CsVatNum/g;
  $line =~ s/_CS_REGNUM_/$CsRegNum/g;
  $line =~ s/_CS_POSTAL_/$CsPostal/g;
  $line =~ s/_CS_PHYSIC_/$CsPhysical/g;
  $line =~ s/_CS_TELE_/$CsTele/g;
  $line =~ s/_CS_FAXN_/$CsFax/g;
  $line =~ s/_CS_MAIL_/$CsEmail/g;
  $line =~ s/_CS_URL_/$CsUrl/g;
  $line =~ s/_CS_URLEX_/$CsUrlEx/g;
  $line =~ s/_CS_BANK_/$CsBank/g;
  $line =~ s/_CS_SLOGAN_/$CsSlogan/g;

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
	$uid = $uid.$rval;
	$uid =~ tr/A-Za-z0-9/ /cs;
	$uid =~ s/ //g;
	if (length($uid) > 10) { return; }
}
}

#--------------------------------------------------------------------------------------------------------------
#error handlers
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

sub convert_timestamp {
    local($e) = @_;
    if ($e eq "") { $ConvTimeStamp = "N/A"; return; }
    ($tsec,$tmin,$thour,$tmday,$tmon,$tyear,$twday,$tyday,$tisdst) = gmtime($e);
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

sub page_error {
	local($e) = @_;
	$getdoc = $docroot."home\.tmpl";
	open (INPHILE, "<$getdoc");
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
$TrackedUser = $HitHost." [".$HitIP."]";
}


