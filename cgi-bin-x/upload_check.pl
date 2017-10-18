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
$FolderName = $info{'ifn'};
$FileName = $info{'ph'};
$FileName =~ s!^.*(\\|\/)!!;
$FileName =~ tr/A-Z/a-z/;

$testphile = $imgroot.$FolderName."/".$FileName;
if (-e $testphile) { $UploadStatus = "exists"; }
else { $UploadStatus = "noexist"; }

print "Content-type: text/xml\n\n";
print "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n";
print "<response>\n";
print "\t<UploadStatus>$FileName</UploadStatus>\n";
print "\t<UploadCheck>$UploadStatus</UploadCheck>\n";
print "</response>\n";
exit;

