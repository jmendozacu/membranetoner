
#-Document Paths
$docroot = "/home/faranani/public_html/toner/adev/";
$mailroot = "/home/faranani/public_html/toner/adev/mail/";
$mailtemp = "/home/faranani/public_html/toner/adev/mail/mailtemp.txt";
$lockphile = "/home/faranani/public_html/toner/adev/write.lock";
$paylogphile = "/home/faranani/public_html/toner/_data/pay.log";
$ThumbNailPath = "/home/faranani/public_html/toner/user/thumbs/";
$FullImagePath = "/home/faranani/public_html/toner/user/products/";
$CatImagePath = "/home/faranani/public_html/toner/user/cats/";
$BrandImagePath = "/home/faranani/public_html/toner/user/brands/";
$imgroot = "/home/faranani/public_html/toner/user/";

#-User
$SiteName = "www.Toner.co.za";
$CurrencyMark = "R";
$DefProdOffset = "25";
$FixedDelCharge = "75.00";
$VatRate = "0.14";
$MailSender = "webmaster\@toner.co.za";
$SupportMail = "webmaster\@toner.co.za";
$ServiceMail = "webmaster\@toner.co.za";
$InfoMail = "webmaster\@toner.co.za";
$SalesMail = "webmaster\@toner.co.za";
$ScriptId = "ADM01";
$OrderDisplayLimit = "25";

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

$TimeStamp = time;

