#!/usr/bin/perl 

# these XML modules are now used for processing XML-format of 
# the Mizar internal database, they should be available for any
# major Perl distribution
use XML::XQL;
use XML::XQL::DOM;

# Dec 14 2001 ... fixed "[pred]" and "dualizing-func", seems OK for MML 3.26.709
# July 24, 2001 ... correcthidden fixed for Mizar 6.1.04 ... "[." added, still to fix
#  a bug introduced by "dualizing-func" 

# stag.pl ... create symbol tags for mizar abstracts
# run it in directory $MIZFILES/abstr on the abstracts you want, usually just
# "./stag.pl *.abs"
# relies on .dno files in $MIZFILES/prel directory and the file $MIZFILES/mml.vct
 


$prel=$ENV{MIZFILES}."/prel/";
$all="KORVMGUL";                        # this is used for indexing
$constrs="KRVMGUL"; # also indexing
# this maps symbols from $all to syntax symbols; used for defh in defshash() 
@symb=  ("func", "func", "pred", "attr", "mode", "struct", "sel", "struct");

# create the old miztags, modify into REFTAGS and delete

print "Creating reference tags\n";  
system "etags   --language=none  --regex='/^[^:]*:: \\([^ \n:]+\\):sch *\\([0-9]+\\)/\\1:sch \\2/'  --regex='/^[^:]*:: \\([^ \n:]+\\):\\([0-9]+\\)/\\1:\\2/'   --regex='/^[^:]*:: \\([^ \n:]+\\):def *\\([0-9]+\\)/\\1:def \\2/' *.abs";
open(IN, "TAGS");
open(OUT,'>reftags'); 
while (<IN>) { s/.*(.*)/$1;$1/; print OUT $_;};
close(IN); 
close(OUT);
system "rm TAGS";
print "reftags done\n";

# read in vocabularies into %voch
print "Reading in vocabularies information\n";
getnames();
print "Vocabularies information read\n";
getccounts();

