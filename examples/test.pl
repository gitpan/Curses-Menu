#!/usr/bin/perl

use Curses;
use Curses::Menu;

my $win = initscr();
cbreak();
noecho();
nonl();


my $m = new Curses::Menu(title=>"Test Menu");

$m->additem("Item 1" => 1);
$m->additem("Item 2" => 2);
$m->additem("Item 3" => 3);

$m->addescape(KEY_PPAGE, "Prev Page", MENU_ACTION_CALL, \&MENU_CALLBACK_PGUP);
$m->addescape(KEY_NPAGE, "Next Page", MENU_ACTION_CALL, \&MENU_CALLBACK_PGDOWN);
$m->addescape(KEY_UP, undef, MENU_ACTION_CALL, \&MENU_CALLBACK_UP);
$m->addescape(KEY_DOWN, undef, MENU_ACTION_CALL, \&MENU_CALLBACK_DOWN);
$m->addescape(13, "Select", MENU_ACTION_RETURN, MENU_OK);
$m->addescape(27, "Cancel", MENU_ACTION_RETURN, MENU_CANCEL);

$m->selected(3);

$m->display($win);

endwin();

print "Escape Value: " . $m->escape() . "\n";
print "Selected Value: " . $m->selected() . "\n";

exit 0;
