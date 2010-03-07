#
# sulekha.pl a text-based markov-chain generator
# Copyright Vivin Suresh Paliath (2004)
# Distributed under GPLv3
#


#!/usr/bin/perl

 use strict;
 use Getopt::Mixed;
 
 $| = 1; #NO BUFFERING DAMNIT!!!!

 my $filename;
 my $line;
 my $verbose;
 my $dehtml;
 my $script = 0;
 my $comment = 0;
 my @wordarr;
 my @letterarr;
 my $frqtable = {};
 my $curridx;
 my $junk;
 my $paraflag;
 my @junkarr;
 my $messagelength = 2;
 my $message;
 my $wordpair;
 my $maxmessagelength;
 my $type = "word";
 my $depth = 2;
 my $set;
 my $space;

 Getopt::Mixed::init('l:i
                      t:s
                      d:i
                      h:s
                      length>l
                      type>t
                      depth>d
                      help>h'
                    );

 while(my($option, $value, $pretty) = Getopt::Mixed::nextOption())
 {
       OPTION:
       {
             $option eq 'l' and do
             {
                     $maxmessagelength = $value if $value;
             };

             $option eq 't' and do
             {
                     $type = $value if $value;

                     if($type ne "word" and $type ne "letter")
                     {
                        $type = "word";
                     }
             };

             $option eq 'd' and do
             {
                     $depth = $value if $value;
             };

             $option eq 'h' and do
             {
                     print "Syntax: $0 [options] filename\n";
                     print "        where options are:\n\n";
                     print "        -l=length|--length=length\tLength of the chain. Default is random.\n";
                     print "        -t=word|letter|--type=word|letter\tType of chain. Word or letter-based. Default is word.\n";
                     print "        -d=depth|--depth=depth\nDepth of chain. Default is 2.\n";
                     exit 1;
             };
       }

 }

 Getopt::Mixed::cleanup();

 $filename = $ARGV[0];

 if(scalar(@ARGV) == 0)
 {
           print "Syntax: $0 [options] filename\n";
           print "        where options are:\n\n";
           print "        -l=length|--length=length\tLength of the chain. Default is random.\n";
           print "        -t=word|letter|--type=word|letter\tType of chain. Word or letter-based. Default is word.\n";
           print "        -d=depth|--depth=depth\tDepth of chain. Default is 2.\n";
           exit 1;
 }

 srand;

 foreach $filename(@ARGV)
 {
         print "Opening $filename...";

         open(IN, "<$filename") or die "Could not open $filename for input.";

         print "ok\n";

         print "Formatting $filename...";

         while(<IN>)
         {
               $line .= $_;

         }

         #
         # Treat each punctuation mark as a token
         #

         $line =~ s/\.+/ . /g;
         $line =~ s/\?+/ $& /g;
         $line =~ s/!+/ $& /g;
         $line =~ s/,+/ $& /g;
         $line =~ s/\(/ $& /g;
         $line =~ s/:/ $& /g;

         $line =~ s/^\s+//;
         $line =~ s/\s+$/\n/;
         $line =~ s/\s+/ /;
 
         print "done\nForming frequency table...";

         close(IN);

         $line =~ s/\r*\n/~/g;

         if($type eq "word")
         {
            @wordarr = split(/\s+/, $line);

            for(my $i = 0; $i < scalar(@wordarr) - $depth; $i++)
            {
                $set = "";

                for(my $j = 0; $j < $depth; $j++)
                {
                    $set .= ($wordarr[$i + $j] . " ");
                }

                $set =~ s/\s+$//;

                push(@{$frqtable->{$set}->{succ_arr}}, $wordarr[$i + $depth]); 
            }
         }

         else
         {
            @letterarr = split(//, $line);

            for(my $i = 0; $i < scalar(@letterarr) - $depth; $i++)
            {
                $set = "";

                for(my $j = 0; $j < $depth; $j++)
                {
                    $set .= $letterarr[$i + $j];
                }

                push(@{$frqtable->{$set}->{succ_arr}}, $letterarr[$i + $depth]); 
            }
 
         }        

         print "done\n\n";
 }

 open(OUT, ">$filename.markov");

# foreach my $set(sort(keys(%{$frqtable})))
# {
#         foreach my $successor(@{$frqtable->{$set}->{succ_arr}})
#         {
#                 print "|$set| -> |$successor|\n";
#         }
# }
#
# exit;


 if(!$maxmessagelength)
 {
    $maxmessagelength = int(rand(scalar @wordarr - 200)) + 200;
 }

 my @keys = keys(%{$frqtable});
 my $set = $keys[rand(scalar(@keys)) + 1];
 my $message = $set;

 print "Generating Markov Chain (order-$depth) with $maxmessagelength words. Starting $type-set is \"$set\".\n\n";

 if($type eq "word")
 {
    $space = " ";
 }

 else
 {
    $space = "";
 }

 while($messagelength < $maxmessagelength)
 {
       if($frqtable->{$set})
       {
          $junk = int(rand(scalar(@{$frqtable->{$set}->{succ_arr}})));
       }

       $message .= ($space . $frqtable->{$set}->{succ_arr}->[$junk]);

       if($type eq "word")
       {
          @junkarr = split(/\s+/, $message);
       }

       else
       {
          @junkarr = split(//, $message);
       }

       $set = "";

       for(my $i = (scalar(@junkarr) - $depth); $i < scalar(@junkarr); $i++)
       {
           $set .= ($junkarr[$i] . $space);
       }

       if($type eq "word")
       { 
          $set =~ s/\s+$//;
       }

#       if($paraflag != 1)
#       {
#          $paraflag = int(rand(100));
#       }
#  
#       else
#       {
#          if($message =~ /\.$/ ||
#             $message =~ /\?$/ ||
#             $message =~ /"$/  ||
#             $message =~ /!$/)
#          {
#             $message .= "\n\n";
#             $paraflag = 0;
#          }
#       }
       $messagelength++;
 }

 $message =~ s/~/\n/g;

 $message =~ s/ \././g;
 $message =~ s/ \?/?/g;
 $message =~ s/ !/!/g;
 $message =~ s/ ,/,/g;
 $message =~ s/\( /\(/g;
 $message =~ s/ :/:/g;

 $message =~ s/ +$//;

 print $message . "\n";

 print OUT $message . "\n";

 close(OUT);