# the main loop
print "Creating symbol tags\n";
sleep 1;
open(OUT,'>symbtags');
while ($file = shift) {
    ($fnoext) = split(/\./,$file);
    print "$fnoext\n";
    $nfile= $prel.substr($file,0,1)."/".$fnoext.".dno";
#    open(IN, $nfile) or next;
    next unless (-e $nfile);;
    # this creates %defh...for each "func "pred" etc ... list of symbols from .dno
    defshash();                                  
    foreach $key (keys %defh) {$bound{$key} = $#{$defh{$key}}};  # %bound holds the counts
#    close(IN);        
    open(IN, $file);                                             # opening .abs 
    $bytes=0;                                                    # counting bytes for tags
    print OUT "\n$file,\n";                                        # tag file header
    while (<IN>) 
    { $l=length($_);                                             # bytes counting
      s/::.*//;                                                  # strip comments
# beware, more defs can be on one line! ... ok
	  while(m/(^| )(func|pred|attr|struct|mode|synonym|antonym)([ \n\r(]|$)/g) {
	      $found=$2;
              # guess synonyms and antonyms            
	      if ($found eq "synonym") 
	      {$j = guesswhat('func','pred','attr','mode');}
	      elsif ($found eq "antonym") {$j = guesswhat('pred','attr');}
	      else {$j = $found};
	      shiftprint();                                            # shift and print tag
              # for structs, print defined sels if any
	      if (($found eq "struct") && (defined($selh{$sname})))  {
		  $str = $sname;
		  $j="sel";
		  foreach $i (0 .. $#{$selh{$str}} ) { shiftprint();} 
	      }  
	  }
      $bytes+= $l;                                                     # increase byte count
  }
    close(IN);                                                         
}

print "symbtags tags done\n";
# end of main loop

# read constrcounts into global hash %ccounts
sub getccounts {
    my $f,$f1,$f2;
    undef %ccounts;

    @fnames = `ls *.abs`; 
    foreach $f2 (@fnames) {
	($f) = split(/\./,$f2);
	$f1= $prel.substr($f,0,1)."/".$f.".dco";
	$ccounts{uc($f)} = get1count($f1);
    }
# debug
#   foreach $key (keys %ccounts) {$bla = $ccounts{$key}; print "$bla\n";  foreach $i (0 .. 6) { print "$bla->[$i]"; }}
}

sub get1count {
    my $f1 = shift(@_);
    my $arr = [0,0,0,0,0,0,0];
    return $arr unless (-e $f1);

    my $parser = new XML::DOM::Parser;
    my $doc = $parser->parsefile ($f1);
    my @result = $doc->xql ('Constructors/ConstrCounts/ConstrCount');

    foreach my $node (@result) {
      my $kind = $node->getAttributeNode ("kind");
      my $nr = $node->getAttributeNode ("nr");

      $arr->[index($constrs, $kind->getValue())] += $nr->getValue();
    }

# old stuff - remove after debugging
#     open(IN, $f1) or return $arr;
#     do { $_=<IN>;} until /\#/;
#     $_ = <IN>;
#     while(m/([KRVMGUL])([0-9]+)/g) {
# 	$arr->[index($constrs,$1)] += $2;
#     }
#     close(IN);
    return $arr;
}





# this reads the vocs form mml into the global hash %voch
sub getnames {
    open(VOC, $ENV{MIZFILES}."/mml.vct");
    undef %voch;
    $_=<VOC>; 
    m/\#([A-Z0-9_-]+).*$/;
    $aname=$1;
    <VOC>;
    $newaname=$aname;
    while ($newaname) {                                 # while onevoc() finds new voc name 
	undef $newaname;                                # call it to read its symbols 
	$voch{$aname}= onevoc();
	$aname=$newaname;
    }
    correcthidden();                                    # adds builtins to hidden
    close(VOC);
}


# this reads one voc from mml into 2-dimensional $arr and returns it
sub onevoc {
    my $arr; my $p;
    $arr=[[],[],[],[],[],[],[],[]];
    while (<VOC>) {
	if (/^\#([A-Z0-9_-]+).*$/) {$newaname=$1; $_=<VOC>; return $arr;}
	m/^([KORVMGUL])([^ \n\r]+) *.*$/;
	$p=index($all,$1);
        $arr->[$p][1+$#{$arr->[$p]}]=$2;
    }
    return $arr
}

# add builtin symbols for the HIDDEN vocabulary
sub correcthidden {
    @Ks=("[", "{", "]."); @Rs=("="); @Ms=("set");
    unshift  @{$voch{"HIDDEN"}->[0]}, @Ks;
    unshift  @{$voch{"HIDDEN"}->[2]}, @Rs;
    unshift  @{$voch{"HIDDEN"}->[4]}, @Ms;
}

# %defh...for each symbol "func "pred" "mode" ...contains list of symbols
# create it from .dno file, special care for structs... we need constr too to
# recognize its selectors
# %defnrs keeps constr nrs for respective %defh members
sub defshash {
    my $i,$tr,$nrs,$lname;
    %defh = ( "func" => [], "pred" => [], "mode" => [], 
	      "attr" => [], "sel" => [], "struct" => []);
    %defnrs = ( "func" => [], "pred" => [], "mode" => [], 
	      "attr" => [], "sel" => [], "struct" => []);
    @bases = (0,0,0,0,0,0,0);                        #constr bases
    
    my $parser = new XML::DOM::Parser;
    my $doc = $parser->parsefile ($nfile);

# init bases
    my @result = $doc->xql ('Notations/Signature/ArticleID');
    foreach my $node (@result) {
      $lname = $node->getAttributeNode("name")->getValue();
      foreach $i (0 .. 6) { $bases[$i] += $ccounts{$lname}->[$i]; }
    }
# remove the last one
    foreach $i (0 .. 6) { $bases[$i] -= $ccounts{$lname}->[$i]; }
    $hidden=0;                                       # if using HIDDEN, ban V1 (="strict") 
    undef(%selh);                                    # for each struct constr array of its sels  
    undef(%struct);                                  # constr structs names
    maketransl($doc);                                    # table for relative names in this .dno

    my @patterns = $doc->xql ('Notations/Pattern');

    foreach $pattern (@patterns) {
      $pkind = $pattern->getAttributeNode("kind")->getValue();

      next unless ($pkind =~ m/[KRMVUG]/);
      if ($pkind eq "U")
	{
	  my @argtypes = $pattern->xql('ArgTypes/Typ');
	  my $struc = $argtypes[$#argtypes];
	  $g = 'G' . $struc->getAttributeNode ("nr")->getValue();
	}
      else { undef $g };

      my $format = ($pattern->xql('Format'))[0];
      my $fkind = $format->getAttributeNode ("kind")->getValue();
      my $fnr = $format->getAttributeNode ("symbolnr")->getValue();

      $r = $fnr; $s = $fkind;
      # strict not visible
      if (($fkind eq "V")&&($fnr == 1)&&($hidden==1)) { next};

      # push "U" into its struct array in %selh
      if (defined($g)) { pushsel()};

      $p = index($all, $fkind);
      $f = $defh{$symb[$p]};	                   # array of the syntax symbol
      $nrs = $defnrs{$symb[$p]};
      $f->[1+$#{$f}] = $trans->[$p][$r-1];           # put the string there
      $nrs->[1+$#{$nrs}] = 0;   # init;

      # set constructors
      my $ckind = $pattern->getAttributeNode("constrkind")->getValue();
      my $cnr = $pattern->getAttributeNode("constrnr")->getValue();

      if ($ckind =~ m/[KRMVUG]/)  {  # antonyms and strmodes  ignored
	$tr = $cnr - $bases[index($constrs,$ckind)];
	if ($tr > 0) { $nrs->[$#{$nrs}] = $tr;} 
	if ($s eq "G") {
	  $ckind eq "G" or print "constr not found in $nfile: $_";
	  $struct{$ckind.$cnr} = $f->[$#{$f}];  # keeps names of struc constrs
	}
      }
    }
    $doc->dispose();
    return %defh;
}

# $trans...tells the voc name and the number in that voc of a given ralative symbol
# this creates the trans table for one .dno
sub maketransl {
    my ($doc) = @_;
    $trans=[[],[],[],[],[],[],[],[]];
    my @result = $doc->xql ('Notations/Vocabularies/Vocabulary/ArticleID');
    foreach my $node (@result) {
      my $name = $node->getAttributeNode("name")->getValue();
      if ($name eq "HIDDEN") { $hidden=1};
      foreach my $i (0 .. 7) {
	    foreach my $j (0 .. $#{$voch{$name}->[$i]}) {
		$trans->[$i][1+$#{$trans->[$i]}] = $voch{$name}->[$i][$j];
	    }}
    }
}

# pushes sel $r into its struct constr array
sub pushsel {
    undef $str;
    $str=$struct{$g};                                  # this yields the name of the struct constr
    if (!defined($selh{$str})) { $selh{$str} = [] }; 
    $selh{$str}->[1+$#{$selh{$str}}] = $r;
}

# This is now quite risky guessing for synonyms and antonyms
sub guesswhat {
  my @possible_syms = @_;
  my $g =substr($_,pos);
  my $p1,$p2, @syms1, @syms2, $max;
  @syms1 = (); @syms2 = (); $max = 0;
  while (index($g,';') < 0)    # very nasty, have to read more lines
  {
      my $old = $_;
      my $oldpos = pos;
      $bytes+= $l;         # increase byte count
      $_ = <IN>;
      $l=length($_);
      s/::.*//; 
      $_ = $old.$_;
      pos = $oldpos;
      $g =substr($_,pos);
  }

  $g =~ m/^(.*)[ \r\n]for[ \r\n](.*);/s
    or die "Bad guessing at $fnoext:$.";

  ($p1,$p2)= ($1, $2);    # the patterns hopefully
  foreach $sym (@possible_syms)
  {
      if(($#{$defh{$sym}} > -1) && (index($p1,$defh{$sym}[0]) > -1)) 
      { 
	  push(@syms1, $sym);
	  push(@syms2, $defh{$sym}[0]);
	  if(length($syms2[$#syms2]) > $max) { $max = length($syms2[$#syms2])};
      }
  }
  if ($#syms1 < 0)  {die "Nothing matched while guessing at $fnoext:$.:$_:$g:$p1:$p2";}
  if ($#syms1 == 0) {return $syms1[0]}; # OK, only one matched
  if ($#syms1 > 0)                    # more than one matched
  {
      my @syms3 = ();
      foreach $i (0 .. $#syms1) 
      { if(length($syms2[$i]) == $max) { push(@syms3,$syms1[$i])}};
      
      if ($#syms3 == 0) {return $syms3[0]}; # only one longest

      die "More than one match at at $fnoext:$.:$p1:".join(',',@syms1).":".
	  join(',',@syms2);
  }
}
  
# shifts the array in $defh{$j} and does the tag printing
sub shiftprint {
    $sname = shift @{$defh{$j}};
    $cnr   = shift @{$defnrs{$j}};
    $ord = $bound{$j}-$#{$defh{$j}};
    print OUT $sname.";".uc($fnoext).":$j.$cnr:$ord$sname$.,$bytes\n";
}

