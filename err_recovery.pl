#!/usr/bin/perl -w

=head1 NAME

err_recovery.pl ( Produce random Mizar articles and test Mizar error recovery )

=head1 SYNOPSIS

err_recovery.pl [options] filename

 Options:
   --number=<arg>		-n<arg>
   --pepperamount=<arg>,	-p<arg>
   --mixamount=<arg>,		-x<arg>
   --cpulimit=<arg>,		-c<arg>
   --startpos=<arg>,		-s<arg>
   --maxoutbytes=<arg>,         -b<arg>
   --verifier=<arg>,		-v<arg>
   --help,                  	-h
   --man

=head1 OPTIONS

=over 8

=item B<<< --number=<arg>, -n<arg> >>>

Number of random articles created, default is 100.

=item B<<< --pepperamount=<arg>, -p<arg> >>>

Amount of randomly added keywords, default is 30.

=item B<<< --mixamount=<arg>, -x<arg> >>>

Amount of random permutations. default is 10.
Not implemented yet!

=item B<<< --cpulimit=<arg>, -c<arg> >>>

CPU limit for each try, default is 7.

=item B<<< --maxoutbytes=<arg>, -b<arg> >>>

Maximal length of output printed from one test, 
default is 2000. Used to keep the log file reasonably
small when performing large number of tests giving
long error output like access violations.

=item B<<< --verifier=<arg>, -v<arg> >>>

The verifier to run. Default is "verifier".

=item B<<< --help, -h >>>

Print a brief help message and exit.

=item B<<< --man >>>

Print the manual page and exit.

=back

=head1 CONTACT

Josef Urban urban@kti.ms.mff.cuni.cz

=cut

=head1 APPENDIX

Description of functions defined here.

=cut

use strict;
use Pod::Usage;
use Getopt::Long;

my $ARTICLE_NUMBER	= 100;
my $PEPPER_AMOUNT	= 30;
my $MIX_AMOUNT		= 10;
my $CPU_LIMIT		= 7;
my $START_POS		= 1200;
my $MAX_OUTPUT_BYTES    = 2000;
my $VERIFIER		= "verifier";

## Name of the original Mizar article to be peppered - $ARGV[0]
my $MIZ_NAME;


## Keywords starting main mizar text items.
## Now also the environmental declarations.
my @mizar_main_keywords =
  ( 'theorem', 'scheme', 'definition', 'registration', 
    'notation', 'schemes', 'constructors', 'definitions', 
    'theorems', 'vocabulary', 'clusters', 'signature',
    'requirements'
  );


## Keywords for Mizar block starts and ends.
my @mizar_block_keywords =
  ( 'proof', 'now', 'end', 'hereby', 'case', 'suppose');

## Keywords for logical symbols in Mizar formulas.
my @mizar_formula_keywords =
  ( 'for', 'ex', 'not', '&', 'or', 'implies', 'iff', 'st', 'holds', 'being');

## Keywords denoting skeleton proof steps.
my @mizar_skeleton_keywords =
  ( 'assume', 'cases',  'given', 'hence', 'let', 'per', 'take', 'thus');


## Mizar keywords not mentioned in other place.
my @mizar_normal_keywords =
  ('and', 'antonym', 'attr', 'as', 'be', 'begin', 'canceled', 'cluster', 
   'coherence', 'compatibility', 'consider', 'consistency',  
   'contradiction', 'correctness', 'def', 'deffunc', 
   'defpred', 'environ', 'equals', 'existence',
   'func', 'if', 'irreflexivity', 
   'it', 'means', 'mode', 'of',  'otherwise', 'over', 
   'pred', 'provided', 'qua', 'reconsider', 'redefine', 'reflexivity', 
   'reserve', 'struct', 'such', 'synonym', 
   'that', 'then', 'thesis', 'where', 
   'associativity', 'commutativity', 'connectedness', 'irreflexivity', 
   'reflexivity', 'symmetry', 'uniqueness', 'transitivity', 'idempotence', 
   'asymmetry', 'projectivity', 'involutiveness'
  );

## All keywords used for pepper.
my @mizar_keywords = 
    (@mizar_main_keywords,
     @mizar_block_keywords,
     @mizar_formula_keywords,
     @mizar_skeleton_keywords,
     @mizar_normal_keywords);


sub min { my ($x,$y) = @_; ($x <= $y)? $x : $y }
sub max { my ($x,$y) = @_; ($x <= $y)? $y : $x }


sub DEBUGGING { 0 };
sub Debug_Print
{ 
    my($str) = @_;
    if(DEBUGGING) { print $str};
}

# Assumes that the two arguments are integers themselves!
sub Random_Int_In ($$)
{
    my($min, $max) = @_;
    return $min if $min == $max;
    ($min, $max) = ($max, $min)  if  $min > $max;
    return $min + int rand(1 + $max - $min);
}


