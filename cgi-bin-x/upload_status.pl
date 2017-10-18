#!/usr/bin/perl

#print "Content-type: text/html\n\n";

require "admconfig.pl";

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

$TokenKey = $info{'tk'};

$tokenphile = $imgroot.$TokenKey.".tmp";
if (-e $tokenphile) { $UploadStatus = "404"; }
else { $UploadStatus = "200"; }

print "Content-type: text/xml\n\n";
print "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n";
print "<response>\n";
print "\t<UploadStatus>$UploadStatus</UploadStatus>\n";
print "\t<UploadCheck>ignore</UploadCheck>\n";
print "</response>\n";
exit;

