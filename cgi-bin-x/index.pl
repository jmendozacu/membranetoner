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

$uid = $info{'uid'};
$func = $info{'fn'};
$subf = $info{'subf'};
$page = $info{'pg'};
$step = $info{'st'};
$CLevel1 = $info{'mct'};
$CLevel2 = $info{'sct'};
$CLevel3 = $info{'pct'};
$OffSet = $info{'fs'};
$ProdId = $info{'pid'};
$BrandId = $info{'br'};
$BasketId = $info{'bid'};
$FormTime = $form{'FormTime'};
$BuyerId = $form{'BuyerId'};
$UidClear = $info{'uc'};

if ($func ne "force") {
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
}
else {
  $SessionCid = $info{'sci'};
  push(@writecookie,"tonSessionCid|$SessionCid");
  push(@writecookie,"tonUniqueId|$uid");
  $ResId = $info{'rid'};
  $OrderId = $info{'oi'};
}
if ($OffSet eq "") { $OffSet = "0"; }

#--------------------------------------------------------------------------------------------------------------
#-Check for valid UID

if (($UidClear eq "1") && ($func ne "checkout")) {
  $sql_statement = "UPDATE shopping_basket SET StatFlag = '0' WHERE SessionId = '$uid';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  $UidClear = "";
}
if (($UidClear eq "2") && ($func ne "checkout")) {
  $sql_statement = "UPDATE shopping_basket SET StatFlag = '0' WHERE SessionId = '$uid';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  $uid = "";
  $UidClear = "";
}

if ($uid eq "") {
	&generate_random_string;
	$pref = time;
	$uid = $uid.$pref;
	$sql_statement = "INSERT INTO user_session VALUES ('','".$uid."','".$userid."','".$pref."','0');";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  push(@writecookie,"tonUniqueId|$uid");

}
#else {
#  $CheckTime = time;
#  $CheckTime = $CheckTime - 56600;
#  $sql_statement = "SELECT ExpireTime FROM user_session WHERE SessionId = '$uid';";
#  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
#  @arr = $sth->fetchrow;
#  $SessionTime = @arr[0];
#  if ($SessionTime < $CheckTime) {
#  $OldUId = $uid;
#  $uid = "";
#	&generate_random_string;
#	$pref = time;
#	$uid = $uid.$pref;
#	$sql_statement = "INSERT INTO user_session VALUES ('','".$uid."','".$userid."','".$pref."','0');";
#	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||x $sql_statement"); &check_dbase_error;
#	$TestString = "Old: $OldUId | New UID: $uid | $SessionTime";
#    }
#}

#--------------------------------------------------------------------------------------------------------------
#-Currency Convertor
	



#--------------------------------------------------------------------------------------------------------------
#-Function Calls

if ($func eq "home") { &fetch_home_page; }
elsif ($func eq "about") { &fetch_about_page; }
elsif ($func eq "contact") { &fetch_contact_page; }
elsif ($func eq "jobs") { &fetch_vacancy_page; }
elsif ($func eq "service") { &fetch_service_page; }
elsif ($func eq "support") { &fetch_support_page; }
elsif ($func eq "partners") { &fetch_partner_page; }
elsif ($func eq "legal") { &fetch_legal_page; }
elsif ($func eq "faq") { &fetch_faq_page; }
#---
elsif ($func eq "links") { &fetch_links_page; }
elsif ($func eq "basket") { &fetch_basket_page; }
elsif ($func eq "checkout") { &fetch_checkout_page; }
elsif ($func eq "force") { &fetch_checkout_page; }
elsif ($func eq "order") { &fetch_order_page; }
elsif ($func eq "bform") { &fetch_forms_page; }
elsif ($func eq "remind") { &fetch_password_reminder; }
elsif ($func eq "spbrand") { &fetch_brand_page; }
elsif ($func eq "spsearch") { &fetch_search_page; }
elsif ($func eq "special") { &fetch_specials_page; }
elsif ($func eq "spmain") { &fetch_product_page; }
elsif ($func eq "newsletter") { &fetch_newsletter_page; }
elsif ($func eq "cview") { &fetch_category_page; }
elsif ($func eq "buy") { &quick_buy_redirect; }
elsif ($func eq "resell") { &manage_reseller_account; }
elsif ($func eq "affiliate") { &manage_affiliate_account; }

else { &fetch_home_page; }
exit;

#==============================================================================================================
sub manage_affiliate_account {
  &parse_reseller_form;
  if ($step eq "remind") {
    $page = "reseller_reminder";
    $PageTitle = "Reseller/Affiliate Account Password Reminder";
  }    
  elsif ($step eq "remsend") {
    $sql_statement = "SELECT PassWord,ActiveCode,FirstName FROM reseller_details WHERE EmailAddress LIKE '$EmailAddress';";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($PassWord,$ActiveCode,$FirstName) = @arr;
    if ($PassWord ne "") {
      $AlertPrompt = "An email containing your username & password has been sent to your email address!"; 
      &send_reseller_reminder;
      $page = "reseller_login";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
    }
    else {
      $AlertPrompt = "The email address you supplied does not match any Reseller account! Please try again..."; 
      $page = "reseller_reminder";
      $PageTitle = "Reseller/Affiliate Account Password Reminder";
    }
  }    
  elsif ($step eq "login") {
    $sql_statement = "SELECT ResId,StatFlag,FirstName FROM reseller_details WHERE EmailAddress = '$EmailAddress' AND PassWord = '$PassWord';";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($ResId,$StatFlag,$FirstName) = @arr;
    
    if ($ResId eq "") {
      $page = "reseller_login";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
      $AlertPrompt = "The username and/or password you entered are incorrect! Please try again...";
    }
    elsif ($StatFlag eq "1") {
      $page = "reseller_validate";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
      $AlertPrompt = "Your Reseller account has not been activated yet! Please check your email for instructions...";
    }
    elsif ($StatFlag eq "2") {
      $page = "reseller_login";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
      $AlertPrompt = "Your Reseller account has not been approved as yet! Please contact our support dept. to query the status of your application";
    }
    elsif ($StatFlag eq "0") {
      $page = "reseller_login";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
      $AlertPrompt = "Your Reseller account has been suspended! Please contact our support dept.";
    }
    else {
      &generate_session_code;
      push(@writecookie,"tonSessionCid|$SessionCid");
      
      $sql_statement = "DELETE FROM reseller_session WHERE UserId = '$ResId';";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $ExpireTime = $TimeStamp + $DefSessionTime;
      $sql_statement = "INSERT INTO reseller_session VALUES ('','$SessionCid','$ResId','$ExpireTime','0','$current_user');";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $sql_statement = "INSERT INTO reseller_history VALUES ('','1','$TimeStamp','$ResId','$current_user','1000','Login Successful');";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;

      #print "Location: ../cgi-bin/reseller.pl?fn=home&ri=$ResId\nURI: ../cgi-bin/reseller.pl?fn=home&ri=$ResId\n\n" ; 
      #exit; 
      $page = "reseller_jump";
      $PageTitle = "Reseller Login";
      &display_page_requested;
    }
  }    
  elsif ($step eq "lgform") {
    $page = "reseller_login";
    $PageTitle = "Reseller/Affiliate Account Login";
  }    
  elsif ($step eq "remind") {
    $page = "reseller_reminder";
    $PageTitle = "Reseller/Affiliate Account Password Reminder";
  }    
  elsif ($step eq "resend") {
    $AffId = $info{'ai'};
    $sql_statement = "SELECT EmailAddress,PassWord,ActiveCode FROM affiliate_details WHERE AffId = '$AffId' AND SessionId = '$uid';";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($EmailAddress,$PassWord,$ActiveCode) = @arr;
    if ($EmailAddress ne "") { &send_affiliate_welcome; }
    $page = "affiliate_validate";
    $PageTitle = "Validate your Toner.co.za Affiliate Application";
    $StatusMessage = "0|The email containing your activation code was re-sent to your email address. Please check your email shortly!";
  }
  elsif ($step eq "valid") {
    $AffId = $info{'ai'};
    $sql_statement = "SELECT * FROM affiliate_details WHERE AffId = '$AffId' AND EmailAddress LIKE '$EmailAddress' ORDER BY AffId DESC LIMIT 0,1;";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($XAffId, $StatFlag, $SignDate, $CompanyName, $Title, $FirstName, $SurName, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $XPassWord, $XActiveCode, $SessionId, $CommissionRate, $SiteDescript) = @arr;
    
    if (($EmailAddress !~ /.+\@.+\..+/) || (length($PassWord) < 5) || ($ActiveCode ne $XActiveCode) || ($PassWord ne $XPassWord)) {
      $StatusMessage = "2|The login details and/or Activation Code you supplied are inccorrect! Please try again!";
      $page = "affiliate_validate";
      $PageTitle = "Toner.co.za Affiliate Application";
    }
    else {
      &send_affiliate_alert;
      $sql_statement = "UPDATE affiliate_details SET StatFlag = '2' WHERE AffId = '$AffId';";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $page = "affiliate_complete";
      $PageTitle = "Toner.co.za Affiliate Application - Complete";
    }
  }
  elsif ($step eq "new") {
    if ($EmailAddress !~ /.+\@.+\..+/) { 
      $AlertPrompt = "Please enter a valid email address!";
      $page = "affiliate_apply";
      $PageTitle = "Become a Toner.co.za Affiliate";
    }
    elsif (index($EmailAddress,"content-transfer-encoding") > -1) { 
      $AlertPrompt = "Your IP address has been logged for security purposes! Please refrain from attempting to send spam through our server";
      $page = "affiliate_apply";
      $PageTitle = "Become a Toner.co.za Affiliate";
    }
    elsif ((length($CompanyName) < 2) || (length($FirstName) < 2) || (length($SurName) < 2) || (length($Telephone) < 2) || (length($PostalAddress) < 2) || (length($PassWord) < 2)) {
      $AlertPrompt = "Please enter valid contact information!";
      $page = "affiliate_apply";
      $PageTitle = "Become a Toner.co.za Affiliate";
    }
    else {
      ($EmailAddress,$junk) = split(/\n/,$EmailAddress);
      $EmailAddress =~ tr/a-zA-Z0-9\.\-\@\_/ /cs;
      $EmailAddress =~ s/ //gi;
      
      $sql_statement = "SELECT AffId FROM affiliate_details WHERE EmailAddress LIKE '$EmailAddress' AND SessionId = '$uid';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      $AffId = @arr[0];
      push(@debugstring,"IDCHECK||$AffId");
      if ($AffId eq "") {
        &generate_activate_code;
        $sql_statement = "INSERT INTO affiliate_details VALUES ('','1','$TimeStamp','$CompanyName','$Title','$FirstName','$SurName','$EmailAddress','$TelArea','$Telephone','$FaxArea','$FaxNum','$PostalAddress','$CityTown','$Province','$Country','$WebURL','$PassWord','$ActiveCode','$uid','0.00','$SiteDescript');";
        push(@debugstring,"SQL||$sql_statement");
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        sleep(1);
        $sql_statement = "SELECT AffId FROM affiliate_details WHERE EmailAddress LIKE '$EmailAddress' AND SessionId = '$uid';";
        push(@debugstring,"SQL||$sql_statement");
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        @arr = $sth->fetchrow;
        $AffId = @arr[0];
        &send_affiliate_welcome;
      }
      $page = "affiliate_validate";
      $PageTitle = "Validate your Toner.co.za Affiliate Application";
    }
  }
  else {
    $page = "affiliate_apply";
    $PageTitle = "Become a Toner.co.za Affiliate";
  }
  &display_page_requested;
}

sub manage_reseller_account {
  &parse_reseller_form;
  if ($step eq "remind") {
    $page = "reseller_reminder";
    $PageTitle = "Reseller/Affiliate Account Password Reminder";
  }    
  elsif ($step eq "remsend") {
    $sql_statement = "SELECT PassWord,ActiveCode,FirstName FROM reseller_details WHERE EmailAddress LIKE '$EmailAddress';";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($PassWord,$ActiveCode,$FirstName) = @arr;
    if ($PassWord ne "") {
      $AlertPrompt = "An email containing your username & password has been sent to your email address!"; 
      &send_reseller_reminder;
      $page = "reseller_login";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
    }
    else {
      $AlertPrompt = "The email address you supplied does not match any Reseller account! Please try again..."; 
      $page = "reseller_reminder";
      $PageTitle = "Reseller/Affiliate Account Password Reminder";
    }
  }    
  elsif ($step eq "login") {
    $sql_statement = "SELECT ResId,StatFlag,FirstName FROM reseller_details WHERE EmailAddress = '$EmailAddress' AND PassWord = '$PassWord';";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($ResId,$StatFlag,$FirstName) = @arr;
    
    if ($ResId eq "") {
      $page = "reseller_login";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
      $AlertPrompt = "The username and/or password you entered are incorrect! Please try again...";
    }
    elsif ($StatFlag eq "1") {
      $page = "reseller_validate";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
      $AlertPrompt = "Your Reseller account has not been activated yet! Please check your email for instructions...";
    }
    elsif ($StatFlag eq "2") {
      $page = "reseller_login";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
      $AlertPrompt = "Your Reseller account has not been approved as yet! Please contact our support dept. to query the status of your application";
    }
    elsif ($StatFlag eq "0") {
      $page = "reseller_login";
      $PageTitle = "Login to your Toner.co.za Reseller/Affiliate Account";
      $AlertPrompt = "Your Reseller account has been suspended! Please contact our support dept.";
    }
    else {
      &generate_session_code;
      push(@writecookie,"tonSessionCid|$SessionCid");
      
      $sql_statement = "DELETE FROM reseller_session WHERE UserId = '$ResId';";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $ExpireTime = $TimeStamp + $DefSessionTime;
      $sql_statement = "INSERT INTO reseller_session VALUES ('','$SessionCid','$ResId','$ExpireTime','0','$current_user');";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $sql_statement = "INSERT INTO reseller_history VALUES ('','1','$TimeStamp','$ResId','$current_user','1000','Login Successful');";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;

      #print "Location: ../cgi-bin/reseller.pl?fn=home&ri=$ResId\nURI: ../cgi-bin/reseller.pl?fn=home&ri=$ResId\n\n" ; 
      #exit; 
      $page = "reseller_jump";
      $PageTitle = "Reseller Login";
      &display_page_requested;
    }
  }    
  elsif ($step eq "lgform") {
    $page = "reseller_login";
    $PageTitle = "Reseller/Affiliate Account Login";
  }    
  elsif ($step eq "remind") {
    $page = "reseller_reminder";
    $PageTitle = "Reseller/Affiliate Account Password Reminder";
  }    
  elsif ($step eq "resend") {
    $ResId = $info{'ri'};
    $sql_statement = "SELECT EmailAddress,PassWord,ActiveCode FROM reseller_details WHERE ResId = '$ResId' AND SessionId = '$uid';";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($EmailAddress,$PassWord,$ActiveCode) = @arr;
    if ($EmailAddress ne "") { &send_reseller_welcome; }
    $page = "reseller_validate";
    $PageTitle = "Validate your Toner.co.za Reseller Application";
    $AlertPrompt = "The email containing your activation code was re-sent to your email address. Please check your email shortly!";
  }
  elsif ($step eq "valid") {
    $ResId = $info{'ri'};
    $sql_statement = "SELECT * FROM reseller_details WHERE ResId = '$ResId' AND EmailAddress LIKE '$EmailAddress' ORDER BY ResId DESC LIMIT 0,1;";
    push(@debugstring,"SQL||$sql_statement");
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($XResId, $StatFlag, $SignDate, $CompanyName, $CompanyReg, $VatNumber, $Title, $FirstName, $SurName, $IdNumber, $EmailAddress, $TelArea, $Telephone, $FaxArea, $FaxNum, $Mobile, $PhysicalAddress, $PostalAddress, $CityTown, $Province, $Country, $WebURL, $XPassWord, $XActiveCode, $SessionId, $DiscountRate, $BusinessDescript) = @arr;
    
    if (($EmailAddress !~ /.+\@.+\..+/) || (length($PassWord) < 5) || ($ActiveCode ne $XActiveCode) || ($PassWord ne $XPassWord)) {
      $AlertPrompt = "The login details and/or Activation Code you supplied are inccorrect! Please try again!";
      $page = "reseller_validate";
      $PageTitle = "Toner.co.za Reseller Application - Complete";
    }
    else {
      &send_reseller_alert;
      $sql_statement = "UPDATE reseller_details SET StatFlag = '2' WHERE ResId = '$ResId';";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $page = "reseller_complete";
      $PageTitle = "Toner.co.za Reseller Application - Complete";
    }
  }
  elsif ($step eq "new") {
    if ($EmailAddress !~ /.+\@.+\..+/) { 
      $StatusMessage = "1|Please enter a valid email address!";
      $page = "reseller_apply";
      $PageTitle = "Become a Toner.co.za Reseller";
    }
    elsif (index($EmailAddress,"content-transfer-encoding") > -1) { 
      $AlertPrompt = "Your IP address has been logged for security purposes! Please refrain from attempting to send spam through our server";
      $page = "reseller_apply";
      $PageTitle = "Become a Toner.co.za Reseller";
    }
    elsif ((length($CompanyName) < 2) || (length($FirstName) < 2) || (length($SurName) < 2) || (length($Telephone) < 2) || (length($PostalAddress) < 2) || (length($PassWord) < 2)) {
      $AlertPrompt = "Please enter valid contact information!";
      $page = "reseller_apply";
      $PageTitle = "Become a Toner.co.za Reseller";
    }
    else {
      ($EmailAddress,$junk) = split(/\n/,$EmailAddress);
      $EmailAddress =~ tr/a-zA-Z0-9\.\-\@\_/ /cs;
      $EmailAddress =~ s/ //gi;
      $sql_statement = "SELECT ResId FROM reseller_details WHERE EmailAddress LIKE '$EmailAddress' AND SessionId = '$uid';";
      push(@debugstring,"SQL||$sql_statement");
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      $ResId = @arr[0];
      if ($ResId eq "") {
        &generate_activate_code;
        $sql_statement = "INSERT INTO reseller_details VALUES ('','1','$TimeStamp','$CompanyName','$CompanyReg','$VatNumber','$Title','$FirstName','$SurName','$IdNumber','$EmailAddress','$TelArea','$Telephone','$FaxArea','$FaxNum','$Mobile','$PhysicalAddress','$PostalAddress','$CityTown','$Province','$Country','$WebURL','$PassWord','$ActiveCode','$uid','0.00','0','','$BusinessDescript');";
        push(@debugstring,"SQL||$sql_statement");
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        sleep(1);
        $sql_statement = "SELECT ResId FROM reseller_details WHERE EmailAddress LIKE '$EmailAddress' AND SessionId = '$uid';";
        push(@debugstring,"SQL||$sql_statement");
        $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
        @arr = $sth->fetchrow;
        $ResId = @arr[0];
        &send_reseller_welcome;
      }
      $page = "reseller_validate";
      $PageTitle = "Validate your Toner.co.za Reseller Application";
    }
  }
  else {
    $page = "reseller_apply";
    $PageTitle = "Become a Toner.co.za Reseller";
  }
  &display_page_requested;
}

