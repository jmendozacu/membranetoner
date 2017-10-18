#!/usr/bin/perl
# 
# English:
# Program: CGICOMMAND v1.0 (April 2000)
# Powerful CGI program: Allows to execute command lines using a web interface.
# Might be useful for use on a web server where you have no Telnet allowance.
# Installation: upload using ASCII mode to the cgi-bin directory, chmod 755
# Operating Systems: All
# Tested with: UNIX/APACHE and WINDOWS/XITAMI
# Try "dir" command on a Windows server or "ls" on UNIX systems to test operation
#
# Deutsch:
# Programm: CGICOMMAND v1.0 (April 2000)
# M‰chtiges CGI-Programm erlaubt das Ausf¸hren von Kommandozeilen ¸ber ein Web-Interface
# Kˆnnte n¸tzlich sein, wenn Sie auf Ihrem Web-Server keine Telnet-Erlaubnis haben
# Installation: Upload im ASCII-Mode ins cgi-bin Verzeichnis, dann chmod 755
# Betriebssysteme: Alle
# Getestet mit: UNIX/APACHE und WINDOWS/XITAMI
# Testen Sie mit "dir"-Befehl auf einem Windows-Server oder "ls" auf einem UNIX-System.
#
# Copyright by Ruediger Thies
# (Idea by: Alfredo Rahn)
#

# --------- BEGIN OF USER DEFINABLE SECTION --------- 
# IMPORTANT: Set $password to YOUR individual password,
# if the password string is empty, everybody can access your server

  $password= '';  #  Change this to YOUR password!

# --------- END OF USER DEFINABLE SECTION --------- 
# ----- DO NOT EDIT ANYTHING BELOW THIS LINE ------



#####################################
# Main Program Loop
#####################################
$cgi_name=$ENV{'CGI_NAME'};
if ($cgi_name eq '') {$cgi_name=$ENV{'SCRIPT_NAME'};}

if (index($ENV{'HTTP_ACCEPT_LANGUAGE'},'de')>=0)
{ # Web Browser prefers German language
  $presents='Der Innovator pr&auml;sentiert:';
  $progtitle='Command Line Interpreter!';
  $freeware='Das Kopieren und Weitergeben unver&auml;nderter Originaldateien ist erlaubt.
            <br>DIE WEITERGABE MODIFIZIERTER VERSIONEN IST STRENGSTENS VERBOTEN!
            <br>Alle Rechte vorbehalten.';
  $risk='Sie verwenden diese Software auf eigene Gefahr!<br>
            Haftungsausschluﬂ: KEINE GARANTIE!';
  $enterpassword='Bitte Passwort eingeben:';
}
else
{ # Use English language otherwise
  $presents='The Innovator presents: ';
  $progtitle='Command Line Interpreter!';
  $freeware='Please feel free to copy unmodified versions of this script.
             <br>DISTRIBUTION OF MODIFIED VERSIONS IS STRICTLY PROHIBITED!
             <br>All rights reserved.';
  $risk='Use this software on your own risk!<br>
             Disclaimer: NO WARRANTIES!';
  $enterpassword='Please enter password:';
}
$title=$presents.$progtitle;
&ReadParse;
$subaction=$in{'SUB'};
if ($subaction eq '') {$subaction='LOGIN'};
if ($subaction eq 'LOGIN') {&Login}
else
{
  &CheckLogin;
  if ($subaction eq 'MAINFRAME') {&MainFrame}
  elsif ($subaction eq 'BOTTOMFRAME') {&BottomFrame}
  elsif ($subaction eq 'COMMAND') {&Command}
  else {&die_error("Undefined SUB action $subaction")};
}
exit(0); # main loop finished here


#####################################
sub ReadParse 
#####################################
# Parse input parameters
{
  local (*in) = @_ if @_;  local ($i, $loc, $key, $val);
  if ($ENV{'REQUEST_METHOD'} eq "GET") {
    $in = $ENV{'QUERY_STRING'};
  } elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
    read(STDIN,$in,$ENV{'CONTENT_LENGTH'});  }
  @in = split(/&/,$in);
  foreach $i (0 .. $#in) {
    $in[$i] =~ s/\+/ /g;
    ($key, $val) = split(/=/,$in[$i],2);
    $key =~ s/%(..)/pack("c",hex($1))/ge;
    $val =~ s/%(..)/pack("c",hex($1))/ge;
    $in{$key} .= "\0" if (defined($in{$key}));
    $in{$key} .= $val;  
  }
  return 1;
}



#####################################
sub MainFrame
#####################################
# Print main frame as HTML output
{
print "Content-type: text/html\n\n";
print <<"EOM" ;
<html>
<head>
<title>$title</title>
</head>
<!-- frames -->
<frameset  rows="85%,*">
    <frame name="top" src="$cgi_name?SUB=COMMAND&PASSWORD=$password" marginwidth="10" marginheight="10" scrolling="auto" frameborder="no">
    <frame name="bot" src="$cgi_name?SUB=BOTTOMFRAME&PASSWORD=$password" marginwidth="10" marginheight="10" scrolling="auto" frameborder="yes">
</frameset>
<body>
</body>
</html>
EOM
}


#####################################
sub BottomFrame
#####################################
# Print bottom frame as HTML output
{
print "Content-type: text/html\n\n";
print <<"EOM" ;
<html>
<head>
<title>$title</title>
</head>
<body>
<form action="$cgi_name" method="POST" target="top">
Command: <input type="Text" name="C">
<input type="Submit" name="" value="Execute">
<INPUT TYPE="HIDDEN" NAME = "SUB" VALUE="COMMAND">
<INPUT TYPE="HIDDEN" NAME = "PASSWORD" VALUE="$password">
</form>
</body>
</html>
EOM
}


#####################################
sub Command
#####################################
# Execute command and direct output to top frame
{
  print "Content-type: text/html\nPragma: no-cache\n\n";
	$OutPut = `$in{'C'}`;
	$OutPut =~ s/\n/<br>/g;
	print "$OutPut";
  print "\nReady.";
}


#####################################
sub Login
#####################################
# Show main login screen and ask for password
{
print "Content-type: text/html\n\n";
print <<"EOM" ;
<HTML>
<html>
<head>
<title>$title</title>
</head>
<BODY>
<center>
<h1><br>$presents<br>$progtitle</h1>
<table>
<tr><td>&copy;&nbsp;Copyright by<br>Ruediger Thies<br>The Innovator<br>
  <a href="http://www.fortunecity.de/wolkenkratzer/wasserturm/704/">http://www.fortunecity.de/wolkenkratzer/wasserturm/704/</a><br>
  E-Mail: <a href=mailto:thies\@online.de?subject=Command-Line-Interpreter>thies\@online.de</a>
</td></tr>
</table>
<FORM action="$cgi_name" method="POST">
  <INPUT TYPE="HIDDEN" NAME = "SUB" VALUE="MAINFRAME">
  $enterpassword&nbsp;<INPUT TYPE="TEXT" NAME = "PASSWORD"><INPUT TYPE="SUBMIT" VALUE="Login"></FORM>
</FORM>
$freeware<br>
$risk
</center>
</BODY>
</HTML>
EOM
}

#####################################
sub CheckLogin
#####################################
# check password, if invalid halt execution
{
   if ($password ne $in{'PASSWORD'})
  {&die_error("Invalid password")}
}


#####################################
sub die_error
#####################################
{
  local ($message) = @_;
  print "Content-type: text/html\n\n";
  print "<CODE>\n";
  print "Error while executing Perl script $CGI:\n";
  print $message;
  print "</CODE>\n";
  exit(0);
};
