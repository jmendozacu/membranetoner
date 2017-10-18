#!/usr/bin/perl

$current_user = $ENV{REMOTE_ADDR};
$referer = $ENV{HTTP_REFERER};
$user_agent = $ENV{HTTP_USER_AGENT};
$remote = $ENV{REMOTE_HOST};
$mail_prog = '/usr/sbin/sendmail' ;

print "Content-type: text/html\n\n";
print "IP: $current_user<br>\n";
print "RF: $referer<br>\n";
print "RM: $remote<br>\n";
print "Vars:\n<br>";

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
  print "Name: $name : $value\n<br>";
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
exit;


