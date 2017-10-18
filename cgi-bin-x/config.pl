
#-Document Paths
$docroot = "/home/faranani/public_html/toner/dev/";
$mailroot = "/home/faranani/public_html/toner/dev/mail/";
$mailtemp = "/home/faranani/public_html/toner/dev/mail/mailtemp.txt";
$lockphile = "/home/faranani/public_html/toner/dev/write.lock";
$paylogphile = "/home/faranani/public_html/toner/_data/pay.log";
$ThumbNailPath = "/home/faranani/public_html/toner/user/thumbs/";
$FullImagePath = "/home/faranani/public_html/toner/user/products/";
$BrandImagePath = "/home/faranani/public_html/toner/user/brands/";

#-User
$SiteName = "Toner SA";
$CurrencyMark = "R";
$DefProdOffset = "10";
$FixedDelCharge = "85.00";
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
$host = "localhost";
$user = "faranani_tonercoz";
$password = "carlos4321";
$database = "faranani_tonercoza";


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

