#!/usr/bin/perl
# Copyright (c) 2026 By Wayne Wright, W5XD. See LICENSE for copying permissions.
# perl script to help automate recording .wav files for sending to piper training.
# Its input is
# a) <baseDir> required command line argument is directory where metadata.csv exists
# b) metadata.csv  in <baseDir>. Formatted as required by piper with | delimiter.
# c) folder named "wav" in <baseDir> containing any already recorded .wav files as named 
#    by first column in metadata.csv
#
# For recording .wav files:
# This script displays the Phrase from the csv and waits for any .wav file to
# appear in <baseDir> directory. This script renames such a file to what the csv
# called for and goes on to the next phrase. 
#    generate
# is allowed as file name, in which case this script computes a name for the file.
#
# This script does nothing to record the wav file. It simply waits for a file to
# appear in the directory. I use http://audacityteam.org.
# piper seems to want 48000 samples/sec, and 16 bit signed integer format Windows
# wav file format.
#
# For managing the csv file:
# This script outputs a new file, metadata-new.csv that contains only entries that have
# recorded wav files.
#
# Typing a Q anytime exits this script.
# Type a 'D' after a "review" of an existing file deletes it and prompts to re-record it.
# Type an 'S' when prompted for a recording and the phrase is skipped and not written
# to the metadata-new.csv file.
#
# Optional command line arguments
# --review      plays each existing file named in metadata.csv and waits confirmation 
#               to continue. Note that Windows moves the keyboard focus to the playback
#               application, so you have first click on perl's console window, then
#               press the apprpriate keyboard
# --scan        Don't do any recordings. Scan the metadata.csv and print a message
#               summarizing what wav files already exist, and whether any extra ones
#               are present.
# --no-dupes    Silently skip any metadata.csv entries that are the same phrase
#               as any earlier entry.
# --baseWavName
#               Override this script's default for "generated" wav file names.
#               The default is "ham_wavs/ph_". This script appends a 3 digit 
#               decimal number and .wav.               
#
use strict;
use warnings;

# Source - https://stackoverflow.com/a
# Posted by Helen Craigman
# Retrieved 2025-12-30, License - CC BY-SA 3.0
use Win32::Console
  ;    # fix for certain characters don't print to Win32 console correctly
Win32::Console::OutputCP(65001);

use Term::ReadKey;    #portable perl console read routines
use Time::HiRes qw(usleep);
use IO::Handle;
ReadMode 'cbreak';

my $review   = 0;
my $scanOnly = 0;
my $noDupes  = 0;
my $baseFolder;
my $doUsage = 0;

my $GENERATE_FLAG =
  "generate";         #if this is the "filename" in the csv, then generate one
my $GENERATE_BASE_NAME = "ham_wavs/ph_";
my $generate_cur_index = 1;
my $BASE_DIR           = undef;
my $WAV_PRE            = "./wav/";

#scan command line
my $maxArgs = $#ARGV;
my $argnum  = 0;
while ( $argnum <= $maxArgs ) {
    my $arg = $ARGV[ $argnum++ ];
    if    ( $arg eq "--review" )   { $review   = 1; }   #plays existing .wav
    elsif ( $arg eq "--scan" )     { $scanOnly = 1; }   #only scan, don't record
    elsif ( $arg eq "--no-dupes" ) { $noDupes  = 1; }   #skip duplicate phrases
    elsif ( $arg eq "--baseWavName" ) {
        if ( $argnum <= $maxArgs ) { $GENERATE_BASE_NAME = $ARGV[ $argnum++ ]; }
        else                       { $doUsage = 1; last; }
    }
    elsif ( 0 != rindex( $arg, "-", 0 ) ) { $BASE_DIR = $arg; }
    else                                  { $doUsage  = 1; last; }
}

if ( !defined($BASE_DIR) || $doUsage != 0 ) {
    print STDERR
"usage PiperRecordingHelper.pl <base-dir> [--review] [--scan] [--no-dupes] [--baseWavName <wav-dir/base-file-name>]\n";
    print STDERR
      "   <base-dir> is where metadata.csv and wav folder must exist\n";
    print STDERR
      "   --review  plays each existing wav file. D to re-record it\n";
    print STDERR "   --no-dupes detects duplicated phrases and skips them\n";
    print STDERR
"   --scan    don't play nor record. only scan for duplicate phrases and create output csv\n";
    print STDERR
"   --baseWavName   is path to .wav file names to generate. Any directories named must already exist.\n";
    exit 1;
}

$BASE_DIR =~ s/\\/\//g;    # we'll use unix / except where windows demands \

if ( not $BASE_DIR =~ /\/\z/ ) {
    $BASE_DIR = $BASE_DIR . "/";
}                          # ensure trailing slash
chdir($BASE_DIR) or die "Argument must be a directory: " . $BASE_DIR . "\n";
my @initWav = glob("*.wav");
if ( scalar(@initWav) != 0 ) {
    print STDERR "There must not be a .wav file here: "
      . $BASE_DIR
      . $initWav[0] . "\n";
    exit 1;
}

my $filename = "metadata.csv";
my $fnCsvOutput =
  "metadata-new.csv";      # the output csv has only phrases with .wav files
open( my $fh,   '<', $filename )    or die "Could not open '$filename': $!";
open( my $fout, '>', $fnCsvOutput ) or die "Could not open output";
if ( not -d "./wav" ) {
    die "wav folder must be in <base-dir> with metadata.csv";
}
$fout->autoflush;
STDOUT->autoflush(1);

my %allPhrases;            # track for duplicate phrases
my %allFiles;              # track all the files named, so far
my %allWavFolders;         # track all wav folders

