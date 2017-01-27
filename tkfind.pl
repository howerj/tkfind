#!/usr/bin/perl -w
# Richard James Howe, 2013
#
# Simple Find utility, bulk of it (the TK code) found here:
#     http://www.perlmonks.org/?node_id=922840
# TODO:
# 	* Add line number option, displays the line number before the matched string.
# 	* Find out if it is possible to colorize the output strings (partially).
# 	* File dialog for selecting search file
# 	* Command line options
# 	* Expand search box to screen size/improve look of GUI
#

########################## Setup area ##################################################################

use strict;
use warnings;
use Tk;
require Tk::Font;

### Global Variables ###

my $defaultFile = "searchme.txt";

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
my $frm_name       = $mw->Frame();
my $regexLabel     = $frm_name->Label(-text=>"Regex:");
my $filenameLabel  = $frm_name->Label(-text=>"File Name:");
my $regexEnt       = $frm_name->Entry();
my $fileEnt        = $frm_name->Entry(-textvariable=>"$defaultFile");

### Check button opens and their labels/result variables. ####

## Delete previous search results on new search? ##
my $deletePrevious         = "Yes";
my $frm_deletePrevious     = $frm_name; # $mw->Frame();
my $lbl_deletePrevious     = $frm_deletePrevious->Label(-text=>"Delete previous results:");
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
my $frm_caseSensitive      = $frm_name; # $mw->Frame();
my $lbl_caseSensitive      = $frm_caseSensitive->Label(-text=>"Case Sensitive Search");
my $rdb_caseSensitive_yes  = $frm_caseSensitive->Radiobutton(
                             -text=>"Yes",
                             -value=>"Yes",  -variable=>\$caseSensitive
                           );
my $rdb_caseSensitive_no   = $frm_caseSensitive->Radiobutton(
                             -text=>"No",
                             -value=>"No",-variable=>\$caseSensitive
                           );

### The search button ###
			   #
my $searchButton           = $frm_name->Button(-text=>"Search", -command =>\&action_on_search_pushButton);

### Text Area ###

my $textarea               = $mw->Frame();
my $textareaFontUsed       = "systemfixed"; # Windows only, should change this.
my $textareaCharWidth      = $textarea->fontMeasure($textareaFontUsed, "W");  # Use "W" as it is a wide(est?) character just in case we are not using a fixed width font
my $textareacontent        = $textarea->Text(
                             -font   => $textareaFontUsed,
                             -width  => (($mw->screenwidth)/$textareaCharWidth) - 10,
                             -height => 40,
                             -wrap   => "none"
                           );
my $srl_y                  = $textarea->Scrollbar(-orient=>'v',-command=>[yview => $textareacontent]);
my $srl_x                  = $textarea->Scrollbar(-orient=>'h',-command=>[xview => $textareacontent]);
$textareacontent->configure(-yscrollcommand=>['set', $srl_y], -xscrollcommand=>['set',$srl_x]);

########################### Geometry Management #######################################################

$frm_name->grid(-row => 1, -column => 1, -columnspan => 1,  -pady => 10);

## Row 1 ##
$regexLabel->grid(-row => 1, -column => 1);
$regexEnt->grid(-row => 1, -column => 2);
$lbl_deletePrevious->grid(-row => 1, -column => 3);
$rdb_delPrv_yes->grid(-row => 1, -column => 4);
$rdb_delPrv_no->grid(-row => 1, -column => 5);

## Row 2 ##
$filenameLabel->grid(-row => 2, -column => 1);
$fileEnt->grid(-row => 2, -column => 2);
$lbl_caseSensitive->grid(-row => 2, -column => 3);
$rdb_caseSensitive_yes->grid(-row => 2, -column => 4);
$rdb_caseSensitive_no->grid(-row => 2, -column => 5);

$searchButton->grid(-row => 1, -column => 6,  -rowspan => 2, -padx => 10,  -sticky => "ns");

$textareacontent->grid(-row => 1, -column => 1);
$srl_y->grid(-row => 1, -column => 2, -sticky => "ns");
$srl_x->grid(-row => 2, -column => 1, -sticky => "ew");
$textarea->grid(-row => 4, -column => 1, -columnspan => 200);


########################### The Main Loop #############################################################

Tk::MainLoop;

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
        print "Using default file \"$defaultFile\"\n";
        $fileName = $defaultFile;
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
