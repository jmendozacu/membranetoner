#!/usr/bin/perl


use CGI::Carp qw(fatalsToBrowser);

#-Document Paths
$docroot = "/hsphere/local/home/carbs/toner.co.za/dev/";
$mailroot = "/hsphere/local/home/carbs/toner.co.za/dev/mail/";
$mailtemp = "/hsphere/local/home/carbs/toner.co.za/dev/mail/mailtemp.txt";
$lockphile = "/hsphere/local/home/carbs/toner.co.za/dev/write.lock";
$paylogphile = "/hsphere/local/home/carbs/toner.co.za/_data/pay.log";
$ThumbNailPath = "/hsphere/local/home/carbs/toner.co.za/user/thumbs/";
$FullImagePath = "/hsphere/local/home/carbs/toner.co.za/user/products/";
$BrandImagePath = "/hsphere/local/home/carbs/toner.co.za/user/brands/";
$TempDir = "/hsphere/local/home/carbs/toner.co.za/backup/sql/";
$TarPhile = "/hsphere/local/home/carbs/toner.co.za/backup/backup.tar";

#-User
$SiteName = "www.Toner.co.za";
$CurrencyMark = "R";
$DefProdOffset = "10";
$FixedDelCharge = "45.00";
$VatRate = "0.14";
$MailSender = "webmaster\@toner.co.za";

@banned = ('072','073','074','082','083','084');

$SupportMail = "tech\@toner.co.za";
$ServiceMail = "tech\@toner.co.za";
$InfoMail = "info\@toner.co.za";
$SalesMail = "sales\@toner.co.za";
$SiteBaseURL = "http://www.toner.co.za/";

#-System
$error_log = "/home/sites/site34/data/system/errorlog.dat";
$backuplog = "/home/sites/site34/data/system/backuplog.dat";

$current_user = $ENV{REMOTE_ADDR};
$referer = $ENV{HTTP_REFERER};
$user_agent = $ENV{HTTP_USER_AGENT};
$remote = $ENV{REMOTE_HOST};
$mail_prog = '/usr/lib/sendmail' ;

#- MySQL Variables
$host = "mysql2.jodoshared.com";
$user = "carbs_toner";
$password = "arvoyo";
$database = "carbs_tonercoza";


use Mysql;
$dbh = Mysql->connect($host, $database, $user, $password);

$sql_statement = "SELECT NOW();";
$sth = $dbh->query($sql_statement);
@arr = $sth->fetchrow;
$DateNow = @arr[0];
$sql_statement = "SELECT YEAR('$DateNow');";
$sth = $dbh->query($sql_statement);
@arr = $sth->fetchrow;
$CopyRightDate = @arr[0];

$TimeStamp = time;

print "Content-type: text/html\n\n";
print "Running backup $DateNow<br>\n";


  $outphile = $TempDir."/backup.sql";
  open (OUTPHILE2, ">$outphile");


	$sql_statement = "SHOW TABLES;";
  push(@debugdata,"SQL||$sql_statement");
	$sth = $dbh->query($sql_statement);
	while (@arr = $sth->fetchrow) {
		($TableName) = @arr;
		push(@tables,$TableName);
	}
	foreach $TableName(@tables) {
		$TableCount++;
    $outphile = $TempDir."/".$TableName.".sql";
		if (($TableName eq "bench_mark") || ($TableName eq "shopping_basket") || ($TableName eq "site_content") || ($TableName eq "user_session")) { $Skip = "1"; }
    else {
    open (OUTPHILE, ">$outphile");
    print OUTPHILE "\nTRUNCATE TABLE $TableName;\n\n";
    print OUTPHILE2 "\nTRUNCATE TABLE $TableName;\n\n";
    $LineCount = "0";
    $sql_statement = "SELECT * FROM $TableName;";
  	$sth = $dbh->query($sql_statement);
  	while (@arr = $sth->fetchrow) {
      foreach $Value(@arr) {
        $Value =~ s/\"/\\"/g;
        $Value =~ s/\'/\\'/g;
        $ValueString = $ValueString.$Value."',";
      }
      chop $ValueString;
      print OUTPHILE "INSERT INTO $TableName VALUES ('".$ValueString.");\n";
      print OUTPHILE2 "INSERT INTO $TableName VALUES ('".$ValueString.");\n";
      $LineCount++;
      $ValueString = "";
    }
    close(OUTPHILE);
		print "$TableCount : $LineCount : Dumped table $TableName <br>\n";
    }
	}

  close(OUTPHILE2);

	$Command = "tar -cf ".$TarPhile." ".$TempDir."/";
  print "exec - $Command<br>\n";
  $OutPut = `$Command`;
	$Command = "gzip $TarPhile";
  print "exec - $Command<br>\n";
  $OutPut = `$Command`;
	$outphile = $TempDir."/backup.sql";
  $Command = "gzip $outphile";
  print "exec - $Command<br>\n";
  $OutPut = `$Command`;