# Pointer to random list of length LEN with integer values 
# from 0 to MAXVAL
sub Rand_List
{
    my ($maxval, $len) = @_;
    my (@res);
    while( $#res < $len - 1) { push(@res, Random_Int_In(1, $maxval)) };
    return @res;
}

# Now randomly deletes a random substring
sub Mix
{
    my ($str) = @_;
    if(1/$MIX_AMOUNT < rand)
    {
	my $offset1  = Random_Int_In(0, length($str) - 1);
	my $offset2  = Random_Int_In($offset1, length($str) - 1);
	return substr($str,0,$offset1).substr($str,$offset2);
    }
    else
    {
	return $str;
    }
}

sub Pepper_With_Syntax
{
    my ($fname, $pepper_nr, $mix_nr, $start, $white_nr, $contents) = @_;

    open(OUT, ">$fname");

    my @posvec  = sort { $a <=> $b } Rand_List($white_nr, $pepper_nr);
    my @wordvec = Rand_List($#mizar_keywords, $pepper_nr);
    my $i 	  = -1;
    my $lastpos   = 0;
    my $cur_white = 0;

    Debug_Print "\nposvec: @posvec\n";
    while($i++ < $#posvec)
    {
	while(($contents =~ m/[ \t\n]+/sg) && ($cur_white < $posvec[$i]))
	{
	    $cur_white++;
	};

	my $newpos = pos $contents;
	Debug_Print "$lastpos,$newpos;";
	if( $cur_white == $posvec[$i])
	{
	    print OUT Mix(substr($contents, $lastpos, 
				 ($newpos - $lastpos)));
	    print OUT ($mizar_keywords[$wordvec[$i]], " ");
	    $lastpos = $newpos;
	}
	else
	{
	    Debug_Print "FAILED\n";
	    print OUT Mix(substr($contents,$lastpos));
	};
    }
    close(OUT);
}


=head2  Create_Peppered()

  Title        : Create_Peppered()
  Usage        : Create_Peppered($orig, $art_nr, $pepper_nr,
                                 $mix_nr, $start);
  Function     : Create the peppered articles from $orig
  Returns      : List of the created filenames
  Global Vars  : @mizar_keywords
  Args         : ($orig, $art_nr, $pepper_nr, $mix_nr, $start)

=cut
sub Create_Peppered
{
    my ($orig, $art_nr, $pepper_nr, $mix_nr, $start) = @_;
    my ($base, $contents, $white_nr, $i, @res);

    die "$orig does not exist" unless(-e $orig);

    $orig 	=~ m/(.*)[.]miz$/
	or die "Not a Mizar file name: $orig";

    $base 	= $1;
    $contents 	= `cat $orig`;
    while($contents =~ m/[ \t\n]+/sg) { $white_nr++ };
    $pepper_nr = min($pepper_nr, $white_nr);

    while($i++ < $art_nr)
    {
	my $new_name = $base."$i.miz";
	if(-e $new_name) { system("rm -f $new_name"); };
	Pepper_With_Syntax($new_name, $pepper_nr, $mix_nr,
			   $start, $white_nr, $contents);
	push @res, $new_name;
    }
    return @res;
}


=head2  Test_Run()

  Title        : Test_Run()
  Usage        : Test_Run($orig, $newfiles, $cpu);
  Function     : Run verifier efficiently on @$newfiles, 
                 printing output to STDOUT.
  Returns      : -
  Global Vars  : $MAX_OUTPUT_BYTES
  Args         : $orig, $newfiles, $cpu;

=cut
## The moving prevents accommodation
sub Test_Run
{
    my ($orig, $newfiles, $cpu) = @_;
    my ($res, $file);
    my $hidden_orig = $orig."000";
    `accom $orig; $VERIFIER -q -l $orig`;
    system("mv $orig $hidden_orig");
    foreach $file (@$newfiles)
    {
	print "Processing: $file\n";
	system("mv $file $orig");
	$res = `ulimit -t$cpu; $VERIFIER -q $orig 2>&1`;
	system("mv $orig $file");
	print (substr($res,0,$MAX_OUTPUT_BYTES), "\n");
    }
    system("mv $hidden_orig $orig");
}


my ($help, $man);
Getopt::Long::Configure ("bundling");

GetOptions('number|n=i'		=> \$ARTICLE_NUMBER,
	   'pepperamount|p=i'	=> \$PEPPER_AMOUNT,
	   'mixamount|x=i'     	=> \$MIX_AMOUNT,
	   'cpulimit|c=i'    	=> \$CPU_LIMIT,
	   'startpos|s=i'   	=> \$START_POS,
	   'maxoutbytes|b=i'    => \$MAX_OUTPUT_BYTES,
	   'verifier|v=s'    	=> \$VERIFIER,
	   'help|h'          	=> \$help,
	   'man'             	=> \$man)
    or pod2usage(2);

pod2usage(1) if($help);
pod2usage(-exitstatus => 0, -verbose => 2) if($man);

pod2usage(2) if ($#ARGV != 0);

$MIZ_NAME = shift @ARGV;

my @created = Create_Peppered($MIZ_NAME, $ARTICLE_NUMBER, $PEPPER_AMOUNT,
			      $MIX_AMOUNT, $START_POS);

Test_Run($MIZ_NAME, \@created, $CPU_LIMIT);



