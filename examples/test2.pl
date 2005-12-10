#!/usr/bin/perl

use Curses;
use Curses::Menu;
use Curses::Menu::MultiSelect;

my $win = initscr();
cbreak();
noecho();
nonl();


my $m = new Curses::Menu::MultiSelect(title=>"Test Menu");

$m->additem("Item 1" => 1);
$m->additem("Item 2" => 2);
$m->additem("Item 3" => 3);

$m->addescape(KEY_PPAGE, "Prev Page", MENU_ACTION_CALL, \&MENU_CALLBACK_PGUP);
$m->addescape(KEY_NPAGE, "Next Page", MENU_ACTION_CALL, \&MENU_CALLBACK_PGDOWN);
$m->addescape(KEY_UP, undef, MENU_ACTION_CALL, \&MENU_CALLBACK_UP);
$m->addescape(KEY_DOWN, undef, MENU_ACTION_CALL, \&MENU_CALLBACK_DOWN);
$m->addescape(ord(" "), undef, MENU_ACTION_CALL, \&MENU_CALLBACK_TOGGLE);
$m->addescape(ord('x'), "Toggle Selection", MENU_ACTION_CALL, \&MENU_CALLBACK_TOGGLE);
$m->addescape(13, "Continue", MENU_ACTION_RETURN, MENU_OK);
$m->addescape(27, "Cancel", MENU_ACTION_RETURN, MENU_CANCEL);

$m->selected([1,3]);

$m->display($win);

endwin();

my $selected = $m->selected();
print "Escape Value: " . $m->escape() . "\n";
print "Selected Value: " . join(", ", @{$selected}) . "\n";

exit 0;
