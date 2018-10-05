#!/usr/bin/env perl
#-------------------------------------------------------------------------
# Adapted from a script originally by Chris Paciorek (http://www.stat.berkeley.edu/~paciorek/uc.pl).
# Original script details: http://www.stat.berkeley.edu/~paciorek/computingTips/Change_case_your_journal_ti.html.
#-------------------------------------------------------------------------
use strict;
use warnings;

use autodie;

use File::Basename;
use Hash::Case::Lower;
use Path::Class;

my $FIELD            = 'journal';

my $fileInName       = $ARGV[0];
my $fileOutName      = basename($fileInName, '.bib')."U.bib";
my $fileInHandle     = file($fileInName)->openr();
my $fileOutHandle    = file($fileOutName)->openw();

tie my(%replace), 'Hash::Case::Lower';
%replace = (
    'PLoS' => 'PLOS'  # PLOS is now rendered in all-caps
);

my @LOWER_CASE_WORDS = ('A', 'An', 'Nor', 'Or', 'And', 'To', 'With', 'Of', 'The', 'In', 'For', 'But', 'On', 'By', 'At', 'Down', 'From', 'Into', 'Like', 'Off', 'Onto', 'Out', 'Over', 'Up', 'Upon', 'Et', 'Al');

while(my $line=$fileInHandle->getline()){
    if($line=~/\s*$FIELD\s*=/){
        $line =~ s/((^\w)|(\s+\w)|(-\w)|(\n\w))/\U$1/g;
        
        my $regexLCDisjunction = join("|", @LOWER_CASE_WORDS);
        $line =~ s/((?:{|\s+)(?:${regexLCDisjunction})\s+)/\L$1/g; 
        
        $line =~ s/(=\s{0,}\{\w)/\U$1/g;
        $line =~ s/(:\s+\w)/\U$1/g;

        # Replace using the hash, ignoring the case of the match
        my $replaceRegex = join("|", keys %replace);
        $line =~ s/($replaceRegex)/$replace{lc($1)}/ieg;
    }
    print $fileOutHandle "$line";
}

close($fileInHandle);
close($fileOutHandle);
