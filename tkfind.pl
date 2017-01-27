#!/usr/bin/perl -w
# Richard James Howe, 2013, 2017
#
# Simple Find utility, bulk of it (the TK code) found here:
#     http://www.perlmonks.org/?node_id=922840
# TODO:
# 	* Add line number option, displays the line number before the matched string.
# 	* Find out if it is possible to colorize the output strings (partially).
# 	* Command line options
# 	* Expand search box to screen size/improve look of GUI
#

########################## Setup area ##################################################################

use strict;
use warnings;
use Tk;
use Tk ':eventtypes';
require Tk::Font;
use Tk::FileDialog; # http://search.cpan.org/dist/Tk-FileDialog/FileDialog.pm

### Global Variables ###

my $searchFile = "searchme.txt";

# Main Window #
my $mw = new MainWindow;

### Misc ###
$mw->title("Perl/Tk Regex utility");

# Maximize main window. #
$mw->geometry($mw->screenwidth . "x" . $mw->screenheight . "+0+0");

########################### Key bindings ##############################################################

$mw->bind('<KeyRelease-Escape>' => sub{ exit });
$mw->bind('<KeyRelease-Return>' => \&action_on_search_pushButton);

########################### GUI Building Area #########################################################

### Labels and data entry. ###
my $form       = $mw->Frame();
my $regexLabel     = $form->Label(-text=>"Regex:");
my $filenameLabel  = $form->Label(-text=>"File Name:");
my $regexEnt       = $form->Entry();
my $fileEnt        = $form->Entry(-textvariable=>"$searchFile");

### Check button opens and their labels/result variables. ####

## Delete previous search results on new search? ##
my $deletePrevious         = "Yes";
my $frm_deletePrevious     = $form; # $mw->Frame();
my $lbl_deletePrevious     = $frm_deletePrevious->Label(-text=>"Delete results:");
my $rdb_delPrv_yes         = $frm_deletePrevious->Radiobutton(
                             -text=>"Yes",
                             -value=>"Yes",  -variable=>\$deletePrevious
                           );
my $rdb_delPrv_no          = $frm_deletePrevious->Radiobutton(
                             -text=>"No",
                             -value=>"No",-variable=>\$deletePrevious
                           );

## Is the search going to be case sensitive or not? ##

my $caseSensitive          = "No";
my $frm_caseSensitive      = $form; # $mw->Frame();
my $lbl_caseSensitive      = $frm_caseSensitive->Label(-text=>"Case Sensitive");
my $rdb_caseSensitive_yes  = $frm_caseSensitive->Radiobutton(
                             -text=>"Yes",
                             -value=>"Yes",  -variable=>\$caseSensitive
                           );
my $rdb_caseSensitive_no   = $frm_caseSensitive->Radiobutton(
                             -text=>"No",
                             -value=>"No",-variable=>\$caseSensitive
                           );

### File selection ###

my $selectFile             = $form->FileDialog(-Title =>'Select a file to search in',
	                                    -Create => 0);

$selectFile->configure(-FPat => '*', -ShowAll => 'YES');



### Buttons ###
			   #
my $searchButton           = $form->Button(-text=>"Search", -command =>\&action_on_search_pushButton);
my $exitButton             = $form->Button(-text=>"Quit", -command => sub { exit });
my $fileSelectButton       = $form->Button(-text=>"Select File", -command => 
	sub {
		my $file =  $selectFile->Show();
		if(defined($file)) {
			$searchFile = $file;
			$fileEnt->configure(-text=> "$searchFile");
		}

	});

### Text Area ###

my $textarea               = $mw->Frame();
my $textareaFontUsed       = "systemfixed"; # Windows only, should change this.
# Use "W" as it is a wide(est?) character just in case we are not using a fixed width font
my $textareaCharWidth      = $textarea->fontMeasure($textareaFontUsed, "W"); 
my $textareacontent        = $textarea->Text(
                             -font   => $textareaFontUsed,
                             -width  => (($mw->screenwidth)/$textareaCharWidth) - 10,
                             -height => $mw->screenheight - 40,
                             -wrap   => "none"
                           );
my $srl_y                  = $textarea->Scrollbar(-orient=>'v',-command=>[yview => $textareacontent]);
my $srl_x                  = $textarea->Scrollbar(-orient=>'h',-command=>[xview => $textareacontent]);
$textareacontent->configure(-yscrollcommand=>['set', $srl_y], -xscrollcommand=>['set',$srl_x]);

########################### Geometry Management #######################################################

$form->pack();
$srl_y->pack(-side => 'right', -expand => 1, -fill => 'y');
$srl_x->pack(-side => 'bottom', -expand => 1, -fill => 'x');
$textareacontent->pack(-side => 'bottom', -expand => 1, -fill => 'both');
$textarea->pack();
$filenameLabel->pack(-anchor => 's', -side => 'left', -pady => 20);
$fileSelectButton->pack(-anchor => 's', -side => 'right', -pady => 20);
$fileEnt->pack(-anchor => 's', -side => 'bottom', -expand => 1, -fill => 'x', -pady => 20);

$regexLabel->pack(-anchor => 'e', -side => 'left');
$regexEnt->pack(-anchor => 'e', -side => 'left');
$lbl_deletePrevious->pack(-anchor => 'e', -side => 'left');
$rdb_delPrv_yes->pack(-anchor => 'e', -side => 'left');
$rdb_delPrv_no->pack(-anchor => 'e', -side => 'left');

$lbl_caseSensitive->pack(-anchor => 'n', -side => 'left');
$rdb_caseSensitive_yes->pack(-anchor => 'n', -side => 'left');
$rdb_caseSensitive_no->pack(-anchor => 'n', -side => 'left');
$searchButton->pack(-anchor => 'n', -side => 'left');

#$exitButton->pack(-anchor => 'n', -side => 'left', -expand => 1, -fill => 'x');

########################### The Main Loop #############################################################

while (Tk::MainWindow->Count) {
	    DoOneEvent(ALL_EVENTS);
}

########################### Push button functions #####################################################

## Function to execute when "Find" button is pressed. ##
# As of yet I have not found a way to update a label with the amount of matching lines
# found.
#
sub action_on_search_pushButton {
    my $regex = $regexEnt->get();
    my $fileName = $fileEnt->get();
    my $foundCount = 0;
    my $lineCount  = 0;
    if ($fileName eq ""){
        print "Using file \"$searchFile\"\n";
        $fileName = $searchFile;
    }

#    $textareacontent->configure(-state => "normal");
    if($deletePrevious eq "Yes"){ # Do we want to delete the previous text on the screen?
        $textareacontent->delete('1.0', 'end');
    }
    $textareacontent->insert('end',"\"$regex\" in file \"$fileName\":\n");
    if (open(FILE, "<", $fileName)){
        while(<FILE>){
           $lineCount++;
           if($caseSensitive eq "No"){ # Check for case sensitive option.
                if (m/$regex/i){
                    $foundCount++;
                    $textareacontent->insert('end', "$lineCount: $_");
                }
           } else {
                if (m/$regex/){
                    $foundCount++;
                    $textareacontent->insert('end', "$lineCount: $_");
                }
           }
        }
        print "Found: ", $foundCount, "\n";
#        $textareacontent->configure(-state => "disabled");
        close(FILE);
    } else {
        $textareacontent->insert('end', "Unable to open $fileName for reading.\n");
    }
}

########################### END OF FILE ################################################################
