#!/usr/bin/perl -w

$slash = "/";

$#ARGV >= 0 || die "usage: $0 articlename \$MIZFILES/mizar";
$articlename = shift; $articlename =~ s/\.err$//; $articlename =~ s/\.miz$//;
$errorlist = $articlename; $errorlist =~ s/$/.err/;
if ($#ARGV < 0)
{
  $MIZFILES = defined($ENV{"MIZFILES"}) ? $ENV{"MIZFILES"} :
    die "environment variable MIZFILES is not set";
  $MIZFILES =~ s/$slash$//; $MIZFILES .= $slash;
  $mizarmsg = $MIZFILES."mizar.msg";
}
else
{
  $mizarmsg = shift; $mizarmsg =~ s/\.msg$//; $mizarmsg =~ s/$/.msg/;
}
open(MSG, $mizarmsg) || die "could not open file $mizarmsg";
while(<MSG>)
{
  s/[\012\015]//g;
  next if !/^\# ([0-9]+)/; $error = $1;
  $_ = <MSG>; s/[\012\015]//g; s/^ +//; s/ +$//;
  $message{$error} = $_;
}
close(MSG);
open(ERR, $errorlist) || die "could not open file $errorlist";
while(<ERR>)
{
  s/[\012\015]//g; s/\t/ /g; next if /^ *$/;
  next if !/^ *([0-9]+) +([0-9]+) +([0-9]+) *$/; $key = "$1:$2:$3";
  $error{$key} = $3, $count{$key}++;
}
close(ERR);
sub cmp2
{
  $a =~ /([0-9]+):([0-9]+):([0-9]+)/; $al = $1; $ar = $2; $an = $3;
  $b =~ /([0-9]+):([0-9]+):([0-9]+)/; $bl = $1; $br = $2; $bn = $3;
  $l = $al <=> $bl; $r = $ar <=> $br; $l ? $l : $r ? $r : $an <=> $bn;
}
$previous = ""; $newline = "";
for $key (sort cmp2 keys %error)
{
  $key =~ /(.*:.*):.*/; $position = $1;
  $error = $error{$key};
  $message = "*$error"; $message .= ",$error" while --$count{$key};
  $message .= ": ";
  $message .= (defined($message{$error}) ? "$message{$error}" :
    "Unlisted error");
  print $position eq $previous ? ", $message" :
    $newline."$articlename.miz:$position: $message";
  $previous = $position; $newline = "\n";
}
print $newline;