#read metadata.csv into arrays to ease iterating forward and back through phrases
my @lineAr;
my @phraseAr;
while ( my $line = <$fh> ) {    #read input .csv file
    my @parts = split( /\x7c/, $line );    #parse by vertical bar |, 0x7c
    if ( scalar( @parts != 2 ) ) {
        print STDERR "Bad line sz=" . scalar(@parts) . " " . $line;
        next;
    }
    push( @lineAr,   $parts[0] );
    push( @phraseAr, $parts[1] );
}

my $which = 0;
for ( $which = 0 ; $which < scalar @lineAr ; $which++ )
{    #for each line in the .csv file input
    my $phrase    = $phraseAr[$which];
    my $lcPhrase  = lc($phrase);
    my $nNlPhrase = $phrase;                  #no trailing newline
    $nNlPhrase =~ s-[\r\n]$--;
    $nNlPhrase =~ s-[\r\n]$--;
    if ( exists $allPhrases{$lcPhrase} ) {    #duplicate phrase
        print STDOUT "Duplicate phrase: \"" . $lcPhrase . '"';
        if ( $noDupes == 1 ) { next; }        #command line said no dupes
    }
    my $targetname    = $lineAr[$which]; # $targetname does not lead with ./wav/
    my $generatedFile = 0;
    if ( lc($targetname) eq $GENERATE_FLAG ) {
        my $checkName;
        while (1) {
            $checkName = sprintf( "%s%04d.wav",
                $GENERATE_BASE_NAME, $generate_cur_index++ );
            if ( exists $allFiles{$checkName} ) { next; }
            if ( -e $WAV_PRE . $checkName )     { next; }
            $targetname    = $checkName;
            $generatedFile = 1;
            last;
        }
    }
    if ( $targetname =~ /\.wav\z/ ) { }    #ensure has .wav extension
    else                            { $targetname = $targetname . ".wav"; }
    $allPhrases{$lcPhrase} = $targetname;
    $allFiles{$targetname} = $lcPhrase;
    my $thisDir = $targetname;
    $thisDir =~ s|[^/]+$||;
    $allWavFolders{$thisDir} = 1;
    my $pathToTarget = $WAV_PRE . $targetname;
    my $targetExists = -e $pathToTarget;

    if ( $scanOnly == 1 ) {    #only scanning for dupes. write output only
        if    ($targetExists) { print $fout $targetname . "|" . $phrase; }
        elsif ( !$generatedFile ) {
            print "Named in csv but not present: " . $targetname . "\n";
        }
        next;
    }
    if ($targetExists) {
        if ( $review == 0 ) {    #not preview, print message and go to next
            print "Already have " . $targetname . "\n";
        }
        else {
            print "review "
              . $targetname
              . " for phrase \""
              . $nNlPhrase . "\"\n";
            my $revslash = $pathToTarget;
            $revslash =~ s|/|\\|g;
            system( "\"" . $revslash . "\"" );    # Windows has an app for that
            my $ch = ReadKey 0;
            my $up = uc($ch);

            # q or Q exits whole program
            # D deletes this recording and prompts to record it again
            if    ( $up eq " " ) { }
            elsif ( $up eq "Q" ) { exit 1; }

            # roman numeral for 50 goes forward or backward 50 phrases
            elsif ( $ch eq "l" ) {
                $which -= 51;
                if ( $which < 0 ) { $which = -1; }
            }
            elsif ( $up eq "L" ) { $which += 49; }

            # digits go forward that man
            elsif ( $up !~ /\\D/ ) { $which += $up; }
            elsif ( $up eq "D" ) {
                print STDOUT "C to confirm: ";
                $ch = ReadKey 0;
                if ( uc($ch) eq "C" ) {
                    unlink $pathToTarget;
                    print "\n->";
                    goto do_record;
                }
            }
        }
        print $fout $targetname . "|"
          . $phrase;    # input line goes to output line
        next;
    }
  do_record:            # here to record a new wav file for phrase
    while (1) {
        my $prompt = $nNlPhrase;
        print STDOUT "Say: \"" . $prompt
          . "\"\n";     # prompt to read into recording
        my @files;
        while (1) {
            my $ch = ReadKey - 1;    #poll for input. undef if none
            if ( defined $ch ) {
                if    ( uc($ch) eq "Q" ) { exit 1; }
                elsif ( uc($ch) eq "S" ) { goto next_phrase; }
            }
            usleep(100_000);           # Sleep for 100 milliseconds
            @files = glob("*.wav");    # wait for any file named .wav to appear
            if ( scalar(@files) != 0 ) { last; }
        }
        usleep(100_000);    # Sleep for 100 milliseconds after seeing a file
        if ( scalar(@files) == 1 ) {
            print STDERR "Renaming " . $files[0] . " to " . $targetname;
            rename( $files[0], $WAV_PRE . $targetname )
              or die "Failed to rename";
            print "\n";
            print $fout $targetname . "|"
              . $phrase;    # input line goes to output line
            last;           #breaks the while(1)
        }
        else { print $STDERR "No .wav file"; }
    }
  next_phrase:
}

close($fh);
close($fout);

if ( $scanOnly == 1 ) {
    print "Number of files named in csv " . scalar keys(%allFiles) . "\n";
    foreach my $key ( keys %allWavFolders ) {
        my @wavs = glob( $key . "*.wav" );
        foreach my $wavfile (@wavs) {
            $wavfile = substr( $wavfile, 4 );    #strip off leading wav/
            if ( !exists $allFiles{$wavfile} ) {
                print "File " . $key . $wavfile . " not named in csv.\n";
            }
        }
    }
}