sub generate_activate_code {
  for ($a=0; $a <= 2500; $a++) {
  	$rval = rand(9);
  	$rval = sprintf("%.0f", $rval);
  	$ActiveCode = $ActiveCode.$rval;
    $ActiveCode =~ tr/A-Za-z0-9/ /cs;
  	$ActiveCode =~ s/ //g;
  	if (length($ActiveCode) > 7) { return; }
  }
}
sub generate_session_code {
  for ($a=0; $a <= 2500; $a++) {
    $rval = rand(74);
    $rval = $rval + 48;
    $rval = sprintf("%.0f", $rval);
    $rval = chr($rval);
    $SessionCid = $SessionCid.$rval;
    $SessionCid =~ tr/A-Za-z0-9/ /cs;
    $SessionCid =~ s/A//gi;
    $SessionCid =~ s/E//gi;
    $SessionCid =~ s/I//gi;
    $SessionCid =~ s/O//gi;
    $SessionCid =~ s/U//gi;
    $SessionCid =~ s/ //g;
    if (length($SessionCid) > 16) { return; }
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
  $ActiveCode = $form{'ActiveCode'};
  $BusinessDescript = $form{'BusinessDescript'};
  $SiteDescript = $form{'SiteDescript'};
  $PostalAddress =~ s/\cM//g;
  $SiteDescript =~ s/\cM//g;
  $BusinessDescript =~ s/\cM//g;
  
  $EmailAddress =~ tr/A-Z/a-z/;
  $WebURL =~ s/http:\/\///gi;

}

#-------

sub quick_buy_redirect {
  $ProdId = $info{'pid'};
  $sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId' LIMIT 0,1;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($ProdId, $OrderCode, $BrandId, $CLevel1, $CLevel2, $CLevel3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize) = @arr;
  
  $LinkURL = "http://www.toner.co.za/cgi-bin/index.pl?fn=basket&br=$BrandId&mct=$CLevel1&sct=$CLevel2&pct=0&st=add&pid=$ProdId&rt=pd&fs=0";

  print "Location: ".$LinkURL."\nURI: ".$LinkURL."\n\n" ;
  exit;
}

#--------------

sub fetch_newsletter_page {
	$EmailAddress = $form{'EmailAddress'};
	$EmailAddress =~ tr/A-Za-z0-9\.\@\-\_/ /cs;
	$EmailAddress =~ s/ //gi;	

	if ($EmailAddress !~ /.+\@.+\..+/) { $AlertPrompt = "Please enter a valid email address!"; }	
	elsif (length($EmailAddress) > 128) { $AlertPrompt = "Please enter a valid email address!"; }	
	else {
	  open (MAIL, "|$mail_prog -t");
	  #open (MAIL, ">>$mailtemp");
	  print MAIL "To: carlos\@sharpsa.co.za\n";
	  print MAIL "Bcc: file13\@w3b.co.za\n";
	  print MAIL "Reply-to: $EmailAddress\n";
	  print MAIL "From: $EmailAddress\n";
	  print MAIL "Subject: toner.co.za Newsletter subscription request\n\n";
	  print MAIL "Submitted by: $EmailAddress [$current_user] $DateNow\n\n";
	  close(MAIL);
		$AlertPrompt = "Thank you! Your email address has been included in our newsletter mailing list";
	}
	$func = "home";
	&fetch_home_page;
}

sub fetch_password_reminder {
  $MailAddy = $form{'MailAddy'};
  $MailAddy =~ tr/A-Z/a-z/;
  
  if ($step eq "form") {
    $page = "static_reminder";
  }
  if ($step eq "send") {
	$sql_statement = "SELECT PassWord,FirstName FROM buyer_base WHERE MailAddy = '$MailAddy' LIMIT 0,1;";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($PassWord,$FirstName) = @arr;
	if ($PassWord eq "") {
	  $AlertPrompt = "We could not find any accounts linked to the email address you provided.\\n\\nPlease make sure you entered your address correctly!";
      $page = "static_reminder";
	}
	else {
	  &send_reminder_email;
      $page = "mail_response";
	  $FormType = "Password Reminder";
	}
  }
  $SetBackLink = "<a href=\"../cgi-bin/index.pl?fn=basket&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$OffSet."&st=view\"><img src=\"../images/arrow_l.gif\" width=\"7\" height=\"7\" hspace=\"3\" align=\"absmiddle\" border=\"0\">Go back to Shopping Basket</a>";
  $PageTitle = "Password Reminder Service";
  &display_page_requested;
}

#--------------------------------------------------------------------------------------------------------------

sub fetch_forms_page {
  &parse_user_detailform;

  if ($step eq "support") {
    $Brand = $form{'Brand'};
    $Model = $form{'Model'};
	
	&generate_tracking_number;

	$MailText = $MailText."\n\nSupport Request Received from:\n\nTrack #:\t$TrackNumber\n";
	$MailText = $MailText."Date:\t\t$DateNow\nFrom IP:\t$current_user\nName:\t\t$Title $FirstName $Surname\n";
	$MailText = $MailText."Email:\t\t$MailAddy\nCompany:\t$Company\nPhone:\t\t($TelAreaCode) $Telephone\n\n";
	$MailText = $MailText."Machine Details:\nBrand:\t\t$Brand\nModel:\t\t$Model\nFault Description/Question:\n----------\n$Comments\n----------\n\n\n";
		
	$RecipMail = $SupportMail;
	$MailSubject = "Support Request www.Toner.co.za [$TrackNumber]";
	&send_email_message;
	$FormType = "Support Request";
  }
  if ($step eq "service") {
    $Address = $form{'Address'};
    $Brand = $form{'Brand'};
    $Model = $form{'Model'};
    $Account = $form{'Account'};
	$Address =~ s/\cM//g;
	
	&generate_tracking_number;

	$MailText = $MailText."\n\nService Request Received from:\n\nTrack #:\t$TrackNumber\n";
	$MailText = $MailText."Date:\t\t$DateNow\nFrom IP:\t$current_user\nName:\t\t$Title $FirstName $Surname\n";
	$MailText = $MailText."Email:\t\t$MailAddy\nCompany:\t$Company\nPhone:\t\t($TelAreaCode) $Telephone\nAccount:\t$Account\nAddress:\n$Address\n\n";
	$MailText = $MailText."Machine Details:\nBrand:\t\t$Brand\nModel:\t\t$Model\nFault Description:\n----------\n$Comments\n----------\n\n\n";
		
	$RecipMail = $ServiceMail;
	$MailSubject = "Service Request www.Toner.co.za [$TrackNumber]";
	&send_email_message;
	$FormType = "Service Request";
  }
  if ($step eq "contact") {
    $Industry = $form{'Industry'};
    $Position = $form{'Position'};

	&generate_tracking_number;

	$MailText = $MailText."\n\nContact Enquiry Received from:\n\nTrack #:\t$TrackNumber\n";
	$MailText = $MailText."Date:\t\t$DateNow\nFrom IP:\t$current_user\nName:\t\t$Title $FirstName $Surname\n";
	$MailText = $MailText."Industry:\t$Industry\nPosition:\t$Position\nEmail:\t\t$MailAddy\nCompany:\t$Company\nPhone:\t\t($TelAreaCode) $Telephone\n";
	$MailText = $MailText."Comments:\n----------\n$Comments\n----------\n\n\n";
		
	$RecipMail = $InfoMail;
	$MailSubject = "Contact Request www.Toner.co.za [$TrackNumber]";
	&send_email_message;
	$FormType = "Contact Request";
  }
  if ($step eq "enquire") {
    $ProdId = $form{'ProdId'};
    $ProdName = $form{'ProdName'};
    $OrderCode = $form{'OrderCode'};
    $Model = $form{'Model'};
    $MailTemplate = $mailroot."welcome.msg";

	&generate_tracking_number;

	$MailText = $MailText."\n\nProduct Enquiry Received from:\n\nTrack #:\t$TrackNumber\n";
	$MailText = $MailText."Date:\t\t$DateNow\nFrom IP:\t$current_user\nName:\t\t$Title $FirstName $Surname\n";
	$MailText = $MailText."Email:\t\t$MailAddy\nCompany:\t$Company\nPhone:\t\t($TelAreaCode) $Telephone\n";
	$MailText = $MailText."Comments:\n----------\n$Comments\n----------\n\n";
	$MailText = $MailText."Requires information on product:\nOrderCode:\t$OrderCode\nName:\t\t$Model - $ProdName\n";
	$MailText = $MailText."Link:\n ".$SiteBaseURL."cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&pid=".$ProdId."&st=view\n\n\n";
		
	$RecipMail = $SalesMail;
	$MailSubject = "Product Enquiry www.Toner.co.za [$TrackNumber]";
	&send_email_message;
	$SetBackLink = "<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$OffSet."\"><img src=\"../images/arrow_l.gif\" width=\"7\" height=\"7\" hspace=\"3\" align=\"absmiddle\" border=\"0\">Go back to Catalogue</a>";
	$FormType = "Product Enquiry";
  }

  $sql_statement = "INSERT INTO submit_forms VALUES ('','$TrackNumber','$TimeStamp','$current_user','$FormType','$buffer');";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  $PageTitle = "Your Enquiry has been sent!";
  $page = "mail_response";
  &display_page_requested;
}

sub generate_tracking_number {
  $sql_statement = "SELECT TrackNum FROM track_counter LIMIT 0,1;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $TrackNumber = @arr[0];
  $TrackNumber++;
  $sql_statement = "UPDATE track_counter SET TrackNum = '$TrackNumber';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
}


#--------------------------------------------------------------------------------------------------------------

sub fetch_search_page {

  if ($step eq "link") {
	($SearchBrand,$SearchCat,$SearchModel,$SearchRule) = split(/\^\^/,$info{'sk'});
  }
  else {
    $SearchBrand = $form{'SearchBrand'};
    $SearchCat = $form{'SearchCat'};
    $SearchModel = $form{'SearchModel'};
    $SearchRule = $form{'SearchRule'};
    $SearchModel =~ s/- Keywords -//gi;
  }


  $SearchModel =~ s/<([^>]|\n)*>//g;
  $SearchModel =~ tr/A-Za-z0-9\,\.\@\'\-/ /cs;
  $SearchModel =~ s/  / /gi;
  $SearchModel =~ s/^\s+//;
  $SearchModel =~ s/\s+$//;

  @skeys = split(/\ /,$SearchModel);
  $SearchTerm = $SearchModel;
  $SearchLink = $SearchModel;
  $SearchTerm =~ s/ /\%/g;
  #$SearchTerm = "%".$SearchTerm."%";
  $SearchLink =~ s/ /+/gi;
	
	if (($SearchModel eq "") && ($SearchCat ne "")) { $SearchKey = $SearchKey." AND Level1 = '$SearchCat'"; }
	#elsif (($SearchModel ne "") && ($SearchCat ne "")) { $SearchKey = $SearchKey." AND Level1 = '$SearchCat' AND (OrderCode LIKE '%".$SearchTerm."%' OR Model LIKE '%".$SearchTerm."%' OR ProdName LIKE '%".$SearchTerm."%' OR FeatureSumm LIKE '%".$SearchTerm."%' OR ProdNotes LIKE '%".$SearchTerm."%')"; }
	else { $SearchKey = $SearchKey." AND (OrderCode LIKE '%".$SearchTerm."%' OR Model LIKE '%".$SearchTerm."%' OR ProdName LIKE '%".$SearchTerm."%' OR FeatureSumm LIKE '%".$SearchTerm."%' OR ProdNotes LIKE '%".$SearchTerm."%' OR ProdNotes LIKE '%".$SearchTerm."%')"; }
  
  #print "Content-type: text/html\n\n\n";
  $ResultCount = "0";
  $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE ProdFlag = '1' ".$SearchKey.";";
  #print $sql_statement;
	$TestString = $sql_statement;
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $ResultCount = @arr[0];

  $sql_statement = "SELECT ProdId FROM prod_base WHERE ProdFlag = '1' ".$SearchKey." ORDER BY ProdId DESC LIMIT $OffSet,$DefProdOffset;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
	$ProdId = @arr[0];
	push(@results,$ProdId);
  }
  $ResultString = "Found <b>".$ResultCount."</b> matches to your Search Query";
  
  foreach $ProdId(@results) {
	$sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId' LIMIT 0,1;";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($ProdId, $OrderCode, $BrandId, $CLevel1, $CLevel2, $CLevel3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize) = @arr;
	$sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$CheckBasket = @arr[0];
	$sql_statement = "SELECT MfName from brand_base WHERE MfCode = '$MfId';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$XBrandName = @arr[0];
	$sql_statement = "SELECT CatName from cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$XCatName = @arr[0];

	if ($ProdImage eq "") { $ProdImage = $OrderCode.".jpg"; }
	$ImagePath = $ThumbNailPath.$ProdImage;
	if (-e $ImagePath) { $SetProdImage = $ProdImage; } else { $SetProdImage = "none.gif"; }
	  if ($CheckBasket == 0) { $BasketImage = "buy.gif"; $PreDescript = ""; }
	  else { $BasketImage = "buy_in.gif";  $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
	  if ($RetailPrice < 1) {
      $RetailTotal = "*P.O.A.";
      $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=enquire&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Request more Information</a>";
	  }
	  else {		
      $RetailTotal = $RetailPrice * $VatRate;
      $RetailTotal = $RetailTotal + $RetailPrice;
      $RetailTotal = sprintf("%.2f",$RetailTotal);
      $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=add&pid=".$ProdId."&fs=".$OffSet."&rt=search&sk=".$SearchBrand."^^".$SearchCat."^^".$SearchModel."^^".$SearchRule."#".$ProdId."\"><img src=\"../images/".$BasketImage."\" alt=\"Buy\" border=\"0\" height=\"19\" width=\"56\"></a>";
	  }
	  if ($StockLevel == 0) { $StockImage = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\"> Out of Stock"; }
	  else { $StockImage = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\"> In Stock"; }
	  $CatListing = $CatListing."<!--$ProdId-->\n <tr>\n <td width=\"100\" rowspan=\"5\" align=\"center\" bgcolor=\"#FFFFFF\" class=\"dotborder\" valign=\"top\"><a name=\"".$ProdId."\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../user/thumbs/".$SetProdImage."\" width=\"100\" alt=\"View ".$ProdName."\" border=\"0\"></a></td>\n <td width=\"250\" height=\"10\" colspan=\"3\" bgcolor=\"".$HdrColor1."\" class=\"dotborderlg\"><img src=\"../images/pointer.gif\" hspace=\"2\" align=\"absmiddle\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><b>".$ProdName."</b></a></td>\n <td align=\"right\" bgcolor=\"".$HdrColor2."\" class=\"dotborderlg\"><span class=\"PriceTag\">".$CurrencyMark." ".$RetailTotal." </span>&nbsp;</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"40\" colspan=\"4\" valign=\"top\" class=\"dotborderdesc\">".$PreDescript." ".$FeatureSumm."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Model:</td>\n <td class=\"dotborderlg\">&nbsp;".$Model."</td>\n <td align=\"right\" class=\"dotborderlg\">Order Code:&nbsp; </td>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;".$OrderCode."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Stock:</td>\n <td class=\"dotborderlg\" colspan=\"3\">&nbsp;".$StockImage."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" colspan=\"4\" align=\"right\" class=\"dotborderlg\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../images/detail.gif\" border=\"0\" height=\"19\" hspace=\"3\" width=\"71\"></a>".$AddBasketLink."&nbsp;</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td colspan=\"5\"><img src=\"../images/blank.gif\" width=\"2\" height=\"5\"></td>\n </tr>\n";
	}

  $StartRecord = $OffSet + 1;
  $DisplayText = "Displaying Items <b>$StartRecord</b> to <b>$ResultCount</b> of <b>$DisplayLimit</b> Results to...";
  $CurrOffSet = $OffSet;
  $PrevLink = $OffSet - $DefProdOffset;
  $OffSet = $OffSet + $DefProdOffset;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

  if ($OffSet > $DefProdOffset) { $RNavLink = $RNavLink."&laquo; <a href=\"../cgi-bin/index.pl?fn=spsearch&st=link&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$PrevLink."&sk=".$SearchBrand."^^".$SearchCat."^^".$SearchModel."^^".$SearchRule."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
  $RNavLink = $RNavLink."| ";
  for ($a=0; $a <= 30; $a++) {
    $TestOffSet = $a * $DefProdOffset;
    $LinkLoop = $a + 1;
    if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
    elsif ($TestOffSet < $ResultCount) { $RNavLink = $RNavLink."<a href=\"../cgi-bin/index.pl?fn=spsearch&st=link&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$TestOffSet."&sk=".$SearchBrand."^^".$SearchCat."^^".$SearchModel."^^".$SearchRule."\">$LinkLoop</a> \n"; }
  }
  $RNavLink = $RNavLink."| ";
  if ($OffSet < $ResultCount) { $RNavLink = $RNavLink." <a href=\"../cgi-bin/index.pl?fn=spsearch&st=link&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$OffSet."&sk=".$SearchBrand."^^".$SearchCat."^^".$SearchModel."^^".$SearchRule."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
  if ($OffSet > 0) { $OffSet = $OffSet - $DefProdOffset; }

  if ($form{'SearchModel'} ne "") {
    $sql_statement = "INSERT INTO search_terms VALUES ('','1','$TimeStamp','$current_user','$SearchModel','$ResultCount');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  }

  $CatNavString = "<a href=\"../cgi-bin/index.pl?fn=spsearch&st=link&br=".$BrandId."&mct=100&sct=100\"><b>".$BrandName."</b></a> &raquo; $XCatName";
  if ($SearchModel eq "") { $SearchModel = "- Model or Cartridge Number -"; }
  $PageTitle = "Search Results";
  $page = "search_view";

  
  
  &display_page_requested;
  exit;



}

#--------------------------------------------------------------------------------------------------------------
sub fetch_category_page {
  $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $XCatName = @arr[0];
  $CatNavString = "$XCatName";

	$sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND ProdFlag = '1';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$ProdCount = @arr[0];

	$sql_statement = "SELECT ProdId FROM prod_base WHERE Level1 = '$CLevel1' AND ProdFlag = '1' ORDER BY ProdId DESC LIMIT ".$OffSet.",".$DefProdOffset.";";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	$TestString = $sql_statement;
	while (@arr = $sth->fetchrow) {
	  $XProdId = @arr[0];
	  push(@plist,$XProdId);
	}
	
	foreach $ProdId(@plist) {
	  $sql_statement = "SELECT OrderCode,Model,ProdName,RetailPrice,FeatureSumm,StockLevel,ProdImage,Level1,MfId,ProdImage FROM prod_base WHERE ProdId = '$ProdId';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  ($OrderCode,$Model,$ProdName,$RetailPrice,$FeatureSumm,$StockLevel,$ProdImage,$PLevel1,$BrandId,$ProdImage) = @arr;
	  $sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $CheckBasket = @arr[0];
		
	  if ($ProdImage eq "") { $ProdImage = $OrderCode.".jpg"; }
	  $ImagePath = $ThumbNailPath.$ProdImage;
	  if (-e $ImagePath) { $SetProdImage = $ProdImage; } else { $ProdImage = "none.gif"; }
	  if ($CheckBasket == 0) { $BasketImage = "buy.gif"; $PreDescript = ""; }
	  else { $BasketImage = "buy_in.gif";  $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
	  if ($RetailPrice < 1) {
      $RetailTotal = "*P.O.A.";
      $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=enquire&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Request more Information</a>";
	  }
	  else {		
      $RetailTotal = $RetailPrice * $VatRate;
      $RetailTotal = $RetailTotal + $RetailPrice;
      $RetailTotal = sprintf("%.2f",$RetailTotal);
      $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=add&pid=".$ProdId."&fs=".$OffSet."&rt=cview#".$ProdId."\"><img src=\"../images/".$BasketImage."\" alt=\"Buy\" border=\"0\" height=\"19\" width=\"56\"></a>";
	  }
	  if ($StockLevel == 0) { $StockImage = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\"> Out of Stock"; }
	  else { $StockImage = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\"> In Stock"; }
	  $CatListing = $CatListing."<!--$ProdId-->\n <tr>\n <td width=\"100\" rowspan=\"5\" align=\"center\" bgcolor=\"#FFFFFF\" class=\"dotborder\" valign=\"top\"><a name=\"".$ProdId."\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../user/thumbs/".$ProdImage."\" width=\"100\" alt=\"View ".$ProdName."\" border=\"0\"></a></td>\n <td width=\"250\" height=\"10\" colspan=\"3\" bgcolor=\"".$HdrColor1."\" class=\"dotborderlg\"><img src=\"../images/pointer.gif\" hspace=\"2\" align=\"absmiddle\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><b>".$ProdName."</b></a></td>\n <td align=\"right\" bgcolor=\"".$HdrColor2."\" class=\"dotborderlg\"><span class=\"PriceTag\">".$CurrencyMark." ".$RetailTotal." </span>&nbsp;</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"40\" colspan=\"4\" valign=\"top\" class=\"dotborderdesc\">".$PreDescript." ".$FeatureSumm."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Model:</td>\n <td class=\"dotborderlg\">&nbsp;".$Model."</td>\n <td align=\"right\" class=\"dotborderlg\">Order Code:&nbsp; </td>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;".$OrderCode."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Stock:</td>\n <td class=\"dotborderlg\" colspan=\"3\">&nbsp;".$StockImage."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" colspan=\"4\" align=\"right\" class=\"dotborderlg\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../images/detail.gif\" border=\"0\" height=\"19\" hspace=\"3\" width=\"71\"></a>".$AddBasketLink."&nbsp;</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td colspan=\"5\"><img src=\"../images/blank.gif\" width=\"2\" height=\"5\"></td>\n </tr>\n";
	}

    $StartRecord = $OffSet + 1;
    $DisplayText = "Displaying Items <b>$StartRecord</b> to <b>$ResultCount</b> of <b>$DisplayLimit</b> Results to...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $DefProdOffset;
    $OffSet = $OffSet + $DefProdOffset;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $DefProdOffset) { $RNavLink = $RNavLink."&laquo; <a href=\"../cgi-bin/index.pl?fn=special&fs=".$PrevLink."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $DefProdOffset;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ProdCount) { $RNavLink = $RNavLink."<a href=\"../cgi-bin/index.pl?fn=cview&mct=$CLevel1&fs=".$TestOffSet."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ProdCount) { $RNavLink = $RNavLink." <a href=\"../cgi-bin/index.pl?fn=cview&mct=$CLevel1&fs=".$OffSet."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
	if ($OffSet > 0) { $OffSet = $OffSet - $DefProdOffset; }

	$ImagePath = $BrandImagePath.$CLevel1.".gif";
	if (-e $ImagePath) { $BrandImage = $CLevel1.".gif"; } else { $BrandImage = "default.gif"; }

	$PageTitle = "Products : $XCatName";
	$page = "cat_listing";
  &display_page_requested;
  exit;
}

sub fetch_specials_page {

	$sql_statement = "SELECT COUNT(*) FROM prod_base WHERE SpecFlag = '1' AND ProdFlag = '1';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$ProdCount = @arr[0];

	$sql_statement = "SELECT ProdId FROM prod_base WHERE SpecFlag = '1' AND ProdFlag = '1' ORDER BY ProdId DESC LIMIT ".$OffSet.",".$DefProdOffset.";";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	$TestString = $sql_statement;
	while (@arr = $sth->fetchrow) {
	  $XProdId = @arr[0];
	  push(@plist,$XProdId);
	}
	
	foreach $ProdId(@plist) {
	  $sql_statement = "SELECT OrderCode,Model,ProdName,RetailPrice,FeatureSumm,StockLevel,ProdImage,Level1,MfId,ProdImage FROM prod_base WHERE ProdId = '$ProdId';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  ($OrderCode,$Model,$ProdName,$RetailPrice,$FeatureSumm,$StockLevel,$ProdImage,$PLevel1,$BrandId,$ProdImage) = @arr;
	  $sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $CheckBasket = @arr[0];
		
	  if ($ProdImage eq "") { $ProdImage = $OrderCode.".jpg"; }
	  $ImagePath = $ThumbNailPath.$ProdImage;
	  if (-e $ImagePath) { $SetProdImage = $ProdImage; } else { $ProdImage = "none.gif"; }
	  if ($CheckBasket == 0) { $BasketImage = "buy.gif"; $PreDescript = ""; }
	  else { $BasketImage = "buy_in.gif";  $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
	  if ($RetailPrice < 1) {
      $RetailTotal = "*P.O.A.";
      $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=enquire&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Request more Information</a>";
	  }
	  else {		
      $RetailTotal = $RetailPrice * $VatRate;
      $RetailTotal = $RetailTotal + $RetailPrice;
      $RetailTotal = sprintf("%.2f",$RetailTotal);
      $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=add&pid=".$ProdId."&fs=".$OffSet."&rt=spec#".$ProdId."\"><img src=\"../images/".$BasketImage."\" alt=\"Buy\" border=\"0\" height=\"19\" width=\"56\"></a>";
	  }
	  if ($StockLevel == 0) { $StockImage = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\"> Out of Stock"; }
	  else { $StockImage = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\"> In Stock"; }
	  $CatListing = $CatListing."<!--$ProdId-->\n <tr>\n <td width=\"100\" rowspan=\"5\" align=\"center\" bgcolor=\"#FFFFFF\" class=\"dotborder\" valign=\"top\"><a name=\"".$ProdId."\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../user/thumbs/".$ProdImage."\" width=\"100\" alt=\"View ".$ProdName."\" border=\"0\"></a></td>\n <td width=\"250\" height=\"10\" colspan=\"3\" bgcolor=\"".$HdrColor1."\" class=\"dotborderlg\"><img src=\"../images/pointer.gif\" hspace=\"2\" align=\"absmiddle\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><b>".$ProdName."</b></a></td>\n <td align=\"right\" bgcolor=\"".$HdrColor2."\" class=\"dotborderlg\"><span class=\"PriceTag\">".$CurrencyMark." ".$RetailTotal." </span>&nbsp;</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"40\" colspan=\"4\" valign=\"top\" class=\"dotborderdesc\">".$PreDescript." ".$FeatureSumm."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Model:</td>\n <td class=\"dotborderlg\">&nbsp;".$Model."</td>\n <td align=\"right\" class=\"dotborderlg\">Order Code:&nbsp; </td>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;".$OrderCode."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Stock:</td>\n <td class=\"dotborderlg\" colspan=\"3\">&nbsp;".$StockImage."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" colspan=\"4\" align=\"right\" class=\"dotborderlg\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$PLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../images/detail.gif\" border=\"0\" height=\"19\" hspace=\"3\" width=\"71\"></a>".$AddBasketLink."&nbsp;</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td colspan=\"5\"><img src=\"../images/blank.gif\" width=\"2\" height=\"5\"></td>\n </tr>\n";
	}

    $StartRecord = $OffSet + 1;
    $DisplayText = "Displaying Items <b>$StartRecord</b> to <b>$ResultCount</b> of <b>$DisplayLimit</b> Results to...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $DefProdOffset;
    $OffSet = $OffSet + $DefProdOffset;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $DefProdOffset) { $RNavLink = $RNavLink."&laquo; <a href=\"../cgi-bin/index.pl?fn=special&fs=".$PrevLink."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $DefProdOffset;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ProdCount) { $RNavLink = $RNavLink."<a href=\"../cgi-bin/index.pl?fn=special&fs=".$TestOffSet."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ProdCount) { $RNavLink = $RNavLink." <a href=\"../cgi-bin/index.pl?fn=special&fs=".$OffSet."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
	if ($OffSet > 0) { $OffSet = $OffSet - $DefProdOffset; }

	$PageTitle = "Products : Special Offers";
	$page = "special_offers";
  &display_page_requested;
  exit;
}

#--------------------------------------------------------------------------------------------------------------

sub fetch_brand_page {
  $sql_statement = "SELECT MfName FROM brand_base WHERE MfCode = '$BrandId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $BrandName = @arr[0];
  $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $XCatName = @arr[0];

  if (($CLevel1 eq "100") && ($CLevel2 eq "100")) {

	$sql_statement = "SELECT DISTINCT(Level1) FROM prod_base WHERE MfId = '$BrandId' AND ProdFlag = '1' ORDER BY Level1;";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	while (@arr = $sth->fetchrow) {
	  $XLevel1 = @arr[0];
	  push(@brands,$XLevel1);
	}
	foreach $XLevel1(@brands) {
	  $sql_statement = "SELECT CatName FROM cat_base WHERE Level1 = '$XLevel1' AND Level2 = '100';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $XCatName = @arr[0];
	  $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE MfId = '$BrandId' AND Level1 = '$XLevel1' AND ProdFlag = '1';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $XProdCount = @arr[0];

	  $CatListing = $CatListing."<!--$XLevel1-->\n<tr>\n <td class=\"dotborderlg\"><img src=\"../images/arrow_r.gif\" width=\"7\" height=\"7\" hspace=\"2\" align=\"absmiddle\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$XLevel1."\">".$XCatName."</a></td><td align=\"center\" nowrap class=\"dotborderlg\">".$XProdCount."</td>\n</tr>\n";
	}
	$CatNavString = "$BrandName";
	$PageTitle = "Products : $BrandName";
	$page = "brand_main";
  }
  elsif ($step eq "view") { 
	$sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId' LIMIT 0,1;";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($ProdId, $OrderCode, $MfId, $Level1, $Level2, $Level3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize, $ProdFlag, $SpecFlag, $RotateFlag, $DisplayPriority, $ProdType, $OptionText_0, $OptionText_1, $OptionText_2, $OptionText_3, $OptionText_4, $OptionText_5, $OptionPrice_0, $OptionPrice_1, $OptionPrice_2, $OptionPrice_3, $OptionPrice_4, $OptionPrice_5, $OptionSuffix_0, $OptionSuffix_1, $OptionSuffix_2, $OptionSuffix_3, $OptionSuffix_4, $OptionSuffix_5, $OptionWeight_0, $OptionWeight_1, $OptionWeight_2, $OptionWeight_3, $OptionWeight_4, $OptionWeight_5, $OptionStock_0, $OptionStock_1, $OptionStock_2, $OptionStock_3, $OptionStock_4, $OptionStock_5, $ViewCount, $KeyWordMeta) = @arr;
	$ViewCount++;
  $sql_statement = "UPDATE prod_base SET ViewCount = '$ViewCount' WHERE ProdId = '$ProdId';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;

	$DescriptionMeta = $FeatureText;
	$sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$CheckBasket = @arr[0];
	if ($CheckBasket == 0) { $HdrColor1 = "#F2F2F2"; $HdrColor2 = "#E2E2E2"; $PreDescript = ""; }
	else { $HdrColor1 = "#FFCCCC"; $HdrColor2 = "#FF9999"; $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
	if ($StockLevel == 0) { $StockImage = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\"> Out of Stock"; }
	else { $StockImage = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\"> In Stock"; }
	
	if ($ProdImage eq "") { $ProdImage = $OrderCode.".jpg"; }
	$ImagePath = $FullImagePath.$ProdImage;
	if (-e $ImagePath) { $SetProdImage = $ProdImage; } else { $ProdImage = "none.gif"; }
	$sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$CheckBasket = @arr[0];
		
	  if ($CheckBasket == 0) { $BasketImage = "buy.gif"; $PreDescript = ""; }
	  else { $BasketImage = "buy_in.gif";  $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
	
	if ($RetailPrice < 1) {
	  $RetailPrice = "*P.O.A.";
	  $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=enquire&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Request more Information</a>";
	  $page = "brand_eview";
	}
	else {		
	  $RetailTotal = $RetailPrice * $VatRate;
	  $RetailTotal = $RetailTotal + $RetailPrice;
	  $RetailPrice = sprintf("%.2f",$RetailTotal);
	  $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=add&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Add to Shopping Basket</a>";
	  $page = "brand_view";
	}
	if ($FeatureText eq "") { $FeatureText = $FeatureSumm; }

	$PageTitle = "Products : $XCatName : $ProdName";
    $FeatureText =~ s/\*/\<br\>\&\#149\; /g;
	if ($step eq "enquire") { $page = "category_eqview"; }

	$CatNavString = "<a href=\"../cgi-bin/index.pl?fn=cview&mct=".$CLevel1."&sct=".$CLevel2."&pct=0\"><b>".$XCatName."</b></a> &raquo; $OrderCode";
	$CatDescript = $MidDescript;
	$ImagePath = $BrandImagePath.$CLevel1.".gif";
	if (-e $ImagePath) { $BrandImage = $CLevel1.".gif"; } else { $BrandImage = "default.gif"; }

	&display_page_requested;
  }
 
  elsif ($CLevel1 ne "100") {
	$sql_statement = "SELECT COUNT(*) FROM prod_base WHERE MfId = '$BrandId' AND Level1 = '$CLevel1' AND ProdFlag = '1';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$ProdCount = @arr[0];

	$sql_statement = "SELECT ProdId FROM prod_base WHERE MfId = '$BrandId' AND Level1 = '$CLevel1' AND ProdFlag = '1' ORDER BY ProdId DESC LIMIT ".$OffSet.",".$DefProdOffset.";";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	$TestString = $sql_statement;
	while (@arr = $sth->fetchrow) {
	  $XProdId = @arr[0];
	  push(@plist,$XProdId);
	}
	
	foreach $ProdId(@plist) {
	  $TestString = $TestString."\n$ProdId";
      $sql_statement = "SELECT OrderCode,Model,ProdName,RetailPrice,FeatureSumm,StockLevel,ProdImage FROM prod_base WHERE ProdId = '$ProdId';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  ($OrderCode,$Model,$ProdName,$RetailPrice,$FeatureSumm,$StockLevel,$ProdImage) = @arr;
	  $sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $CheckBasket = @arr[0];
		
	  if ($ProdImage eq "") { $ProdImage = $OrderCode.".jpg"; }
	  $ImagePath = $ThumbNailPath.$ProdImage;
	  if (-e $ImagePath) { $SetProdImage = $ProdImage; } else { $ProdImage = "none.gif"; }
	  if ($RetailPrice < 1) {
		$RetailTotal = "*P.O.A.";
		$AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=enquire&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Request more Information</a>";
	  }
	  else {		
		$RetailTotal = $RetailPrice * $VatRate;
		$RetailTotal = $RetailTotal + $RetailPrice;
		$RetailTotal = sprintf("%.2f",$RetailTotal);
		$AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=add&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Add to Shopping Basket</a>";
	  }
	  if ($CheckBasket == 0) { $HdrColor1 = "#F2F2F2"; $HdrColor2 = "#E2E2E2"; $PreDescript = ""; }
	  else { $HdrColor1 = "#FFCCCC"; $HdrColor2 = "#FF9999"; $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
	  if ($StockLevel == 0) { $StockImage = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\"> Out of Stock"; }
	  else { $StockImage = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\"> In Stock"; }
	  $CatListing = $CatListing."<!--$ProdId-->\n <tr>\n <td width=\"100\" rowspan=\"5\" align=\"center\" bgcolor=\"#FFFFFF\" class=\"dotborder\"><a name=\"".$ProdId."\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../user/thumbs/".$ProdImage."\" width=\"100\" alt=\"View ".$ProdName."\" border=\"0\"></a></td>\n <td width=\"250\" height=\"10\" colspan=\"3\" bgcolor=\"".$HdrColor1."\" class=\"dotborderlg\"><img src=\"../images/arrow_r.gif\" width=\"7\" height=\"7\" hspace=\"2\" align=\"absmiddle\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><b>".$ProdName."</b></a></td>\n <td align=\"right\" bgcolor=\"".$HdrColor2."\" class=\"dotborderlg\"><b>".$CurrencyMark." ".$RetailTotal." </b>&nbsp;</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"40\" colspan=\"4\" valign=\"top\" class=\"dotborderdesc\">".$PreDescript." ".$FeatureSumm."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Model:</td>\n <td class=\"dotborderlg\">&nbsp;".$Model."</td>\n <td align=\"right\" class=\"dotborderlg\">Order Code:&nbsp; </td>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;".$OrderCode."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Stock:</td>\n <td class=\"dotborderlg\" colspan=\"3\">&nbsp;".$StockImage."</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td height=\"10\" colspan=\"4\" align=\"right\" class=\"dotborderlg\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\">View</a> | ".$AddBasketLink."&nbsp;</td>\n </tr>\n";
	  $CatListing = $CatListing." <tr>\n <td colspan=\"5\"><img src=\"../images/blank.gif\" width=\"2\" height=\"5\"></td>\n </tr>\n";
	}

    $StartRecord = $OffSet + 1;
    $DisplayText = "Displaying Items <b>$StartRecord</b> to <b>$ResultCount</b> of <b>$DisplayLimit</b> Results to...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $DefProdOffset;
    $OffSet = $OffSet + $DefProdOffset;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $DefProdOffset) { $RNavLink = $RNavLink."&laquo; <a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$PrevLink."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $DefProdOffset;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ProdCount) { $RNavLink = $RNavLink."<a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$TestOffSet."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ProdCount) { $RNavLink = $RNavLink." <a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$OffSet."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
	if ($OffSet > 0) { $OffSet = $OffSet - $DefProdOffset; }

	$ImagePath = $BrandImagePath.$CLevel1.".gif";
	if (-e $ImagePath) { $BrandImage = $CLevel1.".gif"; } else { $BrandImage = "default.gif"; }

	$CatNavString = "<a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=100&sct=100\"><b>".$BrandName."</b></a> &raquo; $XCatName";
	$PageTitle = "Products : $BrandName : $XCatName";
	$page = "brand_listing";
  }
  &display_page_requested;
  exit;
}

#--------------------------------------------------------------------------------------------------------------

sub fetch_product_page {
  $sql_statement = "SELECT CatName,CatDescript FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($TopCatName,$TopDescript) = @arr;
  $sql_statement = "SELECT CatName,CatDescript FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($MidCatName,$MidDescript) = @arr;
  $sql_statement = "SELECT COUNT(*) FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 != '100';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $SubCount = @arr[0];
  
  if ($step eq "special") {
	$sql_statement = "SELECT ProdId FROM prod_base WHERE SpecFlag = '1' AND ProdFlag != '0' ORDER BY ProdId DESC LIMIT ".$OffSet.",".$DefProdOffset.";";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	while (@arr = $sth->fetchrow) {
	  $ProdId = @arr[0];
	  push(@plist,$ProdId);
	}

	foreach $ProdId(@plist) {
      $sql_statement = "SELECT OrderCode,Model,ProdName,RetailPrice,FeatureSumm,StockLevel,ProdImage,Level1,Level2 FROM prod_base WHERE ProdId = '$ProdId';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  ($OrderCode,$Model,$ProdName,$RetailPrice,$FeatureSumm,$StockLevel,$ProdImage,$XCLevel1,$XCLevel2) = @arr;
	  $sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $CheckBasket = @arr[0];
		
	  $ImagePath = $ThumbNailPath.$OrderCode.".jpg";
	  if (-e $ImagePath) { $ProdImage = $OrderCode.".jpg"; } else { $ProdImage = "none.gif"; }
	  if ($RetailPrice < 1) {
		$RetailTotal = "*P.O.A.";
		$AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$XCLevel1."&sct=".$XCLevel2."&pct=0&st=enquire&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Request more Information</a>";
	  }
	  else {		
		$RetailTotal = $RetailPrice * $VatRate;
		$RetailTotal = $RetailTotal + $RetailPrice;
		$RetailTotal = sprintf("%.2f",$RetailTotal);
		$AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=basket&mct=".$XCLevel1."&sct=".$XCLevel2."&pct=0&st=add&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Add to Shopping Basket</a>";
	  }
	  if ($CheckBasket == 0) { $HdrColor1 = "#F2F2F2"; $HdrColor2 = "#E2E2E2"; $PreDescript = ""; }
	  else { $HdrColor1 = "#FFCCCC"; $HdrColor2 = "#FF9999"; $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
	  if ($StockLevel == 0) { $StockImage = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\"> Out of Stock"; }
	  else { $StockImage = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\"> In Stock"; }
		$CatListing = $CatListing."<!--$ProdId-->\n <tr>\n <td width=\"100\" rowspan=\"5\" valign=\"top\" align=\"center\" bgcolor=\"#FFFFFF\" class=\"dotborder\"><a name=\"".$ProdId."\"><a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$XCLevel1."&sct=".$XCLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../user/thumbs/".$ProdImage."\" width=\"100\" alt=\"View ".$ProdName."\" border=\"0\"></a></td>\n <td width=\"250\" height=\"10\" colspan=\"3\" bgcolor=\"".$HdrColor1."\" class=\"dotborderlg\"><img src=\"../images/arrow_r.gif\" width=\"7\" height=\"7\" hspace=\"2\" align=\"absmiddle\"><a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$XCLevel1."&sct=".$XCLevel2."&pct=0&st=view&pid=".$ProdId."\"><b>".$ProdName."</b></a></td>\n <td align=\"right\" bgcolor=\"".$HdrColor2."\" class=\"dotborderlg\"><b>".$CurrencyMark." ".$RetailTotal." </b>&nbsp;</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td height=\"40\" colspan=\"4\" valign=\"top\" class=\"dotborderdesc\">".$PreDescript." ".$FeatureSumm."</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Model:</td>\n <td class=\"dotborderlg\">&nbsp;".$Model."</td>\n <td align=\"right\" class=\"dotborderlg\">Order Code:&nbsp; </td>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;".$OrderCode."</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Stock:</td>\n <td class=\"dotborderlg\" colspan=\"3\">&nbsp;".$StockImage."</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td height=\"10\" colspan=\"4\" align=\"right\" class=\"dotborderlg\"><a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$XCLevel1."&sct=".$XCLevel2."&pct=0&st=view&pid=".$ProdId."\">View</a> | ".$AddBasketLink."&nbsp;</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td colspan=\"5\"><img src=\"../images/blank.gif\" width=\"2\" height=\"5\"></td>\n </tr>\n";
	}
	$StartRecord = $OffSet + 1;
    $DisplayText = "Displaying Items <b>$StartRecord</b> to <b>$ResultCount</b> of <b>$DisplayLimit</b> Results to...";
    $CurrOffSet = $OffSet;
    $PrevLink = $OffSet - $DefProdOffset;
    $OffSet = $OffSet + $DefProdOffset;
    #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

    if ($OffSet > $DefProdOffset) { $RNavLink = $RNavLink."&laquo; <a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$XCLevel1."&sct=".$XCLevel2."&pct=0&fs=".$PrevLink."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
    $RNavLink = $RNavLink."| ";
    for ($a=0; $a <= 30; $a++) {
      $TestOffSet = $a * $DefProdOffset;
      $LinkLoop = $a + 1;
      if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
      elsif ($TestOffSet < $ProdCount) { $RNavLink = $RNavLink."<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$XCLevel1."&sct=".$XCLevel2."&pct=0&fs=".$TestOffSet."\">$LinkLoop</a> \n"; }
    }
    $RNavLink = $RNavLink."| ";
    if ($OffSet < $ProdCount) { $RNavLink = $RNavLink." <a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$XCLevel1."&sct=".$XCLevel2."&pct=0&fs=".$OffSet."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
	$PageTitle = "Special Offers!!!";
	$page = "category_spview";
	&display_page_requested;
  }
  
  if (($step eq "view") || ($step eq "enquire")) { 
	$sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId' LIMIT 0,1;";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($ProdId, $OrderCode, $MfId, $Level1, $Level2, $Level3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize) = @arr;
	$sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$CheckBasket = @arr[0];
	if ($CheckBasket == 0) { $HdrColor1 = "#F2F2F2"; $HdrColor2 = "#E2E2E2"; $PreDescript = ""; }
	else { $HdrColor1 = "#FFCCCC"; $HdrColor2 = "#FF9999"; $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
	if ($StockLevel == 0) { $StockImage = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\"> Out of Stock"; }
	else { $StockImage = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\"> In Stock"; }
	$ImagePath = $FullImagePath.$OrderCode.".jpg";
	$TestString = $ImagePath;
	if (-e $ImagePath) { $ProdImage = $OrderCode.".jpg"; } else { $ProdImage = "none.gif"; }

	if ($RetailPrice < 1) {
	  $RetailPrice = "*P.O.A.";
	  $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=enquire&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Request more Information</a>";
	  $page = "category_eview";
	}
	else {		
	  $RetailTotal = $RetailPrice * $VatRate;
	  $RetailTotal = $RetailTotal + $RetailPrice;
	  $RetailPrice = sprintf("%.2f",$RetailTotal);
	  $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=basket&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=add&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Add to Shopping Basket</a>";
	  $page = "category_pview";
	}
	if ($FeatureText eq "") { $FeatureText = $FeatureSumm; }

	$PageTitle = "Products : $ProdName";
    $FeatureText =~ s/\*/\<br\>\&\#149\; /g;
	if ($step eq "enquire") { $page = "category_eqview"; }

	$CatNavString = "<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=100&pct=0\"><b>".$TopCatName."</b></a> &raquo; <a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0\">".$MidCatName;
	$CatDescript = $MidDescript;

	&display_page_requested;
  }
  if (($CLevel2 eq "100") && ($SubCount > 0)) {
	$CatNavString = "<b>$TopCatName</b>";
	$CatDescript = $TopDescript;
	$PageTitle = "Products : $TopCatName";
    $page = "category_mview";

    $sql_statement = "SELECT Level2 FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 != '100';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    while (@arr = $sth->fetchrow) {
	  $CLevel2 = @arr[0];
	  push(@clist,$CLevel2);
	}
	
	foreach $CLevel2(@clist) {
	  $sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $CatCount = @arr[0];
	  $sql_statement = "SELECT CatName,CatDescript FROM cat_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  ($MidCatName,$MidCatDescript) = @arr;
	  #$TestString = $TestString."\nupdate cat_base set CatDescript = 'General description of items in $TopCatName : $MidCatName' where Level1 = '$CLevel1' and Level2 = '$CLevel2';";
	  $CatListing = $CatListing." <tr>\n<td width=\"85%\" class=\"dotborderlg\" bgcolor=\"#F2F2F2\"><img src=\"../images/arrow_r.gif\" width=\"7\" height=\"7\" hspace=\"2\" align=\"absmiddle\"><b><a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0\">".$MidCatName."</a></b></td>\n<td width=\"20%\" align=\"right\" class=\"dotborderlg\" bgcolor=\"#E2E2E2\">".$CatCount."&nbsp;Items</td>\n</tr>\n <tr>\n <td colspan=\"2\" class=\"dotborderdesc\" bgcolor=\"#FFFFFF\">".$MidCatDescript."&nbsp;</td>\n </tr>\n";
	}
	
  }
  else {
	if ($SubCount > 0) {
	  $CatNavString = "<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=100&pct=0\"><b>".$TopCatName."</b></a> &raquo; $MidCatName";
	  $CatDescript = $MidDescript;
	  $PageTitle = "Products : $TopCatName : $MidCatName";
	}
	else {
	  $CatNavString = "<b>$TopCatName</b>";
	  $CatDescript = $TopDescript;
	  $PageTitle = "Products : $TopCatName";
	}
	$sql_statement = "SELECT COUNT(*) FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$ProdCount = @arr[0];
	
	if ($ProdCount < 1) { $CatListing = $CatListing." <tr>\n<td class=\"dotborderdesc\" bgcolor=\"#FFFFFF\" align=\"center\" colspan=\"2\">There are no Products in this category as yet</td></tr>\n"; }
	else {

	  $sql_statement = "SELECT ProdId FROM prod_base WHERE Level1 = '$CLevel1' AND Level2 = '$CLevel2' AND ProdFlag != '0' ORDER BY ProdId DESC LIMIT ".$OffSet.",".$DefProdOffset.";";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  while (@arr = $sth->fetchrow) {
		$ProdId = @arr[0];
		push(@plist,$ProdId);
	  }

	  foreach $ProdId(@plist) {
    	$sql_statement = "SELECT OrderCode,Model,ProdName,RetailPrice,FeatureSumm,StockLevel,ProdImage FROM prod_base WHERE ProdId = '$ProdId';";
		$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
		@arr = $sth->fetchrow;
		($OrderCode,$Model,$ProdName,$RetailPrice,$FeatureSumm,$StockLevel,$ProdImage) = @arr;
		$sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
		$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
		@arr = $sth->fetchrow;
		$CheckBasket = @arr[0];
		
		$ImagePath = $ThumbNailPath.$OrderCode.".jpg";
		if (-e $ImagePath) { $ProdImage = $OrderCode.".jpg"; } else { $ProdImage = "none.gif"; }
		if ($RetailPrice < 1) {
		  $RetailTotal = "*P.O.A.";
		  $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=enquire&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Request more Information</a>";
		}
		else {		
		  $RetailTotal = $RetailPrice * $VatRate;
		  $RetailTotal = $RetailTotal + $RetailPrice;
		  $RetailTotal = sprintf("%.2f",$RetailTotal);
		  $AddBasketLink = "<a href=\"../cgi-bin/index.pl?fn=basket&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=add&pid=".$ProdId."&fs=".$OffSet."#".$ProdId."\">Add to Shopping Basket</a>";
		}
		if ($CheckBasket == 0) { $HdrColor1 = "#F2F2F2"; $HdrColor2 = "#E2E2E2"; $PreDescript = ""; }
		else { $HdrColor1 = "#FFCCCC"; $HdrColor2 = "#FF9999"; $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }
		if ($StockLevel == 0) { $StockImage = "<img src=\"../images/out_stock.gif\" align=\"absmiddle\"> Out of Stock"; }
		else { $StockImage = "<img src=\"../images/in_stock.gif\" align=\"absmiddle\"> In Stock"; }
		$CatListing = $CatListing."<!--$ProdId-->\n <tr>\n <td width=\"100\" rowspan=\"5\" valign=\"top\" align=\"center\" bgcolor=\"#FFFFFF\" class=\"dotborder\"><a name=\"".$ProdId."\"><a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><img src=\"../user/thumbs/".$ProdImage."\" width=\"100\" alt=\"View ".$ProdName."\" border=\"0\"></a></td>\n <td width=\"250\" height=\"10\" colspan=\"3\" bgcolor=\"".$HdrColor1."\" class=\"dotborderlg\"><img src=\"../images/arrow_r.gif\" width=\"7\" height=\"7\" hspace=\"2\" align=\"absmiddle\"><a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\"><b>".$ProdName."</b></a></td>\n <td align=\"right\" bgcolor=\"".$HdrColor2."\" class=\"dotborderlg\"><b>".$CurrencyMark." ".$RetailTotal." </b>&nbsp;</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td height=\"40\" colspan=\"4\" valign=\"top\" class=\"dotborderdesc\">".$PreDescript." ".$FeatureSumm."</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Model:</td>\n <td class=\"dotborderlg\">&nbsp;".$Model."</td>\n <td align=\"right\" class=\"dotborderlg\">Order Code:&nbsp; </td>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;".$OrderCode."</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td height=\"10\" class=\"dotborderlg\">&nbsp;Stock:</td>\n <td class=\"dotborderlg\" colspan=\"3\">&nbsp;".$StockImage."</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td height=\"10\" colspan=\"4\" align=\"right\" class=\"dotborderlg\"><a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."\">View</a> | ".$AddBasketLink."&nbsp;</td>\n </tr>\n";
		$CatListing = $CatListing." <tr>\n <td colspan=\"5\"><img src=\"../images/blank.gif\" width=\"2\" height=\"5\"></td>\n </tr>\n";
	  }

      $StartRecord = $OffSet + 1;
      $DisplayText = "Displaying Items <b>$StartRecord</b> to <b>$ResultCount</b> of <b>$DisplayLimit</b> Results to...";
      $CurrOffSet = $OffSet;
      $PrevLink = $OffSet - $DefProdOffset;
      $OffSet = $OffSet + $DefProdOffset;
      #$RNavLink = "$DisplayLimit/$ResultCount/$OffSet ";

      if ($OffSet > $DefProdOffset) { $RNavLink = $RNavLink."&laquo; <a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$PrevLink."\">Previous Page</a> "; } else { $RNavLink = $RNavLink."<font color=\"#999999\">&laquo; Previous Page </font>"; }
      $RNavLink = $RNavLink."| ";
      for ($a=0; $a <= 30; $a++) {
        $TestOffSet = $a * $DefProdOffset;
        $LinkLoop = $a + 1;
        if ($TestOffSet eq $CurrOffSet) { $RNavLink = $RNavLink."<b><u>$LinkLoop</u></b> \n"; }
        elsif ($TestOffSet < $ProdCount) { $RNavLink = $RNavLink."<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$TestOffSet."\">$LinkLoop</a> \n"; }
      }
      $RNavLink = $RNavLink."| ";
      if ($OffSet < $ProdCount) { $RNavLink = $RNavLink." <a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$OffSet."\">Next Page</a> &raquo;"; } else { $RNavLink = $RNavLink." <font color=\"#999999\">Next Page &raquo;</font>"; }
	}
	$page = "category_sview";
  }
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------

#sub fetch_products_listing {

 # $sql_statement = "SELECT MfCode,MfName FROM brand_base ORDER BY MfName;";
  #$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  #@arr = $sth->fetchrow;
  #($MfCode,$MfName) = @arr;
  #$BrandAlpha = $BrandAlpha."&#149; <


#<tr>
 # <td class="dotborderlg">&nbsp;</td>
  #<td nowrap class="dotborderlg">&nbsp;</td>
#</tr>



#}
#--------------------------------------------------------------------------------------------------------------

sub fetch_basket_page {
  $sql_statement = "SELECT LockFlag FROM user_session WHERE SessionId = '$uid';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $LockFlag = @arr[0];

  if ($step eq "add") {
	$OrderQty = "1";
	$sql_statement = "SELECT * FROM prod_base WHERE ProdId = '$ProdId';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($XProdId, $OrderCode, $MfId, $XLevel1, $XLevel2, $XLevel3, $Model, $ProdName, $ProdSize, $RetailPrice, $MarkupPrice, $CostPrice, $DelCharge, $ProdImage, $ProdNotes, $ProdDate, $AddUser, $FeatureSumm, $ExtraCost, $PackUnit, $StockLevel, $ProdWeight, $MinOrder, $FeatureText, $FeatureList, $ExCostType, $SupplyName, $ExtraSize) = @arr;
	$sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$ProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$TestCnt = @arr[0];
	if ($LockFlag eq "1") { $AlertPrompt = "Your Shopping Basket has been locked by a pending order process!\\n\\nPlease complete the pending order process before attempting to add more items to your basket!\\n\\nClick the shopping basket link for details"; &fetch_product_page; }
	if ($TestCnt == 0) {	
	  $sql_statement = "INSERT INTO shopping_basket VALUES ('','$DateNow','$uid','1','$CLevel1','$CLevel2','$CLevel3','$ProdId','$OrderCode','$OrderOption','$OrderSuffix','$ProdName','$OrderQty','$RetailPrice','$ProdWeight','$DelCharge','$DeliverOption','$ExtraSize','1');";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  $AlertPrompt = "Added '$OrderCode : $ProdName' to your shopping basket!\\n\\nClick the 'Shopping Basket' link for details!";
	}
	else { $AlertPrompt = "You have already Added '$OrderCode : $ProdName' to your shopping basket!\\n\\nClick the 'Shopping Basket' link for details!"; }
	if ($info{'rt'} eq "view") { $step = "link"; &fetch_search_page; }
	if ($info{'rt'} eq "cview") { &fetch_category_page; }
	if ($info{'rt'} eq "pd") { $step = "view"; &fetch_brand_page; }
	if ($info{'rt'} eq "home") { &fetch_home_page; }
	if ($info{'rt'} eq "spec") { $step = "link"; &fetch_specials_page; }
	if ($info{'rt'} eq "search") { $step = "link"; &fetch_search_page; }
  
	&fetch_brand_page;
  }
  if ($step eq "delete") {
	if ($LockFlag eq "1") { $AlertPrompt = "Your Shopping Basket has been locked by a pending order process!\\n\\nPlease complete the pending order process before attempting to add more items to your basket!"; }
    else {
	  $sql_statement = "UPDATE shopping_basket SET StatFlag = '0' WHERE SessionId = '$uid' AND BasketId = '$BasketId';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	}
  }  
  if ($step eq "clear") {
	if ($LockFlag eq "1") { $AlertPrompt = "Your Shopping Basket has been locked by a pending order process!\\n\\nPlease complete the pending order process before attempting to add more items to your basket!"; }
    else {
	  $sql_statement = "UPDATE shopping_basket SET StatFlag = '0' WHERE SessionId = '$uid';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	}
  }  
  if ($step eq "update") {
    if ($LockFlag eq "1") { $AlertPrompt = "Your Shopping Basket has been locked by a pending order process!\\n\\nPlease complete the pending order process before attempting to add more items to your basket!"; }
    else {
	  $sql_statement = "SELECT BasketId FROM shopping_basket WHERE SessionId = '$uid' AND StatFlag != '0';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  while (@arr = $sth->fetchrow) {
	    $BasketId = @arr[0];
	    push(@blist,$BasketId);
	  }
	  foreach $BasketId(@blist) {
	    $FormField = "Qty_".$BasketId;
	    $OrderQty = $form{$FormField};
	    $OrderQty =~ tr/0-9/ /cs;
	    $OrderQty =~ s/ //g;
	    if (($OrderQty > 0) && ($OrderQty < 9999)) {
	    	$sql_statement = "UPDATE shopping_basket SET OrderQty = '$OrderQty' WHERE SessionId = '$uid' AND BasketId = '$BasketId';";
		  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
		}
	  }
	}
  }

  &tally_basket_items;

  if ($BasketCount eq "0") {
	$BasketListing = $BasketListing."<tr><td colspan=\"7\" bgcolor=\"#FFFFFF\" class=\"dotborderdesc\" align=\"center\"><b>Your Shopping Basket is empty!</b></td></tr>\n";
	$FixedDelCharge = "0.00";
  }

  $BasketSubTotal = sprintf("%.2f",$BasketSubTotal);
  $BasketVatTotal = $VatRate * $BasketSubTotal;
  $BasketVatTotal = sprintf("%.2f",$BasketVatTotal);
  $BasketAbsTotal = $BasketSubTotal + $BasketVatTotal + $FixedDelCharge;
  $BasketAbsTotal = sprintf("%.2f",$BasketAbsTotal);

  if ($CLevel1 ne "") { $SetBackLink = "<a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&fs=".$OffSet."\"><img src=\"../images/arrow_l.gif\" width=\"7\" height=\"7\" hspace=\"3\" align=\"absmiddle\" border=\"0\">Go back to Catalogue</a>"; }

  $page = "basket_view";
  $PageTitle = "Your Shopping Basket";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------
sub fetch_order_page {

  $BuyerId = $info{'byd'};
  $TransactId = $form{'LITE_TRANSACTIONINDEX'};
  $LogRefNr = $form{'ECOM_CONSUMERORDERID'};
  $MerchantReference = $uid;
  $ReceiptURL = $form{'LITE_WEBSITE_SUCCESSFUL_URL'};
  $TransactionAmount = $form{'LITE_ORDER_AMOUNT'};
  $TransactionType = $form{'ECOM_PAYMENT_CARD_TYPE'};
  $TransactionResult = $form{'LITE_PAYMENT_CARD_STATUS'};
  $TransactionErrorResponse = $form{'LITE_RESULT_DESCRIPTION'};
  $SafePayRefNr = $form{'ECOM_CONSUMERORDERID'};
  $BankRefNr = $form{'LITE_BANKREFERENCE'};
  $LiveTransaction = $form{'LITE_MERCHANT_APPLICATIONID'};
  $SafeTrack = $form{'LITE_MERCHANT_APPLICATIONID'};
  $BuyerCreditCardNr = $form{'ECOM_PAYMENT_CARD_NUMBER'};
  $StatusFlag = $form{'StatusFlag'};
  $TestType = $form{'TestType'};
  $FailURL = $form{'LITE_WEBSITE_FAIL_URL'};

  open (OUTPHILE, ">>$paylogphile");
  print OUTPHILE "RCPT:|".$DateNow."|".$current_user."|".$referer."|".$user_agent."|".$remote."|\n";
  print OUTPHILE "QS:|".$buffer."|\n------------\n";
  close(OUTPHILE);
  
  if ($step eq "rcpt") {

	$sql_statement = "INSERT INTO safe_shop VALUES ('','$BuyerId','$LogRefNr','$MerchantReference','$ReceiptURL','$TransactionAmount','$TransactionType','$TransactionResult','$TransactionErrorResponse','$SafePayRefNr','$BankRefNr','$LiveTransaction','$SafeTrack','$BuyerCreditCardNr','$TimeStamp','1');";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	$page = "checkout_success";
	&tally_basket_items;

  $sql_statement = "SELECT * FROM order_main WHERE BuyerId = '$BuyerId' AND SessionId = '$uid';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
  #-
  ($OrderId, $OrderStat, $PayOption, $BuyerId, $SessionId, $TimeStamp, $OrderSub, $OrderVat, $OrderDel, $OrderInsure, $OrderTotal, $OrderWeight, $OptionDel, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $DeliverNote, $InvoiceNum, $SubmitIP, $TransactId, $WayBillNumber, $DeliverDate, $AdminComment) = @arr;
	
	if ($OrderId eq "") { &system_error("Invalid Order Info!"); }
	else {
	  $sql_statement = "SELECT InvoiceNum FROM order_main WHERE BuyerId = '$BuyerId' AND SessionId = '$uid' AND OrderTotal = '$BasketAbsTotal';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $InvoiceNumber = @arr[0];
    #if ($InvoiceNumber < 1) {
      #&generate_invoice_number;
      &tally_order_items;
      $sql_statement = "SELECT TransactId FROM safe_shop WHERE BuyerId = '$BuyerId' AND MerchantReference = '$MerchantReference' AND SafePayRefNr = '$SafePayRefNr' ORDER BY TransactId DESC LIMIT 0,1;";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      $TestString = $sql_statement;
      $TransactId = @arr[0];	
      $sql_statement = "UPDATE order_main SET InvoiceNum = '$InvoiceNumber',OrderStat = '1',SubmitIP = '$current_user',TransactId = '$TransactId' WHERE BuyerId = '$BuyerId' AND SessionId = '$uid' AND OrderTotal = '$BasketAbsTotal';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $sql_statement = "UPDATE shopping_basket SET BlockFlag = '0' WHERE SessionId = '$uid';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $PayOption = "CC";
      $sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      ($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $SurName, $DateOfBirth, $TelAreaCode, $Telephone, $FaxAreaCode, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostalCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DelDayFrom, $DelDayTo, $VoucherCode) = @arr;
      &send_order_notification;
      $sql_statement = "UPDATE shopping_basket SET StatFlag = '0' WHERE SessionId = '$uid';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      $ForceInSecure = "1";
      $PageTitle = "Transaction Successful!";

	  #}
	  $UidClear = "2";
	}
  }
  if (($step eq "fail") || ($step eq "again") || ($step eq "error")) {
    $BuyerId = $info{'byd'};
    $sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId' LIMIT 0,1;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $Surname, $DateOfBirth, $TelAreaCode, $Telephone, $FaxArea, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $VoucherCode) = @arr;
    ($BirthYear,$BirthMonth,$BirthDay) = split(/\-/,$DateOfBirth);
    &tally_basket_items;
    $sql_statement = "SELECT OrderId,InvoiceNum FROM order_main WHERE SessionId = '$uid' AND OrderTotal = '$BasketAbsTotal';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($OrderId,$InvoiceNumber) = @arr;
    $UidClear = "";
    $PageTitle = "Transaction Failed";
    $page = "checkout_failure";
  }
#----
  if ($step eq "test") {
	$MerchantReference = $form{'MerchantReferenceNumber'};
	if ($TestType eq "V") {
	  $TransactionResult = "Successfull";
	  $page = "test_response_pass";
	
	}
	else {
	  $ReceiptURL = $FailURL;
	  $TransactionResult = "Failed";
	  $TransactionErrorResponse = "Insufficient Funds";
	  $page = "test_response_fail";
	  
	}
  }
#----
  
  #$page = "test_response";
  &display_page_requested;
}

sub tally_order_items {
  $sql_statement = "SELECT * FROM order_items WHERE OrderId = '$OrderId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
	($ItemId, $BuyerId, $OrderId, $TimeStamp, $Level1, $Level2, $Level3, $ProdId, $OrderCode, $ProdName, $OrderQty, $OrderPrice, $OrderWeight, $DelCharge, $ItemFlag) = @arr;
	$ItemTotal = $OrderPrice * $OrderQty;
	$ItemTotal = sprintf("%.2f",$ItemTotal);
	$InvoiceString = $InvoiceString."<tr>\n <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\">&nbsp;$OrderCode</td>\n";
	$InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\">&nbsp;$ProdName</td>\n";
	$InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"center\">$OrderQty</td>\n";
	$InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"right\">$OrderPrice&nbsp;</td>\n";
	$InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"right\">$ItemTotal&nbsp;</td>\n</tr>\n";
  }
  $InvoiceString = $InvoiceString."<tr>\n <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\">&nbsp;</td>\n";
  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\">&nbsp;</td>\n";
  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"center\">&nbsp;</td>\n";
  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"right\">&nbsp;</td>\n";
  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"right\">&nbsp;</td>\n</tr>\n";

  
  
}

#--------------------------------------------------------------------------------------------------------------

sub fetch_checkout_page {
  $sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE SessionId = '$uid' AND StatFlag != '0';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $TestCnt = @arr[0];
  if ($TestCnt == 0) {
    $AlertPrompt = "Your Shopping basket is empty!\\n\\nThe function you requested is not available. Please place the items you wish to purchase into your shopping basket before proceeding.";
    $step = "view";
    &fetch_basket_page;
  }
  &create_year_listing;
  &parse_user_detailform;
  
  if ($func eq "force") {
    $func = "checkout";
    $step = "iveri";
    #$page = "checkout_secure";
    #$PageTitle = "Secure Payment";
    #&display_page_requested;    
  }

  if ($FormTime eq "") { $FormTime = time; }

  if ($step eq "edsave") {
    $BuyerId = $info{'byd'};
	if ($BannedNumber eq "1") {
    $AlertPrompt = "We're sorry! We do not accept cellular telephone numbers in your contact details!\\nPlease enter your landline number!";
	  $page = "basket_edit";
    $PageTitle = "Edit your Contact Details";
	  &display_page_requested;
	}
	if ($PassWord ne "") {
	  $sql_statement = "UPDATE buyer_base SET MailAddy = '$MailAddy',PassWord = '$PassWord',Title = '$Title',FirstName = '$FirstName',SurName = '$Surname',DateOfBirth = '$DateOfBirth',TelAreaCode = '$TelAreaCode',Telephone = '$Telephone',FaxAreaCode = '$FaxArea',FaxNum = '$FaxNum',Company = '$Company',DeliveryOne = '$DeliveryOne',DeliveryTwo = '$DeliveryTwo',DeliveryThree = '$DeliveryThree',CityTown = '$CityTown',Province = '$Province',PostalCode = '$PostCode',VoucherCode = '$VoucherCode' WHERE BuyerId = '$BuyerId';";
	  $AlertPrompt = "Your Password has changed! Please read your email for details";   
	}
	else { $sql_statement = "UPDATE buyer_base SET MailAddy = '$MailAddy',Title = '$Title',FirstName = '$FirstName',SurName = '$Surname',DateOfBirth = '$DateOfBirth',TelAreaCode = '$TelAreaCode',Telephone = '$Telephone',FaxAreaCode = '$FaxArea',FaxNum = '$FaxNum',Company = '$Company',DeliveryOne = '$DeliveryOne',DeliveryTwo = '$DeliveryTwo',DeliveryThree = '$DeliveryThree',CityTown = '$CityTown',Province = '$Province',PostalCode = '$PostCode',VoucherCode = '$VoucherCode' WHERE BuyerId = '$BuyerId';"; }
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	$TestString = $sql_statement;
	sleep(1);
	#&send_update_email;
	$sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId' LIMIT 0,1;";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $Surname, $DateOfBirth, $TelAreaCode, $Telephone, $FaxArea, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $VoucherCode) = @arr;
    ($BirthYear,$BirthMonth,$BirthDay) = split(/\-/,$DateOfBirth);
	$page = "checkout_login";
    $PageTitle = "Update Saved!";
  }
  if ($step eq "edit") {
    $BuyerId = $info{'byd'};
    $sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId' LIMIT 0,1;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $Surname, $DateOfBirth, $TelAreaCode, $Telephone, $FaxArea, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $VoucherCode) = @arr;
    ($BirthYear,$BirthMonth,$BirthDay) = split(/\-/,$DateOfBirth);
    $page = "basket_edit";
    $PageTitle = "Edit your Profile!";
  }

  if ($step eq "iveri") {
    $BuyerId = $info{'byd'};
    $sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId' LIMIT 0,1;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $Surname, $DateOfBirth, $TelAreaCode, $Telephone, $FaxArea, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $VoucherCode) = @arr;
    ($BirthYear,$BirthMonth,$BirthDay) = split(/\-/,$DateOfBirth);

    &tally_basket_items;
    $sql_statement = "SELECT OrderId,InvoiceNum FROM order_main WHERE SessionId = '$uid' AND OrderTotal = '$BasketAbsTotal';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($OrderId,$InvoiceNumber) = @arr;

    $page = "checkout_secure";
    $PageTitle = "iVeri Secure Checkout";
    &display_page_requested;
  }



  if ($step eq "login") {
	$sql_statement = "SELECT * FROM buyer_base WHERE MailAddy = '$MailAddy' AND PassWord = '$PassWord';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $Surname, $DateOfBirth, $TelAreaCode, $Telephone, $FaxArea, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $VoucherCode) = @arr;
	if ($BuyerId eq "") {
	  $AlertPrompt = "The Email address and/or Password you entered are not Valid!\\n\\nPlease try again!";
	  $FormName = "LoginForm";
	  $SetFocus = "MailAddy";
	  $step = "view";
	  &fetch_basket_page;
	}
    ($BirthYear,$BirthMonth,$BirthDay) = split(/\-/,$DateOfBirth);
	$page = "checkout_login";
    $PageTitle = "Welcome Back $FirstName!";

  }
  if ($step eq "nxagain") {
    $BuyerId = $info{'byd'};
	$sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId' LIMIT 0,1;";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $Surname, $DateOfBirth, $TelAreaCode, $Telephone, $FaxArea, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostCode, $Country, $PayOption, $DeliverNote, $DeliverFrom, $DeliverTo, $DeldayFrom, $DeldayTo, $VoucherCode) = @arr;
	$page = "checkout_chkorder";
    $PageTitle = "Confirm delivery options";
    if ($PayOption eq "TX") { $PayOption2 = " checked"; $PayOptionFull = "Bank Transfer"; } else { $PayOption1 = " checked"; $PayOptionFull = "Credit Card"; }
  }

  if ($step eq "reg") {
    $page = "basket_register";
    $PageTitle = "Step 1 : Register as a Buyer";
  }
  if ($step eq "saverg") {
	$sql_statement = "SELECT COUNT(*) FROM buyer_base WHERE MailAddy = '$MailAddy';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$TestCnt = @arr[0];
	if ($TestCnt > 0) {
    $AlertPrompt = "A user has already registered using the email address '$MailAddy'!\\n\\nOnly one registration is allowed per email address.";
	  $page = "basket_register";
    $PageTitle = "Step 1 : Register as a Buyer";
	}
	elsif ($BannedNumber eq "1") {
    $AlertPrompt = "We're sorry! We do not accept cellular telephone numbers in your contact details!\\nPlease enter your landline number!";
	  $page = "basket_register";
    $PageTitle = "Step 1 : Register as a Buyer";
	  &display_page_requested;
	}
	else {
	  $page = "checkout_confirm";
    $PageTitle = "Step 2 : Confirm your Registration Details";
	}
  }
  if ($step eq "conf") {
    $sql_statement = "UPDATE user_session SET LockFlag = '1' WHERE SessionId = '$uid';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	$sql_statement = "SELECT BuyerId FROM buyer_base WHERE MailAddy = '$MailAddy' AND SessionId = '$uid';";
	$TestString = $sql_statement;
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$BuyerId = @arr[0];
	if ($BuyerId eq "") {
	  $Country = "ZA"; ##### --------
	  $sql_statement = "INSERT INTO buyer_base VALUES ('','1','$uid','$TimeStamp','$MailAddy','$PassWord','$Title','$FirstName','$Surname','$DateOfBirth','$TelAreaCode','$Telephone','$FaxArea','$FaxNum','$Company','$DeliveryOne','$DeliveryTwo','$DeliveryThree','$CityTown','$Province','$PostCode','$Country','$PayOption','$PayNotes','0','0','','','$VoucherCode');";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  &send_welcome_email;
	  sleep(1);
	  $sql_statement = "SELECT BuyerId FROM buyer_base WHERE MailAddy = '$MailAddy' AND SessionId = '$uid';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $BuyerId = @arr[0];
	}	
    $page = "checkout_order";
    $PageTitle = "Step 3 : Update your delivery preferences";
  }
  if ($step eq "last") {
    
	$page = "checkout_last";
    $PageTitle = "Step 4 : Confirm your Order";
  }
  if ($step eq "save") {
    if ($PayOption eq "TX") { $page = "checkout_transfer"; $PendFlag = '1'; $PageTitle = "Order Confirmed!"; }
    else { $page = "checkout_credit"; $PendFlag = '0'; $PageTitle = "Step 4 : Get Ready to SafeShop"; }
    &tally_basket_items;
    $sql_statement = "SELECT OrderId,InvoiceNum FROM order_main WHERE SessionId = '$uid' AND OrderTotal = '$BasketAbsTotal';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($OrderId,$InvoiceNumber) = @arr;
    
	if ($OrderId eq "") {	
	  #if ($PayOption eq "TX") { &generate_invoice_number; }
    &generate_invoice_number;
	  &generate_printer_cid;
	  $sql_statement = "INSERT INTO order_main VALUES ('','$PendFlag','$PayOption','$BuyerId','$uid','$TimeStamp','$BasketSubTotal','$BasketVatTotal','$BasketDelTotal','$InsureCharge','$BasketAbsTotal','$WeightTotal','$DeliverOption','$DeliverFrom','$DeliverTo','$DeldayFrom','$DeldayTo','$DeliverNote','$InvoiceNumber','$current_user','','','','','$PrintCid');";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  $TestString = $sql_statement;
	  sleep(1);
	  $sql_statement = "SELECT OrderId FROM order_main WHERE SessionId = '$uid' AND OrderTotal = '$BasketAbsTotal';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  @arr = $sth->fetchrow;
	  $OrderId = @arr[0];
	  foreach $BkString(@bkstring) {
	    ($XLevel1,$XLevel2,$XLevel3,$XProdId,$OrderCode,$ProdName,$OrderQty,$OrderPrice,$OrderWeight,$DelCharge) = split(/\|/,$BkString);
	    $sql_statement = "INSERT INTO order_items VALUES ('','$BuyerId','$OrderId','$TimeStamp','$XLevel1','$XLevel2','$XLevel3','$XProdId','$OrderCode','$ProdName','$OrderQty','$OrderPrice','$OrderWeight','$DelCharge','$PendFlag');";
	    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  }
	  $sql_statement = "UPDATE buyer_base SET DeliverFrom = '$DeliverFrom',DeliverTo = '$DeliverTo',DeldayFrom = '$DeldayFrom',DeldayTo = '$DeldayTo',PayNotes = '$DeliverNote',PayOption = '$PayOption' WHERE BuyerId = '$BuyerId';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  if ($PayOption eq "TX") {
      $sql_statement = "SELECT * FROM buyer_base WHERE BuyerId = '$BuyerId';";
      $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
      @arr = $sth->fetchrow;
      ($BuyerId, $BuyFlag, $SessionId, $SignDate, $MailAddy, $PassWord, $Title, $FirstName, $SurName, $DateOfBirth, $TelAreaCode, $Telephone, $FaxAreaCode, $FaxNum, $Company, $DeliveryOne, $DeliveryTwo, $DeliveryThree, $CityTown, $Province, $PostalCode, $Country, $PayOption, $PayNotes, $DeliverFrom, $DeliverTo, $DelDayFrom, $DelDayTo, $VoucherCode) = @arr;
      &send_order_notification;
	  }
	}  
	if ($PayOption eq "TX") {
	  $sql_statement = "UPDATE shopping_basket SET BlockFlag = '0' WHERE SessionId = '$uid';";
	  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	  $UidClear = "2";
	}
  }

  if ($step ne "save") { &tally_basket_items; }
  &display_page_requested;
}
sub generate_printer_cid {
  for ($a=0; $a <= 2500; $a++) {
  	$rval = rand(74);
  	$rval = $rval + 48;
  	$rval = sprintf("%.0f", $rval);
  	$rval = chr($rval);
  	$PrintCid = $PrintCid.$rval;
  	$PrintCid =~ tr/A-Za-z0-9/ /cs;
  	$PrintCid =~ s/ //g;
  	if (length($PrintCid) > 12) { return; }
  }
}

sub generate_invoice_number {
  $LockTime = time;
  $CheckTime = $LockTime + 30;
  while (-e $lockphile) {
	$LockTime = time;
	if ($LockTime > $CheckTime) { &system_error("IV_LOCKFILE_ERROR"); }
	sleep(1);
  }
  open (OUTPHILE, ">$lockphile");
  print OUTPHILE "xxx";
  if ($PayOption eq "TX") { $GetIv = "ProForma"; } else { $GetIv = "InvoiceNum"; }
  $sql_statement = "SELECT ".$GetIv." FROM track_counter WHERE TrkId = '1' LIMIT 0,1;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $InvoiceNumber = @arr[0];
  $InvoiceNumber++;
  $sql_statement = "UPDATE track_counter SET ".$GetIv." = '$InvoiceNumber' WHERE TrkId = '1';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  close(OUTPHILE);
  chmod(0777,$lockphile);
  unlink $lockphile;

}

sub tally_basket_items {
  $BasketCount = "0";
  @bkstring = ();
  $sql_statement = "SELECT * FROM shopping_basket WHERE SessionId = '$uid' AND StatFlag != '0';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
  ($BasketId, $SessionDate, $SessionId, $StatFlag, $XLevel1, $XLevel2, $XLevel3, $XProdId, $OrderCode, $OrderOption, $OrderSuffix, $ProdName, $OrderQty, $OrderPrice, $OrderWeight, $DelCharge, $ShipRegion, $ExtraSize, $BlockFlag) = @arr;
  $BasketCount++;
	$ItemTotal = $OrderPrice * $OrderQty;
	$ItemTotal = sprintf("%.2f",$ItemTotal);
	$BasketSubTotal = $BasketSubTotal + $ItemTotal;
	$BasketString = "$XLevel1|$XLevel2|$XLevel3|$XProdId|$OrderCode|$ProdName|$OrderQty|$OrderPrice|$OrderWeight|$DelCharge";
	#$TestString = $TestString.$BasketString."\n";
	$PrintString = $PrintString."ID#:\t\t$XProdId\nOrderCode:\t$OrderCode\nDescription:\t$ProdName\nQuantity:\t$OrderQty\nPrice:\t\t$OrderPrice\n\n";
	push (@bkstring,$BasketString);
	$BasketListing = $BasketListing."<!--$BasketCount:$BasketId:$XProdId-->\n<tr>\n";
    $BasketListing = $BasketListing." <td class=\"basketitem\">&nbsp;".$BasketCount.".</td>\n";
	  if (length($ProdName) > 36) {
      &shorten_text_string("$ProdName|36");
      $ProdName = $ShortString."...";
    }

	if (($step eq "last") || ($step eq "save") || ($step eq "iveri") || ($step eq "error") || ($step eq "fail") || ($step eq "again")) {
	  $BasketListing = $BasketListing." <td align=\"center\" class=\"basketitem\">&nbsp;</td>\n";
    $BasketListing = $BasketListing." <td class=\"basketitem\">&nbsp;".$OrderCode."</td>\n";
    $BasketListing = $BasketListing." <td class=\"basketitem\">&nbsp;".$ProdName."</td>\n";
    $BasketListing = $BasketListing." <td align=\"right\" class=\"basketitem\">".$OrderPrice."&nbsp;</td>\n";
    $BasketListing = $BasketListing." <td align=\"center\" class=\"basketitem\">".$OrderQty."</td>\n";	  
	  $InvoiceString = $InvoiceString."<tr>\n <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\">&nbsp;$OrderCode</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\">&nbsp;$ProdName</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"center\">$OrderQty</td>\n";
	  $InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"right\">$OrderPrice&nbsp;</td>\n";
    
    $IveriCount++;
    $IveriAmount = $OrderPrice * 100;
    $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Product_".$IveriCount."\" name=\"Lite_Order_LineItems_Product_".$IveriCount."\" value=\"".$ProdName."\">\n";
    $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Quantity_".$IveriCount."\" name=\"Lite_Order_LineItems_Quantity_".$IveriCount."\" value=\"".$OrderQty."\">\n";
    $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Amount_".$IveriCount."\" name=\"Lite_Order_LineItems_Amount_".$IveriCount."\" value=\"".$IveriAmount."\">\n";

    
    
	}
	else {
    $BasketListing = $BasketListing." <td align=\"center\" class=\"basketitem\"><a href=\"javascript:ClearBasketItem('".$BasketId."','".$CLevel1."','".$CLevel2."','".$CLevel3."','".$uid."','".$OffSet."');\"><img src=\"../images/cross_box.gif\" width=\"10\" height=\"9\" border=\"0\" alt=\"Remove $OrderCode from basket...\"></a></td>\n";
      $BasketListing = $BasketListing." <td class=\"basketitem\">&nbsp;".$OrderCode."</td>\n";
      $BasketListing = $BasketListing." <td class=\"basketitem\">&nbsp;<a href=\"../cgi-bin/index.pl?fn=spbrand&mct=".$XLevel1."&sct=".$XLevel2."&pct=0&fs=".$OffSet."&st=view&pid=$XProdId\">".$ProdName."</a></td>\n";
      $BasketListing = $BasketListing." <td align=\"right\" class=\"basketitem\">".$OrderPrice."&nbsp;</td>\n";
      $BasketListing = $BasketListing." <td align=\"center\" class=\"basketitem\"><input name=\"Qty_".$BasketId."\" type=\"text\" class=\"QtyInput\" value=\"".$OrderQty."\"></td>\n";	  
	}
    $BasketListing = $BasketListing." <td align=\"right\" bgcolor=\"#FFFFEE\" class=\"dotborderlg\">".$ItemTotal."&nbsp;</td>\n";
    $BasketListing = $BasketListing."</tr>\n";
	$InvoiceString = $InvoiceString." <td class=\"dotborderlg\" bgcolor=\"#FFFFFF\" align=\"right\">$ItemTotal&nbsp;</td>\n</tr>\n";
  }
  $BasketSubTotal = sprintf("%.2f",$BasketSubTotal);
  $BasketVatTotal = $VatRate * $BasketSubTotal;
  $BasketDelTotal = $FixedDelCharge;
  $BasketVatTotal = sprintf("%.2f",$BasketVatTotal);
  $BasketAbsTotal = $BasketSubTotal + $BasketVatTotal + $FixedDelCharge;
  $BasketAbsTotal = sprintf("%.2f",$BasketAbsTotal);
  $BasketShopTotal = $BasketAbsTotal;
  $BasketShopTotal =~ s/\.//g;

  $IveriCount++;
  $IveriAmount = $BasketVatTotal * 100;
  $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Product_".$IveriCount."\" name=\"Lite_Order_LineItems_Product_".$IveriCount."\" value=\"VAT\">\n";
  $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Quantity_".$IveriCount."\" name=\"Lite_Order_LineItems_Quantity_".$IveriCount."\" value=\"1\">\n";
  $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Amount_".$IveriCount."\" name=\"Lite_Order_LineItems_Amount_".$IveriCount."\" value=\"".$IveriAmount."\">\n";
  $IveriCount++;
  $IveriAmount = $BasketDelTotal * 100;
  $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Product_".$IveriCount."\" name=\"Lite_Order_LineItems_Product_".$IveriCount."\" value=\"Delivery Charge\">\n";
  $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Quantity_".$IveriCount."\" name=\"Lite_Order_LineItems_Quantity_".$IveriCount."\" value=\"1\">\n";
  $IveriProdListing = $IveriProdListing."<input type=\"hidden\" id=\"Lite_Order_LineItems_Amount_".$IveriCount."\" name=\"Lite_Order_LineItems_Amount_".$IveriCount."\" value=\"".$IveriAmount."\">\n";

}

sub parse_user_detailform {
  $MailAddy = $form{'MailAddy'};
  $PassWord = $form{'PassWord'};
  $RepPass = $form{'RepPass'};
  $Title = $form{'Title'};
  $FirstName = $form{'FirstName'};
  $Surname = $form{'Surname'};
  $TelAreaCode = $form{'TelAreaCode'};
  $Telephone = $form{'Telephone'};
  $FaxArea = $form{'FaxArea'};
  $FaxNum = $form{'FaxNum'};
  $BirthYear = $form{'BirthYear'};
  $BirthMonth = $form{'BirthMonth'};
  $BirthDay = $form{'BirthDay'};
  $Company = $form{'Company'};
  $DeliveryOne = $form{'DeliveryOne'};
  $DeliveryTwo = $form{'DeliveryTwo'};
  $DeliveryThree = $form{'DeliveryThree'};
  $CityTown = $form{'CityTown'};
  $Province = $form{'Province'};
  $PostCode = $form{'PostCode'};
  $Country = $form{'Country'};
  $PayOption = $form{'PayOption'};
  $Comments = $form{'Comments'};
  $VoucherCode = $form{'VoucherCode'};
  if ($VoucherCode eq "") { $VoucherCode = "NONE"; }
  $VoucherCode =~ tr/a-z/A-Z/;

  $TelAreaCode =~ tr/0-9/ /cs;
  $TelAreaCode =~ s/ //g;
  $Telephone =~ tr/0-9/ /cs;
  $Telephone =~ s/ //g;
  $TestPhoneCell = $TelAreaCode.$Telephone;
  $TestPhoneCell = substr($TestPhoneCell,0,3);
  
  foreach $CellPrefix(@banned) {
	if ($TestPhoneCell eq $CellPrefix) { $BannedNumber = "1"; }
  }

  $DeliverFrom = $form{'DeliverFrom'};
  $DeliverTo = $form{'DeliverTo'};
  $DeliverNote = $form{'DeliverNote'};
  $DeldayFrom = $form{'DeldayFrom'};
  $DeldayTo = $form{'DeldayTo'};
  
  $MailAddy =~ tr/A-Z/a-z/;
  $Telephone =~ tr/0-9/ /cs;
  $Telephone =~ s/ //g;
  $FaxNum =~ tr/0-9/ /cs;
  $FaxNum =~ s/ //g;
  $Comments =~ s/\cM//g;
  $DeliverNote =~ s/\cM//g;
  $DeliverNote =~ s/\n/ /g;
  $DateOfBirth = $BirthYear."-".$BirthMonth."-".$BirthDay;
  $TestString = $DateOfBirth;
  if ($PayOption eq "TX") { $PayOption2 = " checked"; $PayOptionFull = "Bank Transfer"; } else { $PayOption1 = " checked"; $PayOptionFull = "Credit Card"; }
  if ($DeliverFrom eq "") { $DeliverFrom = "08:00:00"; $DeliverTo = "17:00:00"; }
  if ($DeldayFrom eq "") { $DeldayFrom = "Mon"; $DeldayTo = "Fri"; }
}

#--------------------------------------------------------------------------------------------------------------
sub send_order_notification {
  if ($PayOption eq "TX") { $MailTemplate = $mailroot."confirmtx.msg"; $MailSubject = "Your order details from www.Toner.co.za [PF $InvoiceNumber]"; }
  if ($PayOption eq "CC") { $MailTemplate = $mailroot."confirmcc.msg"; $MailSubject = "Your order details from www.Toner.co.za [$InvoiceNumber]"; }
  
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
$line =~ s/_BUYERID_/$BuyerId/g;
$line =~ s/_BUYER_ID_/$BuyerId/g;
$line =~ s/_MAILADDY_/$MailAddy/g;
$line =~ s/_PRFNUM_/$InvoiceNumber/g;
$line =~ s/_CMARK_/$CurrencyMark/g;
$line =~ s/_UID_/$uid/g;
$line =~ s/_FNAME_/$FirstName/g;
$line =~ s/_SNAME_/$SurName/g;
$line =~ s/_SAFEPAYREFNR_/$SafePayRefNr/g;
$line =~ s/_BANKREFNR_/$BankRefNr/g;
$line =~ s/_BASKETLIST_/$BasketListing/g;
$line =~ s/_INVOICE_STRING_/$InvoiceString/g;
  $line =~ s/_SBTT_/$BasketSubTotal/g;
  $line =~ s/_VBTT_/$BasketVatTotal/g;
  $line =~ s/_DCTT_/$BasketDelTotal/g;
  $line =~ s/_ABTT_/$BasketAbsTotal/g;
  $line =~ s/_ABTTX_/$BasketShopTotal/g;
$line =~ s/_ICTT_/$BasketCount/g;
$line =~ s/_CMARK_/$CurrencyMark/g;
$line =~ s/_VOUCHER_CODE_/$VoucherCode/g;
	$MailText = $MailText.$line;
  }
  $RecipMail = $MailAddy;
  &send_email_message;

  $MailTemplate = $mailroot."confirmorder.msg";
  $MailText = "";
  if ($PayOption eq "TX") {
	$MailSubject = "Order details from www.Toner.co.za [PF $InvoiceNumber]";
	$OrderIntroText = "The following order was placed on www.Toner.co.za using the Bank Transfer or Cash Payment Payment option:\n\n";
  }
  if ($PayOption eq "CC") {
	$MailSubject = "Order details from www.Toner.co.za [$InvoiceNumber]";
	$OrderIntroText = "The following order was placed on www.Toner.co.za using the Credit Card Payment option:\n";
  }
  $OrderOutroText = "<b>Tracking Info</b>:<br>Received from:\n\t$current_user\n<br>On Date:\n\t$DateNow<br>Session Id: $uid<br><br>";
  $OrderOutroText = $OrderOutroText."Please login to your administration panel or click the link below to print out the order form.<br><a href=\"".$SiteBaseURL."cgi-bin/invoice.pl?fn=print&byd=".$BuyerId."&inv=".$InvoiceNumber."\">Click to Print Invoice</a>";

  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
  $line =~ s/_ORDERINTRO_/$OrderIntroText/g;
  $line =~ s/_ORDEROUTRO_/$OrderOutroText/g;
  $line =~ s/_SBTT_/$BasketSubTotal/g;
  $line =~ s/_VBTT_/$BasketVatTotal/g;
  $line =~ s/_DCTT_/$BasketDelTotal/g;
  $line =~ s/_ABTT_/$BasketAbsTotal/g;
  $line =~ s/_ABTTX_/$BasketShopTotal/g;
$line =~ s/_ICTT_/$BasketCount/g;
$line =~ s/_CMARK_/$CurrencyMark/g;

  $line =~ s/_EMAIL_/$MailAddy/g;
  $line =~ s/_CTITLE_/$Title/g;
  $line =~ s/_FNAME_/$FirstName/g;
  $line =~ s/_SNAME_/$SurName/g;
  $line =~ s/_TAREA_/$TelAreaCode/g;
  $line =~ s/_TELEPHONE_/$Telephone/g;
  $line =~ s/_FAREA_/$FaxArea/g;
  $line =~ s/_FAX_/$FaxNum/g;
  $line =~ s/_COMPANY_/$Company/g;
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
$line =~ s/_INVDATE_/$DateNow/g;
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
$line =~ s/_SITEBASE_/$SiteBaseURL/g;
	$MailText = $MailText.$line;
  }

  $RecipMail = $SalesMail;
  &send_email_message; 
}


sub send_reminder_email {
  $MailTemplate = $mailroot."reminder.msg";
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
$line =~ s/_BUYERID_/$BuyerId/g;
$line =~ s/_MAILADDY_/$MailAddy/g;
$line =~ s/_PASSWORD_/$PassWord/g;
$line =~ s/_FIRSTNAME_/$FirstName/g;
	$MailText = $MailText.$line;
  }
  $RecipMail = $MailAddy;
  $MailSubject = "Your password reminder for www.Toner.co.za";
  &send_email_message;
}

sub send_welcome_email {
  $MailTemplate = $mailroot."welcome.msg";
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
$line =~ s/_BUYERID_/$BuyerId/g;
$line =~ s/_MAILADDY_/$MailAddy/g;
$line =~ s/_PASSWORD_/$PassWord/g;
$line =~ s/_FIRSTNAME_/$FirstName/g;
	$MailText = $MailText.$line;
  }
  $RecipMail = $MailAddy;
  $MailSubject = "Your registration on www.Toner.co.za";
  &send_email_message;
}

sub send_reseller_welcome {
  $MailTemplate = $mailroot."reseller_new.msg";
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
$line =~ s/_RES_ID_/$ResId/g;
$line =~ s/_EMAILADDRESS_/$EmailAddress/g;
$line =~ s/_PASSWORD_/$PassWord/g;
$line =~ s/_FIRSTNAME_/$FirstName/g;
$line =~ s/_ACTIVECODE_/$ActiveCode/g;
	$MailText = $MailText.$line;
  }
  $RecipMail = $EmailAddress;
  $MailSubject = "Your Reseller Account Activation on www.Toner.co.za";
  &send_email_message;
}
sub send_reseller_reminder {
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
  $MailSubject = "Your Reseller Account Password Reminder from www.Toner.co.za";
  &send_email_message;
}
sub send_affiliate_welcome {
  $MailTemplate = $mailroot."affiliate_new.msg";
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
    $line =~ s/_AFF_ID_/$AffId/g;
    $line =~ s/_EMAILADDRESS_/$EmailAddress/g;
    $line =~ s/_PASSWORD_/$PassWord/g;
    $line =~ s/_FIRSTNAME_/$FirstName/g;
    $line =~ s/_ACTIVECODE_/$ActiveCode/g;
  	$MailText = $MailText.$line;
  }
  $RecipMail = $EmailAddress;
  $MailSubject = "Your Affiliate Account Activation on www.Toner.co.za";
  &send_email_message;
}
sub send_affiliate_reminder {
  $MailTemplate = $mailroot."affiliate_reminder.msg";
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
  $MailSubject = "Your Affiliate Account Password Reminder from www.Toner.co.za";
  &send_email_message;
}
sub send_reseller_alert {
  $MailTemplate = $mailroot."reseller_alert.msg";
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
  $line =~ s/_DATE_NOW_/$DateNow/g;
  $line =~ s/_RESID_/$ResId/g;
  $line =~ s/_STATFLAG_/$StatFlag/g;
  $line =~ s/_SIGNDATE_/$SignDate/g;
  $line =~ s/_COMPANYNAME_/$CompanyName/g;
  $line =~ s/_COMPANYREG_/$CompanyReg/g;
  $line =~ s/_VATNUMBER_/$VatNumber/g;
  $line =~ s/_TITLE_/$Title/g;
  $line =~ s/_FIRSTNAME_/$FirstName/g;
  $line =~ s/_SURNAME_/$SurName/g;
  $line =~ s/_IDNUMBER_/$IdNumber/g;
  $line =~ s/_EMAILADDRESS_/$EmailAddress/g;
  $line =~ s/_TELAREA_/$TelArea/g;
  $line =~ s/_TELEPHONE_/$Telephone/g;
  $line =~ s/_FAXAREA_/$FaxArea/g;
  $line =~ s/_FAXNUM_/$FaxNum/g;
  $line =~ s/_MOBILE_/$Mobile/g;
  $line =~ s/_PHYSICALADDRESS_/$PhysicalAddress/g;
  $line =~ s/_POSTALADDRESS_/$PostalAddress/g;
  $line =~ s/_CITYTOWN_/$CityTown/g;
  $line =~ s/_PROVINCE_/$Province/g;
  $line =~ s/_COUNTRY_/$Country/g;
  $line =~ s/_WEBURL_/$WebURL/g;
  $line =~ s/_PASSWORD_/$PassWord/g;
  $line =~ s/_ACTIVECODE_/$ActiveCode/g;
  $line =~ s/_SESSIONID_/$SessionId/g;
  $line =~ s/_BUSINESSDESCRIPT_/$BusinessDescript/g;
  	$MailText = $MailText.$line;
  }
  $RecipMail = $SalesMail;
  #$RecipMail = "ninja\@w3b.co.za";
  $MailSubject = "New Reseller Account Application on www.Toner.co.za";
  &send_email_message;
}
sub send_affiliate_alert {
  $MailTemplate = $mailroot."affiliate_alert.msg";
  open (INPHILE, "<$MailTemplate");
  @inmail = <INPHILE>;
  close(INPHILE);

  foreach $line(@inmail) {
  $line =~ s/_DATE_NOW_/$DateNow/g;
  $line =~ s/_AFF_ID_/$AffId/g;
  $line =~ s/_STATFLAG_/$StatFlag/g;
  $line =~ s/_SIGNDATE_/$SignDate/g;
  $line =~ s/_COMPANYNAME_/$CompanyName/g;
  $line =~ s/_TITLE_/$Title/g;
  $line =~ s/_FIRSTNAME_/$FirstName/g;
  $line =~ s/_SURNAME_/$SurName/g;
  $line =~ s/_IDNUMBER_/$IdNumber/g;
  $line =~ s/_EMAILADDRESS_/$EmailAddress/g;
  $line =~ s/_TELAREA_/$TelArea/g;
  $line =~ s/_TELEPHONE_/$Telephone/g;
  $line =~ s/_FAXAREA_/$FaxArea/g;
  $line =~ s/_FAXNUM_/$FaxNum/g;
  $line =~ s/_POSTALADDRESS_/$PostalAddress/g;
  $line =~ s/_CITYTOWN_/$CityTown/g;
  $line =~ s/_PROVINCE_/$Province/g;
  $line =~ s/_COUNTRY_/$Country/g;
  $line =~ s/_WEBURL_/$WebURL/g;
  $line =~ s/_PASSWORD_/$PassWord/g;
  $line =~ s/_ACTIVECODE_/$ActiveCode/g;
  $line =~ s/_SESSIONID_/$SessionId/g;
  $line =~ s/_SITEDESCRIPT_/$SiteDescript/g;
  	$MailText = $MailText.$line;
  }
  $RecipMail = $SalesMail;
  #$RecipMail = "ninja\@w3b.co.za";
  $MailSubject = "New Affiliate Account Application on www.Toner.co.za";
  &send_email_message;
}

sub send_email_message {
  ($RecipMail,$junk) = split(/\n/,$RecipMail);
  $RecipMail =~ tr/a-zA-Z0-9\.\-\@\_/ /cs;
  $RecipMail =~ s/ //gi;
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
sub fetch_legal_page {
  $page = "static_legal";
  $PageTitle = "Terms and Conditions";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------
sub fetch_faq_page {
  $page = "static_faq";
  $PageTitle = "Frequently Asked Questions";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------
sub fetch_contact_page {
  #&lookup_countrycodes;
  $page = "static_contact";
  $PageTitle = "Contact Us";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------
sub fetch_partner_page {
  $page = "static_partners";
  $PageTitle = "Partners";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------
sub fetch_support_page {
  $page = "static_support";
  $PageTitle = "Technical Support Requests";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------
sub fetch_service_page {
  $page = "static_service";
  $PageTitle = "Service Requests";
  &display_page_requested;
}

#--------------------------------------------------------------------------------------------------------------
sub fetch_vacancy_page {
  $page = "static_jobs";
  $PageTitle = "Jobs at $SiteTitle";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------
sub fetch_about_page {
  $page = "static_about";
  $PageTitle = "About Us";
  &display_page_requested;
}
sub fetch_links_page {
  if ($step eq "get") {
    $sql_statement = "SELECT LinkURL FROM content_links WHERE LinkId = '".$info{'i'}."';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    $LinkURL = @arr[0];
    $sql_statement = "UPDATE content_links SET ViewCount=ViewCount+1 WHERE LinkId = '".$info{'i'}."';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    
    print "Location: http://".$LinkURL."\nURI: http://".$LinkURL."\n\n\n" ;
    exit;
  }

  $sql_statement = "SELECT * FROM content_links WHERE StatFlag = '1' ORDER BY LinkName;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  while (@arr = $sth->fetchrow) {
    ($XLinkId,$XStatFlag,$XTimeStamp,$XLinkName,$XLinkURL,$ViewCount,$XLinkDescript) = @arr;
    #&convert_timestamp($XTimeStamp);
    $XLinkURL =~ s/http:\/\///gi;
    $TableListing = $TableListing."<tr>\n";
    $TableListing = $TableListing." <td width=\"5%\" valign=\"top\"><a href=\"http://".$XLinkURL."\" target=\"_blank\"><img src=\"../images/icon_link.gif\" alt=\"$XLinkName\" width=\"24\" height=\"24\" border=\"0\"></a></td>\n";
    $TableListing = $TableListing." <td valign=\"top\"><a href=\"http://".$XLinkURL."\" target=\"_blank\"><strong>$XLinkName</strong></a><br><img src=\"../images/blkline.gif\" width=\"480\" height=\"1\" vspace=\"2\"><br>$XLinkDescript<br>&nbsp;</td>\n";
    $TableListing = $TableListing."</tr>\n";
  }


  $page = "static_links";
  $PageTitle = "Useful Links";
  &display_page_requested;
}
#--------------------------------------------------------------------------------------------------------------

sub fetch_home_page {

$sql_statement = "SELECT COUNT(*) FROM prod_base;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
@arr = $sth->fetchrow;
$PrCount = @arr[0];

$sql_statement = "SELECT COUNT(*) FROM cat_base WHERE Level1 != '100';";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
@arr = $sth->fetchrow;
$CtCount = @arr[0];

$SiteSummary = "<b>$PrCount</b> Products in <b>$CtCount</b> Categories";

$SplitFlag = "0";
$sql_statement = "SELECT ProdId,ProdName,RetailPrice,OrderCode,Level1,Level2,FeatureSumm,MfId,ProdImage FROM prod_base WHERE SpecFlag = '1' ORDER BY ProdId DESC LIMIT 0,10;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
while (@arr = $sth->fetchrow) {
  ($SProdId,$SProdName,$SRetailPrice,$SOrderCode,$SLevel1,$SLevel2,$SFeatureSumm,$SBrandId,$SProdImage) = @arr;
  push(@fprods,"$SProdId|$SProdName|$SRetailPrice|$SOrderCode|$SLevel1|$SLevel2|$SFeatureSumm|$SBrandId|$SProdImage");
}
foreach $Temp(@fprods) {
  ($SProdId,$SProdName,$SRetailPrice,$SOrderCode,$SLevel1,$SLevel2,$SFeatureSumm,$SBrandId,$SProdImage) = split(/\|/,$Temp);
	$sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE ProdId = '$SProdId' AND SessionId = '$uid' AND StatFlag != '0';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
	@arr = $sth->fetchrow;
	$CheckBasket = @arr[0];
  if ($SRetailPrice < 1) { $SRetailTotal = "*P.O.A."; }
  else {		
	$SRetailTotal = $SRetailPrice * $VatRate;
	$SRetailTotal = $SRetailTotal + $SRetailPrice;
	$SRetailTotal = sprintf("%.2f",$SRetailTotal);
  }
  if ($SProdImage eq "") { $SProdImage = $SOrderCode.".jpg"; }
  $ImagePath = $ThumbNailPath.$SProdImage;
  if (-e $ImagePath) { $SetProdImage = $SProdImage; } else { $SProdImage = "none.gif"; }

  if (length($SFeatureSumm) > 80) {
    &shorten_text_string("$SFeatureSumm|80");
    $SFeatureSumm = $ShortString."...";
  }
	if ($CheckBasket == 0) { $BasketImage = "buy.gif"; $PreDescript = ""; }
	else { $BasketImage = "buy_in.gif";  $PreDescript = "This Item has been added to your <a href=\"../cgi-bin/index.pl?fn=basket&br=".$BrandId."&mct=".$CLevel1."&sct=".$CLevel2."&pct=0&st=view&pid=".$ProdId."&fs=".$OffSet."\">Shopping Basket</a>.<br>"; }

  $SpecialsHome = $SpecialsHome."<tr>\n <td width=\"10%\" rowspan=\"4\" valign=\"top\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$SBrandId."&mct=".$SLevel1."&sct=".$SLevel2."&pct=0&st=view&pid=".$SProdId."\"><img src=\"../user/thumbs/".$SProdImage."\" width=\"100\" border=\"0\" alt=\"View ".$SProdName."\"></a></td>\n";
  $SpecialsHome = $SpecialsHome." <td><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$SBrandId."&mct=".$SLevel1."&sct=".$SLevel2."&pct=0&st=view&pid=".$SProdId."\" class=\"HeadingLink\">$SProdName</a></td>\n</tr>\n";
  $SpecialsHome = $SpecialsHome."<tr>\n <td>$SFeatureSumm</td>\n</tr>\n";
  $SpecialsHome = $SpecialsHome."<tr>\n <td align=\"right\">Featured Price: <span class=\"PriceTag\">".$CurrencyMark." ".$SRetailTotal."</span></td>\n</tr>\n";
  $SpecialsHome = $SpecialsHome."<tr>\n <td align=\"right\" valign=\"bottom\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$SBrandId."&mct=".$SLevel1."&sct=".$SLevel2."&pct=0&st=view&pid=".$SProdId."\"><img src=\"../images/detail.gif\" width=\"71\" height=\"19\" hspace=\"3\" border=\"0\"></a><a href=\"../cgi-bin/index.pl?fn=basket&br=".$SBrandId."&mct=".$SLevel1."&sct=".$SLevel1."&pct=0&st=add&pid=".$SProdId."&rt=pd&fs=0\" title=\"Buy $SProdName\"><img src=\"../images/".$BasketImage."\" width=\"56\" height=\"19\" border=\"0\" alt=\"Buy $ProdTitle\"></a></td>\n</tr>\n";
  $SpecialsHome = $SpecialsHome."<tr>\n <td colspan=\"2\" valign=\"top\" class=\"SeperatorPane\"><img src=\"../images/blank.gif\" width=\"2\" height=\"6\"></td>\n</tr>\n";

  if ($SplitFlag eq "0") { $SpecialsHomeLeft = $SpecialsHomeLeft.$SpecialsHome; }
  if ($SplitFlag eq "1") { $SpecialsHomeRight = $SpecialsHomeRight.$SpecialsHome; }
  if ($SplitFlag eq "0") { $SplitFlag = "1"; } else { $SplitFlag = "0"; }
  $SpecialsHome = "";
}

$sql_statement = "SELECT ProdId,ProdName,RetailPrice,OrderCode,Level1,Level2,FeatureSumm,MfId,ProdImage FROM prod_base WHERE Level1 = '186' ORDER BY ProdId DESC LIMIT 0,2;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
while (@arr = $sth->fetchrow) {
  ($SProdId,$SProdName,$SRetailPrice,$SOrderCode,$SLevel1,$SLevel2,$SFeatureSumm,$SBrandId,$SProdImage) = @arr;
  if ($SRetailPrice < 1) { $SRetailTotal = "*P.O.A."; }
  else {		
  	$SRetailTotal = $SRetailPrice * $VatRate;
  	$SRetailTotal = $SRetailTotal + $SRetailPrice;
  	$SRetailTotal = sprintf("%.2f",$SRetailTotal);
  }
  if ($SProdImage eq "") { $SProdImage = $SOrderCode.".jpg"; }
  $ImagePath = $ThumbNailPath.$SProdImage;
  if (-e $ImagePath) { $SetProdImage = $SProdImage; } else { $SProdImage = "none.gif"; }

  if (length($SFeatureSumm) > 80) {
    &shorten_text_string("$SFeatureSumm|80");
    $SFeatureSumm = $ShortString."...";
  }
	$BasketImage = "buy.gif"; $PreDescript = "";

  $SpecialsTop = $SpecialsTop."<tr>\n <td width=\"10%\" rowspan=\"4\" valign=\"top\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$SBrandId."&mct=".$SLevel1."&sct=".$SLevel2."&pct=0&st=view&pid=".$SProdId."\"><img src=\"../user/thumbs/".$SProdImage."\" width=\"100\" border=\"0\" alt=\"View ".$SProdName."\"></a></td>\n";
  $SpecialsTop = $SpecialsTop." <td><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$SBrandId."&mct=".$SLevel1."&sct=".$SLevel2."&pct=0&st=view&pid=".$SProdId."\" class=\"HeadingLink\">$SProdName</a></td>\n</tr>\n";
  $SpecialsTop = $SpecialsTop."<tr>\n <td>$SFeatureSumm</td>\n</tr>\n";
  $SpecialsTop = $SpecialsTop."<tr>\n <td align=\"right\">Featured Price: <span class=\"PriceTag\">".$CurrencyMark." ".$SRetailTotal."</span></td>\n</tr>\n";
  $SpecialsTop = $SpecialsTop."<tr>\n <td align=\"right\" valign=\"bottom\"><a href=\"../cgi-bin/index.pl?fn=spbrand&br=".$SBrandId."&mct=".$SLevel1."&sct=".$SLevel2."&pct=0&st=view&pid=".$SProdId."\"><img src=\"../images/detail.gif\" width=\"71\" height=\"19\" hspace=\"3\" border=\"0\"></a><a href=\"../cgi-bin/index.pl?fn=basket&br=".$SBrandId."&mct=".$SLevel1."&sct=".$SLevel1."&pct=0&st=add&pid=".$SProdId."&rt=pd&fs=0\" title=\"Buy $SProdName\"><img src=\"../images/".$BasketImage."\" width=\"56\" height=\"19\" border=\"0\" alt=\"Buy $ProdTitle\"></a></td>\n</tr>\n";
  $SpecialsTop = $SpecialsTop."<tr>\n <td colspan=\"2\" valign=\"top\" class=\"SeperatorPane\"><img src=\"../images/blank.gif\" width=\"2\" height=\"6\"></td>\n</tr>\n";
}

$SpecialsHomeLeft = "<table width=\"100%\" border=\"0\" cellspacing=\"2\" cellpadding=\"0\">\n".$SpecialsHomeLeft."</table>\n"; 
$SpecialsHomeRight = "<table width=\"100%\" border=\"0\" cellspacing=\"2\" cellpadding=\"0\">\n".$SpecialsHomeRight."</table>\n"; 

$page = "static_home";
$PageTitle = "South Africa's largest supplier of consumables for almost every brand of copier, fax or printer around!";
&display_page_requested;
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

#--------------------------------------------------------------------------------------------------------------

sub summarise_special_offers {
  $sql_statement = "SELECT ProdId,ProdName,RetailPrice,OrderCode,Level1,Level2,FeatureSumm FROM prod_base WHERE SpecFlag = '1' AND RotateFlag = '0' LIMIT 0,1;";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($SProdId,$SProdName,$SRetailPrice,$SOrderCode,$SLevel1,$SLevel2,$SFeatureSumm) = @arr;

  if ($SProdId eq "") {
	$sql_statement = "UPDATE prod_base SET RotateFlag = '0' WHERE SpecFlag = '1';";
	$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    $sql_statement = "SELECT ProdId,ProdName,RetailPrice,OrderCode,Level1,Level2,FeatureSumm FROM prod_base WHERE SpecFlag = '1' AND RotateFlag = '0' LIMIT 0,1;";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($SProdId,$SProdName,$SRetailPrice,$SOrderCode,$SLevel1,$SLevel2,$SFeatureSumm) = @arr;
  }
  $sql_statement = "UPDATE prod_base SET RotateFlag = '1' WHERE ProdId = '$SProdId';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  if ($SRetailPrice < 1) { $SRetailTotal = "*P.O.A."; }
  else {		
	$SRetailTotal = $SRetailPrice * $VatRate;
	$SRetailTotal = $SRetailTotal + $SRetailPrice;
	$SRetailTotal = sprintf("%.2f",$SRetailTotal);
  }
  
  $ImagePath = $ThumbNailPath.$SOrderCode.".jpg";
  if (-e $ImagePath) { $SProdImage = $SOrderCode.".jpg"; } else { $SProdImage = "none.gif"; }
  $SpecialList = "<a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$SLevel1."&sct=".$SLevel2."&pct=0&st=view&pid=".$SProdId."\"><img src=\"../user/thumbs/".$SProdImage."\" width=\"100\" border=\"0\"></a><br><b>$SOrderCode</b><br><a href=\"../cgi-bin/index.pl?fn=spmain&mct=".$SLevel1."&sct=".$SLevel2."&pct=0&st=view&pid=".$SProdId."\">".$SProdName."</a><br>".$SFeatureSumm."<br>-------------<br>Now only <b>".$CurrencyMark." ".$SRetailTotal."</b><br>Including VAT";
  $SpecialList = "<table width=\"100%\" border=\"0\" cellspacing=\"1\" cellpadding=\"0\"><tr><td align=\"center\" class=\"dotborderspec\">".$SpecialList."</td></tr></table>\n"; 


}

#--------------------------------------------------------------------------------------------------------------

sub populate_list_menu {

$sql_statement = "SELECT Level1,CatName FROM cat_base ORDER BY CatName;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
while (@arr = $sth->fetchrow) {
  ($PLevel1,$PCatName) = @arr;
  if (($func eq "checkout") && ($step eq "iveri")) { $DomainRoot = "http://www.toner.co.za"; } else { $DomainRoot = ".."; }
  if ($SearchCat eq $PLevel1) { $SubcatListing = $SubcatListing."<a href=\"".$DomainRoot."/cgi-bin/index.pl?fn=cview&mct=".$PLevel1."&sct=100\" title=\"$PCatName\" class=\"MidLinks\">".$PCatName."</a><br>\n"; }
  else { $SubcatListing = $SubcatListing."<a href=\"".$DomainRoot."/cgi-bin/index.pl?fn=cview&mct=".$PLevel1."&sct=100\" title=\"$PCatName\" class=\"MidLinks\">".$PCatName."</a><br>\n"; }
	push(@catkeys,$PCatName);
}
$sql_statement = "SELECT MfCode,MfName FROM brand_base ORDER BY MfName;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
while (@arr = $sth->fetchrow) {
    ($PBrandId,$PBrandName) = @arr;
    if ($SearchBrand eq $PBrandId) { $BrandListing = $BrandListing."<option value=\"".$PBrandId."\" selected>".$PBrandName."</option>\n"; $SetCountryName = $CountryName; }
    else { $BrandListing = $BrandListing."<option value=\"".$PBrandId."\">".$PBrandName."</option>\n"; }
		push(@catkeys,$PBrandName);
}

}
#--------------------------------------------------------------------------------------------------------------

sub display_page_requested {

$getpage = $docroot.$page."\.html";
$getmenu = $docroot."product_menu.html";
if ($SearchModel eq "") { $SearchModel = "- Model or Cartridge Number -"; }
if ($SubcatListing eq "") { &populate_list_menu; }
#if ($BrandImage eq "") { $BrandImage = "default.gif"; }
#if (($func eq "home") || ($func eq "sprods") || ($func eq "spsearch")) { &populate_list_menu; }


if ($BasketCount eq "") {
  $sql_statement = "SELECT COUNT(*) FROM shopping_basket WHERE SessionId = '$uid' AND StatFlag != '0';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $BasketCount = @arr[0];
}
if ($BasketCount == 1) { $TopBaskCount = "$BasketCount item"; }
else { $TopBaskCount = "$BasketCount items"; $TopFlash = "flash"; }

$KeyWordMeta = $KeyWordMeta.",";
foreach $CatKey(@catkeys) { $KeyWordMeta = $KeyWordMeta.$CatKey.","; }
chop $KeyWordMeta;

if (($page ne "brand_view") && ($page ne "brand_eview")) {
  $sql_statement = "SELECT PageTitle,PageDescript,PageKeys FROM system_meta WHERE PageName = '$page';";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  ($PageTitle,$PageDescript,$PageKeys) = @arr;
  if ($PageTitle eq "") {
    $sql_statement = "SELECT PageTitle,PageDescript,PageKeys FROM system_meta WHERE PageName = 'default';";
    $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
    @arr = $sth->fetchrow;
    ($PageTitle,$PageDescript,$PageKeys) = @arr;
  }
}
$KeyWordMeta = $PageKeys;
$DescriptionMeta = $PageDescript;
$PageTitle =~ s/\"/\'/g;
$BannerFrame = "<iframe name=\"TopBannerWindo\" width=\"234\" height=\"60\" src=\"http://www.toner.co.za/cgi-bin/adrtt.pl?fn=get&pg=_PAGENAME_\" frameborder=\"0\" scrolling=\"no\"></iframe>";

if ($FirstVisit eq "") { push(@writecookie,"tonFirstVisit|$TimeStamp"); }

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

print "\n<!-- Designed and Powered by W3b.co.za -->\n";

if ($AlertPrompt ne "") { $AlertPrompt = "\nwindow.alert(\"".$AlertPrompt."\");"; }
if ($SetFocus ne "") { $SetFocus = "\ndocument.".$FormName.".".$SetFocus.".select();\ndocument.".$FormName.".".$SetFocus.".focus();"; }
if ($StatusMessage ne "") {
  ($StatusType,$StatusMessage) = split(/\|/,$StatusMessage);
  if ($StatusType eq "0") { $StatusMessage = "<tr><td colspan=\"2\" class=\"StatusOk\"><img src=\"../images/status_ok.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</td></tr>"; }
  if ($StatusType eq "1") { $StatusMessage = "<tr><td colspan=\"2\" class=\"StatusAlert\"><img src=\"../images/status_alert.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</td></tr>"; }
  if ($StatusType eq "2") { $StatusMessage = "<tr><td colspan=\"2\" class=\"StatusStop\"><img src=\"../images/status_stop.gif\" width=\"32\" height=\"32\" hspace=\"3\" vspace=\"3\" border=\"0\" align=\"left\">$StatusMessage</td></tr>"; }
}

open (INPHILE, "<$getmenu");
@indata=<INPHILE>;
close(INPHILE);

foreach $line(@indata) {
  $ProdMenu = $ProdMenu.$line;
}

open (INPHILE, "<$getpage");
@indata=<INPHILE>;
close(INPHILE);

foreach $line(@indata) {
  $WriteHtml = $WriteHtml.$line;
}

  $WriteHtml =~ s/_TABLELISTING_/$TableListing/g;
  $WriteHtml =~ s/_COPYRIGHT_/$CopyRightDate/g;
  $WriteHtml =~ s/_PRODUCT_MENU_/$ProdMenu/g;
  $WriteHtml =~ s/_PAGE_TITLE_/$PageTitle/g;
  $WriteHtml =~ s/_TBSK_/$TopBaskCount/g;
  $WriteHtml =~ s/_TFLX_/$TopFlash/g;
  $WriteHtml =~ s/_PROD_ID_/$ProdId/g;
  $WriteHtml =~ s/_BRAND_ID_/$BrandId/g;
  $WriteHtml =~ s/_KEYWORD_META_/$KeyWordMeta/g;
  $WriteHtml =~ s/_DESCRIPTION_META_/$DescriptionMeta/g;

  $WriteHtml =~ s/_ALERT_PROMPT_/$AlertPrompt/g;
  $WriteHtml =~ s/_STATMSG_/$StatusMessage/g;
  $WriteHtml =~ s/_SET_FOCUS_/$SetFocus/g;
  $WriteHtml =~ s/_UID_/$uid/g;
  $WriteHtml =~ s/_OFFSET_/$OffSet/g;
  $WriteHtml =~ s/_BACK_LINK_/$SetBackLink/g;
  $WriteHtml =~ s/_CAT_1_/$CLevel1/g;
  $WriteHtml =~ s/_CAT_2_/$CLevel2/g;
  $WriteHtml =~ s/_CAT_3_/$CLevel3/g;
  $WriteHtml =~ s/_FORMTIME_/$FormTime/g;
  $WriteHtml =~ s/_BUYER_ID_/$BuyerId/g;
  $WriteHtml =~ s/_CMARK_/$CurrencyMark/g;
  $WriteHtml =~ s/_PRODUCTCOUNT_/$SiteSummary/g;
  $WriteHtml =~ s/_BRANDLISTING_/$BrandListing/g;
  $WriteHtml =~ s/_SCATLISTING_/$SubcatListing/g;
  	
  $WriteHtml =~ s/_SPECIAL_OFFERS_/$SpecialList/g;
  $WriteHtml =~ s/_SPECIALSLIST_/$SpecialList/g;
  $WriteHtml =~ s/_SPECIALSLEFT_/$SpecialsHomeLeft/g;
  $WriteHtml =~ s/_SPECIALSRIGHT_/$SpecialsHomeRight/g;
  $WriteHtml =~ s/_SPECIALS_TOP_/$SpecialsTop/g;
  $WriteHtml =~ s/_SPECIAL_MAIN_/$SpecialMain/g;
  $WriteHtml =~ s/_DIS_LINK_/$DisLink/g;
  $WriteHtml =~ s/_CURR_/$CurrType/g;
  $WriteHtml =~ s/_CZAR_/$CurrZAR/g;
  $WriteHtml =~ s/_CEUR_/$CurrEUR/g;
  $WriteHtml =~ s/_CUSD_/$CurrUSD/g;
  $WriteHtml =~ s/_CGBP_/$CurrGBP/g;
  $WriteHtml =~ s/_RESERVED_/$ReservedText/g;
  $WriteHtml =~ s/_SUB_NAME_/$SubName/g;
  $WriteHtml =~ s/_SUB_EMAIL_/$SubEmail/g;
  $WriteHtml =~ s/_SITE_SUMMARY_/$SiteSummary/g;
  $WriteHtml =~ s/_MAIN_SPEC_/$MainSpec/g;
  $WriteHtml =~ s/_SIZE_WIDTH_/$globe_x/g;
  $WriteHtml =~ s/_SIZE_HEIGHT_/$globe_y/g;
  $WriteHtml =~ s/_COUNTRY_LISTING_/$CountryListing/g;

  $WriteHtml =~ s/_SESSIONCID_/$SessionCid/g;
  $WriteHtml =~ s/_ORDER_ID_/$OrderId/g;

	
if (($func eq "cview") || ($func eq "spmain") || ($func eq "basket") || ($func eq "spbrand") || ($func eq "spsearch") || ($func eq "special")) {
  $WriteHtml =~ s/_CATNAV_STRING_/$CatNavString/g;
  $WriteHtml =~ s/_CATDESCRIPT_/$CatDescript/g;
  $WriteHtml =~ s/_CAT_LISTING_/$CatListing/g;
  $WriteHtml =~ s/_TOP_CATNAME_/$TopCatName/g;
  $WriteHtml =~ s/_NAVLINK_/$RNavLink/g;
  $WriteHtml =~ s/_RESULTSTRING_/$ResultString/g;
  $WriteHtml =~ s/_SEARCHRULE_/$SearchRule/g;
  $WriteHtml =~ s/_SEARCHMODEL_/$SearchModel/g;

  $WriteHtml =~ s/_BRANDNAME_/$BrandName/g;
  $WriteHtml =~ s/_BRAND_NAME_/$BrandName/g;
  $WriteHtml =~ s/_BRAND_IMAGE_/$BrandImage/g;
  $WriteHtml =~ s/_ORDERCODE_/$OrderCode/g;
  $WriteHtml =~ s/_MFID_/$MfId/g;
  $WriteHtml =~ s/_MODEL_/$Model/g;
  $WriteHtml =~ s/_PRODNAME_/$ProdName/g;
  $WriteHtml =~ s/_PRODSIZE_/$ProdSize/g;
  $WriteHtml =~ s/_RETAILPRICE_/$RetailPrice/g;
  $WriteHtml =~ s/_MARKUPPRICE_/$MarkupPrice/g;
  $WriteHtml =~ s/_COSTPRICE_/$CostPrice/g;
  $WriteHtml =~ s/_DELCHARGE_/$DelCharge/g;
  $WriteHtml =~ s/_PROD_IMAGE_/$ProdImage/g;
  $WriteHtml =~ s/_PRODNOTES_/$ProdNotes/g;
  $WriteHtml =~ s/_PRODDATE_/$ProdDate/g;
  $WriteHtml =~ s/_ADDUSER_/$AddUser/g;
  $WriteHtml =~ s/_FEATURESUMM_/$FeatureSumm/g;
  $WriteHtml =~ s/_EXTRACOST_/$ExtraCost/g;
  $WriteHtml =~ s/_PACKUNIT_/$PackUnit/g;
  $WriteHtml =~ s/_STOCKIMAGE_/$StockImage/g;
  $WriteHtml =~ s/_PRODWEIGHT_/$ProdWeight/g;
  $WriteHtml =~ s/_MINORDER_/$MinOrder/g;
  $WriteHtml =~ s/_FEATURETEXT_/$FeatureText/g;
  $WriteHtml =~ s/_FEATURELIST_/$FeatureList/g;
  $WriteHtml =~ s/_EXCOSTTYPE_/$ExCostType/g;
  $WriteHtml =~ s/_BASKIMAGE_/$BasketImage/g;

}
if (($func eq "basket") || ($func eq "checkout") || ($func eq "order")) {
  $WriteHtml =~ s/_BASKET_LISTING_/$BasketListing/g;
  $WriteHtml =~ s/_SBTT_/$BasketSubTotal/g;
  $WriteHtml =~ s/_VBTT_/$BasketVatTotal/g;
  $WriteHtml =~ s/_DCTT_/$FixedDelCharge/g;
  $WriteHtml =~ s/_ABTT_/$BasketAbsTotal/g;
  $WriteHtml =~ s/_ABTTX_/$BasketShopTotal/g;
  $WriteHtml =~ s/_ICTT_/$BasketCount/g;
}
if (($func eq "checkout") || ($func eq "bform") || ($func eq "remind") || ($func eq "order")) {
  $WriteHtml =~ s/_EMAIL_/$MailAddy/g;
  $WriteHtml =~ s/_CTITLE_/$Title/g;
  $WriteHtml =~ s/_FNAME_/$FirstName/g;
  $WriteHtml =~ s/_SNAME_/$Surname/g;
  $WriteHtml =~ s/_TAREA_/$TelAreaCode/g;
  $WriteHtml =~ s/_TELEPHONE_/$Telephone/g;
  $WriteHtml =~ s/_FAREA_/$FaxArea/g;
  $WriteHtml =~ s/_FAX_/$FaxNum/g;
  $WriteHtml =~ s/_FORMTYPE_/$FormType/g;
}
if (($func eq "checkout") || ($func eq "order")) {
  $WriteHtml =~ s/_BIRTH_YEAR_/$BirthYear/g;
  $WriteHtml =~ s/_VOUCHER_CODE_/$VoucherCode/g;
  $WriteHtml =~ s/_YEAR_LIST_/$YearList/g;
  $WriteHtml =~ s/_BIRTH_MONTH_/$BirthMonth/g;
  $WriteHtml =~ s/_BIRTH_DAY_/$BirthDay/g;
  $WriteHtml =~ s/_COMPANY_/$Company/g;
  $WriteHtml =~ s/_DELIVERY_1_/$DeliveryOne/g;
  $WriteHtml =~ s/_DELIVERY_2_/$DeliveryTwo/g;
  $WriteHtml =~ s/_DELIVERY_3_/$DeliveryThree/g;
  $WriteHtml =~ s/_CITYTOWN_/$CityTown/g;
  $WriteHtml =~ s/_PROVINCE_/$Province/g;
  $WriteHtml =~ s/_POSTCODE_/$PostCode/g;
  $WriteHtml =~ s/_COUNTRY_/$Country/g;
  $WriteHtml =~ s/_PAY_1_/$PayOption1/g;
  $WriteHtml =~ s/_PAY_2_/$PayOption2/g;
  $WriteHtml =~ s/_PAYOPTION_/$PayOption/g;
  $WriteHtml =~ s/_PAYOPTIONFULL_/$PayOptionproducts/g;
  $WriteHtml =~ s/_PASSW_/$PassWord/g;
  $WriteHtml =~ s/_DELIVER_FROM_/$DeliverFrom/g;
  $WriteHtml =~ s/_DELIVER_TO_/$DeliverTo/g;
  $WriteHtml =~ s/_DELIVER_NOTES_/$DeliverNote/g;
  $WriteHtml =~ s/_DELDAY_FROM_/$DeldayFrom/g;
  $WriteHtml =~ s/_DELDAY_TO_/$DeldayTo/g;
  $WriteHtml =~ s/_PRFNUM_/$InvoiceNumber/g;
  $WriteHtml =~ s/_PURCHASELISTING_/$IveriProdListing/g;

}
if (($func eq "resell") || ($func eq "affiliate")) {
  $WriteHtml =~ s/_COMPANYNAME_/$CompanyName/g;
  $WriteHtml =~ s/_COMPANYREG_/$CompanyReg/g;
  $WriteHtml =~ s/_VATNUMBER_/$VatNumber/g;
  $WriteHtml =~ s/_TITLE_/$Title/g;
  $WriteHtml =~ s/_FIRSTNAME_/$FirstName/g;
  $WriteHtml =~ s/_SURNAME_/$SurName/g;
  $WriteHtml =~ s/_IDNUMBER_/$IdNumber/g;
  $WriteHtml =~ s/_EMAILADDRESS_/$EmailAddress/g;
  $WriteHtml =~ s/_TELAREA_/$TelArea/g;
  $WriteHtml =~ s/_TELEPHONE_/$Telephone/g;
  $WriteHtml =~ s/_FAXAREA_/$FaxArea/g;
  $WriteHtml =~ s/_FAXNUM_/$FaxNum/g;
  $WriteHtml =~ s/_MOBILE_/$Mobile/g;
  $WriteHtml =~ s/_PHYSICALADDRESS_/$PhysicalAddress/g;
  $WriteHtml =~ s/_POSTALADDRESS_/$PostalAddress/g;
  $WriteHtml =~ s/_CITYTOWN_/$CityTown/g;
  $WriteHtml =~ s/_PROVINCE_/$Province/g;
  $WriteHtml =~ s/_COUNTRY_/$Country/g;
  $WriteHtml =~ s/_WEBURL_/$WebURL/g;
  $WriteHtml =~ s/_PASSWORD_/$PassWord/g;
  $WriteHtml =~ s/_BUSINESSDESCRIPT_/$BusinessDescript/g;
  $WriteHtml =~ s/_SITEDESCRIPT_/$SiteDescript/g;
  $WriteHtml =~ s/_RES_ID_/$ResId/g;
  $WriteHtml =~ s/_AFF_ID_/$AffId/g;
}
if ($func eq "order") {
  $WriteHtml =~ s/_PRFNUM_/$InvoiceNumber/g;
  $WriteHtml =~ s/_TRANSACTID_/$TransactId/g;
  $WriteHtml =~ s/_LOGREFNR_/$LogRefNr/g;
  $WriteHtml =~ s/_MERCHANTREFERENCE_/$MerchantReference/g;
  $WriteHtml =~ s/_RECEIPTURL_/$ReceiptURL/g;
  $WriteHtml =~ s/_TRANSACTIONAMOUNT_/$TransactionAmount/g;
  $WriteHtml =~ s/_TRANSACTIONTYPE_/$TransactionType/g;
  $WriteHtml =~ s/_TRANSACTIONRESULT_/$TransactionResult/g;
  $WriteHtml =~ s/_TRANSACTIONERRORRESPONSE_/$TransactionErrorResponse/g;
  $WriteHtml =~ s/_SAFEPAYREFNR_/$SafePayRefNr/g;
  $WriteHtml =~ s/_BANKREFNR_/$BankRefNr/g;
  $WriteHtml =~ s/_LIVETRANSACTION_/$LiveTransaction/g;
  $WriteHtml =~ s/_SAFETRACK_/$SafeTrack/g;
  $WriteHtml =~ s/_BUYERCREDITCARDNR_/$BuyerCreditCardNr/g;
  $WriteHtml =~ s/_TIMESTAMP_/$TimeStamp/g;
  $WriteHtml =~ s/_STATUSFLAG_/$StatusFlag/g;
  $WriteHtml =~ s/_PURCHASELISTING_/$IveriProdListing/g;
}
  $WriteHtml =~ s/_BANNERFRAME_/$BannerFrame/g;

  $WriteHtml =~ s/_UCLR_//g;
  $WriteHtml =~ s/\\,/\,/g;
  $WriteHtml =~ s/\\'/\'/g;
  $WriteHtml =~ s/\\"/\"/g;
  
  if ($ForceInSecure eq "1") {
    $WriteHtml =~ s/\"index\.pl\?fn/\"http:\/\/www.toner.co.za\/cgi-bin\/index\.pl\?fn/g;
    $WriteHtml =~ s/\"..\/cgi-bin\/index\.pl\?fn/\"http:\/\/www.toner.co.za\/cgi-bin\/index\.pl\?fn/g;    
  }

	if ($subf eq "root") {
  	$WriteHtml =~ s/=\"..\//=\"/gi;
  	$WriteHtml =~ s/..\/images/images/gi;
  }

if ($DebugMode eq "Y") {
  $DebugString = $DebugString."<table width=\"800\" border=\"0\" bgcolor=\"#F2F2F2\" cellspacing=\"1\" cellpadding=\"1\" align=\"center\">\n";
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

$WriteHtml =~ s/_DEBUGSTRING_/$DebugString/g;

$MachInst = $ENV{QUERY_STRING};
$MachInst =~ s/$uid//g;
#$t0 = [gettimeofday];
#($seconds, $microseconds) = gettimeofday;
#$EndTime = $seconds.".".$microseconds;
#$ProcTime = $EndTime - $StartTime;
$ProcTime = sprintf("%.5f",$ProcTime);

print $WriteHtml;
print "\n<!-- Executed in $ProcTime seconds | $SessionCid -->\n\n";
$sql_statement = "INSERT INTO bench_mark VALUES ('','$UserId','$TimeStamp','$ProcTime','$ErrorFlag','IDX01','$MachInst');";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
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
	if (length($uid) > 12) { return; }
}
}

#--------------------------------------------------------------------------------------------------------------

sub lookup_countrycodes {

$sql_statement = "SELECT CountryCode,CountryName FROM countrycodes;";
$sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
while (@arr = $sth->fetchrow) {
    $CountryCode = @arr[0];
    $CountryName = @arr[1];
    if ($FromCountry eq $CountryCode) { $CountryListing = $CountryListing."<option value=\"".$CountryCode."\" selected>".$CountryName."</option>\n"; $SetCountryName = $CountryName; }
    else { $CountryListing = $CountryListing."<option value=\"".$CountryCode."\">".$CountryName."</option>\n"; }
}

}

sub create_year_listing {
  $sql_statement = "SELECT YEAR('$DateNow');";
  $sth = $dbh->query($sql_statement); push(@debugstring,"SQL||$sql_statement"); &check_dbase_error;
  @arr = $sth->fetchrow;
  $YearNow = @arr[0];
  $YearNow = $YearNow - 10;
  $TestString = $YearNow;
  for ($a = 1; $a <= 120; $a++) {
	$YearNow--;
	$YearList = $YearList."<option value=\"".$YearNow."\"> $YearNow</option>\n";
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


