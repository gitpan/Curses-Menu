#
# Menu.pm
#
package Curses::Menu;

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION);
use Hash::Util qw(lock_keys);
use Carp qw(croak cluck);
use Curses;

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(MENU_ACTION_RETURN MENU_ACTION_CALL MENU_ACTION_NOP
		MENU_OK MENU_CANCEL
		MENU_CALLBACK_UP MENU_CALLBACK_DOWN
		MENU_CALLBACK_PGUP MENU_CALLBACK_PGDOWN);

@EXPORT = qw(MENU_ACTION_RETURN MENU_ACTION_CALL MENU_ACTION_NOP
	     MENU_OK MENU_CANCEL
	     MENU_CALLBACK_UP MENU_CALLBACK_DOWN
	     MENU_CALLBACK_PGUP MENU_CALLBACK_PGDOWN);

$VERSION = "1.00";


### "constants"
sub MENU_ACTION_RETURN {
    return 2;
}
sub MENU_ACTION_CALL {
    return 1;
}
sub MENU_ACTION_NOP {
    return 0;
}
sub MENU_CANCEL {
    return -1;
}
sub MENU_OK {
    return 0;
}

sub MENU_CALLBACK_UP {
    my $menu = shift;

    if ($menu->{highlighted} > 0) {
	$menu->{highlighted}--;
    } else {
	beep();
    }
}

sub MENU_CALLBACK_DOWN {
    my $menu = shift;

    if ($menu->{highlighted} < $#{$menu->{items}}) {
	$menu->{highlighted}++;
    } else {
	beep();
    }    
}

sub MENU_CALLBACK_PGUP {
    my $menu = shift;

    if ($menu->{highlighted} > 0) {
	$menu->{highlighted} -= $menu->{viewsize};
	if ($menu->{highlighted} < 0) {
	    $menu->{highlighted} = 0;
	}
    } else {
	beep();
    }
}

sub MENU_CALLBACK_PGDOWN {
    my $menu = shift;

    if ($menu->{highlighted} < $#{$menu->{items}}) {
	$menu->{highlighted} += $menu->{viewsize};
	if ($menu->{highlighted} > $#{$menu->{items}}) {
	    $menu->{highlighted} = $#{$menu->{items}};
	}
    } else {
	beep();
    }
}

my @badarg = qw(itemmap viewsize items itemmap escapes 
		selected highlighted escaped);
sub new {
    my $class = shift;
    my %args = (@_);

    my $newinst = {
	items => [],
	itemmap => {},	
	escapes => {},
	escaperows => 2,
	title => undef,

	selected => undef,
	highlighted => 0,
	escaped => undef,
	viewsize => undef,
    };

    my $rv = bless $newinst, $class;
    lock_keys(%{$rv});

    for my $i (keys %args) {
	if (grep {$_ eq $i} @badarg) {
	    croak "Illegal argument \"".$i."\"";
	} elsif (exists $rv->{$i}) {
	    $rv->{$i} = $args{$i};
	} else {
	    croak "Unknown option \"".$i."\"";
	}
    }

    return $rv;
}

sub additems {
    my $self = shift;
    my $items = shift;
    
    # unwind the items correctly.
    if (UNIVERSAL::isa($items, "HASH")) {
	for my $i (keys %{$items}) {
	    if (grep {$_ eq $items->{$i}} @{$self->{items}}) {
		croak "Attempted to add duplicate key \"".$items->{$i}."\"";
	    }
	    push @{$self->{items}}, $items->{$i};
	    $self->{itemmap}->{$items->{$i}} = $i;
	}
    } elsif (UNIVERSAL::isa($items, "ARRAY")) {
	for my $i (@{$items}) {
	    if (grep {$_ eq $i} @{$self->{items}}) {
		croak "Attempted to add duplicate key \"".$i."\"";
	    }
	    push @{$self->{items}}, $i;
	    $self->{itemmap}->{$i} = $i;
	}
    } else {
	croak "bad arguments passed to additems";
    }
}

sub additem {
    my $self = shift;

    if ($#_ == 0) {
	$self->additems([@_]);
    } elsif ($#_ == 1) {
	$self->additems({@_});
    } else {
	croak "bad arguments passed to additem";
    }
}

sub addescape {
    my $self = shift;
    my $keycode = shift;
    my $label = shift;
    my $action = shift;
    my $argument = shift;

    $self->{escapes}->{$keycode} = {
	label => $label,
	action => $action,
	argument => $argument,
    };
    lock_keys(%{$self->{escapes}->{$keycode}});
}

sub drawitem {
    my $self = shift;
    my $window = shift;
    my $itemnum = shift;
    my $row = shift;
    
    my $minx; my $miny;
    getbegyx($window, $miny, $minx);
    my $maxx; my $maxy;   
    getmaxyx($window, $maxy, $maxx);
    my $sizex = $maxx-$minx;

    # prep item details
    my $itemkey = $self->{items}->[$itemnum];
    my $itemtext = $self->{itemmap}->{$itemkey};
    if ($sizex-5 < length($itemtext)) {
	$itemtext = substr $itemtext, 0, $sizex-8;
	$itemtext .= "...";
    }

    # draw the item
    if ($self->{highlighted} == $itemnum) {
	# if highlighted, use reverse video.
	attrset($window, A_REVERSE);
    }
    # blank the line.
    addstr($window, $row, $minx, " "x$sizex);

    # draw the label
    addstr($window, $row, $minx+5, $itemtext);

    if ($self->{highlighted} == $itemnum) {
	# if highlighted, draw the arrow, and revert the reverse flag
	addstr($window, $row, $minx+1, "-->");
	attrset($window, A_NORMAL);
    }
}

sub drawtitle {
    my $self = shift;
    my $window = shift;

    my $minx; my $miny;
    getbegyx($window, $miny, $minx);
    my $maxx; my $maxy;   
    getmaxyx($window, $maxy, $maxx);

    my $sizex = $maxx-$minx;
    my $sizey = $maxy-$miny;

    my $title = $self->{title};
    if (length($title) > $sizex) {
	$title = substr $title, 0, $sizex-1;
    }
    my $xoffs = ($sizex-length($title))/2;
    attrset($window, A_REVERSE);
    addstr($window, $miny, $minx, " "x$sizex);
    addstr($window, $miny, $minx + $xoffs, $title);
    attrset($window, A_NORMAL);
}

sub drawescapes {
    my $self = shift;
    my $window = shift;

    my $minx; my $miny;
    getbegyx($window, $miny, $minx);
    my $maxx; my $maxy;   
    getmaxyx($window, $maxy, $maxx);

    my $sizex = $maxx-$minx;
    my $sizey = $maxy-$miny;

    my @escapes = ();

    my $maxkeywidth = 0;
    my $maxlabelwidth = 0;

    for my $k (keys %{$self->{escapes}}) {
	if (not defined($self->{escapes}->{$k}->{label})) {
	    next;
	}
	my $kn = keyname($k);
	# strip the horrible KEY_ prefix that ncurses uses.
	$kn =~ s/KEY_//;
	# surpress stupid labels.
	if ($k == 13) {
	    $kn = "RETURN";
	} elsif ($k == 27) {
	    $kn = "ESC";
	}
	if (length($kn) > $maxkeywidth) {
	    $maxkeywidth = length($kn);
	}
	if (length($self->{escapes}->{$k}->{label}) > $maxlabelwidth) {
	    $maxlabelwidth = length($self->{escapes}->{$k}->{label});
	}
	
	push @escapes, [ $kn, $self->{escapes}->{$k}->{label} ];
    }

    my $mincellwidth = 6+$maxkeywidth+$maxlabelwidth;
    my $colcount = int($sizex / $mincellwidth);
    my $cellwidth = ($sizex-($colcount*$mincellwidth))/($colcount-1);
    $cellwidth += $mincellwidth;

    #FIXME: pick sensible drawing configuration.
    my $eoffs = $maxy - $self->{escaperows} - 1;
    for my $erow (1..$self->{escaperows}) {
	for my $ecol (1..$colcount) {
	    my $item = shift @escapes;
	   
	    my $kn = $item->[0];

	    my $label = $item->[1];

	    my $loffs = ($maxkeywidth-length($kn))/2;

	    attrset($window, A_REVERSE);
	    addstr($window, $eoffs+$erow,
		   (($ecol-1)*$cellwidth),
		   " "x($maxkeywidth+2));
	    addstr($window, $eoffs+$erow, 
		   (($ecol-1)*$cellwidth)+1+$loffs,
		   $kn);
	    attrset($window, A_NORMAL);
	    addstr($window, $eoffs+$erow, 
		   (($ecol-1)*$cellwidth)+$maxkeywidth+3,
		   $label);
	    if ($#escapes < 0) {
		last;
	    }
	}
	if ($#escapes < 0) {
	    last;
	}
    }
}

sub display {
    my $self = shift;
    my $window = shift;

    my $minx; my $miny;
    getbegyx($window, $miny, $minx);
    my $maxx; my $maxy;   
    getmaxyx($window, $maxy, $maxx);

    my $sizex = $maxx-$minx;
    my $sizey = $maxy-$miny;

    $self->{viewsize} = $sizey - $self->{escaperows} - 3;
    if ($self->{viewsize} < 1) {
	# less rows than the escaperows + 1 for title + 2 for
	# prev/next indicators, + 1 for items
	croak "Terminal too small for menu: $sizey < ".scalar($self->{escaperows} + 4);
    }
    
    intrflush($window, 0);
    keypad($window, 1);
    
    my $listoffs = 0;
    
    $self->drawtitle($window);
    $self->drawescapes($window);

    my $lastlistoffs = -1;
    my $lasthighlight = -1;
    while (1) {
	$listoffs = ($self->{highlighted} / $self->{viewsize});
	$listoffs = int($listoffs) * $self->{viewsize};	    

	if ($lastlistoffs != $listoffs) {
	    for my $i (0..($self->{viewsize}-1)) {
		if ($i+$listoffs > $#{$self->{items}}) {
		    last;
		}

		$self->drawitem($window, $i+$listoffs, $miny+2+$i);
	    }
	} else {
	    if ($self->{highlighted} != $lasthighlight) {
		$self->drawitem($window, $lasthighlight, 
				$lasthighlight-$listoffs+2+$miny);
	    }
	    $self->drawitem($window, $self->{highlighted}, 
			    $self->{highlighted}-$listoffs+2+$miny);
	}
	$lastlistoffs = $listoffs;
	$lasthighlight = $self->{highlighted};

	if ($self->{highlighted} >= $listoffs and $self->{highlighted} < $listoffs+$self->{viewsize}) {
	    move($window, $miny+2+($self->{highlighted}-$listoffs), $maxx-1);
	} else {
	    move($window, $miny+1, $maxx-1);
	}

	doupdate();

	my $key = getch($window);
	my $escape = undef;
	if (exists($self->{escapes}->{$key})) {
	    $escape = $self->{escapes}->{$key};
 	} elsif (exists($self->{escapes}->{ord($key)})) {
	    $escape = $self->{escapes}->{ord($key)};
	}
	if (defined($escape)) {
	    if ($escape->{action} == MENU_ACTION_NOP) {
		# do nothing
	    } elsif ($escape->{action} == MENU_ACTION_CALL) {
		&{$escape->{argument}}($self);
	    } elsif ($escape->{action} == MENU_ACTION_RETURN) {
		$self->{escaped} = $escape->{argument};
		return;
	    } else {
		beep();
	    }
	}
    }    
}

sub highlighted {
    my $self = shift;
    my $newvalue = shift;
    
    if (not defined($newvalue)) {
	return $self->{items}->[$self->{highlighted}];
    }
    if (exists $self->{itemmap}->{$newvalue}) {
	for my $i (0 .. $#{$self->{items}}) {
	    if ($self->{items}->[$i] eq $newvalue) {
		$self->{highlighted} = $i;
		return;
	    }
	}
	die "BUG:  Couldn't find item \"$newvalue\".";
    } else {
	croak "No such item \"$newvalue\"";
    }
}

sub selected {
    my $self = shift;
    my $newvalue = shift;
    
    if (not defined($newvalue)) {
	return $self->highlighted();
    } else {
	$self->highlighted($newvalue);
    }
}

sub escape {
    my $self = shift;

    return $self->{escaped};
}

1;

__END__


=head1 NAME

Curses::Menu - display menus for selecting items using Curses

=head1 SYNOPSIS

 use Curses::Menu;

 my $menu = new Curses::Menu(title => "A Menu");

 $menu->additem("Item One");
 $menu->additem("Item Two" => 2);
 $menu->addescape(KEY_ESC, "Cancel", MENU_RETURN, MENU_CANCEL);
 $menu->addescape(KEY_ENTER, "Select", MENU_RETURN, MENU_OK);
 $menu->addescape(ORD('j'), undef, MENU_CALL, \&MENU_UP);
 $menu->addescape(KEY_UP, "Prev Item", MENU_CALL, \&MENU_UP);

 $menu->selected($value);

 $menu->display($window);

 if ($menu->escape() == MENU_OK) {
   $r3 = $menu->selected();
 }

=head1 DESCRIPTION

  Curses::Menu implements a flexible text menu system.  An object of
  this class represents a menu.

=head1 CONSTRUCTORS

  The following method constructs a Curses::Menu object:

=over 4

=item $menu = Curses::Menu->new( %options );

=back

The following options are supported:

=over 4

=item title

The title to display when presenting this menu.

=item escaperows

The number of rows to use for displaying escape keys (default: 2)

=back

=head1 METHODS

The methods described in this section can be called on a
Curses::Method object.

=over 4

=item additem ( $item )

=item additem ( $item => $keyvalue )

Adds an item to the menu.  If a key value is not provided, the item
value will be used instead.  The key value must be unique.

=item addescape ( $keycode, $label, $actions, $argument )

Adds an escape to the menu.  Escapes are action keys that perform some
kind of action from moving the highlight, to calling callback
functions.

This module only implements 3 actions: MENU_ACTION_NOP, MENU_ACTION_CALL and
MENU_ACTION_RETURN.

MENU_ACTION_NOP does nothing (and supresses the unknown key beep as a
result).

MENU_ACTION_CALL calls the subref specified in the argument field with
the object reference as its first argument.

MENU_ACTION_RETURN causes the menu to return, setting the escape value
to the argument.

=item display( $window )

Displays the menu.  $window must be a valid curses window.  display
only returns when a escape is triggered with an action of
MENU_ACTION_RETURN.

=item escape()

Returns the argument of the escape used to exit the menu.  Not defined
if called before display().

=item selected()

=item selected( $newvalue )

Returns or sets the selected item by key.

=back

=head1 CALLBACKS

The module defines a number of useful callbacks which you will
probably want to use with your menu.

=over 4

=item MENU_CALLBACK_UP

Moves the highlight up one item.

=item MENU_CALLBACK_DOWN

Moves the highlight down one item.

=item MENU_CALLBACK_PGUP

Moves the highlight up a screenful of items.

=item MENU_CALLBACK_PGDOWN

Moves the highlight down a screenful of items.

=head1 CREDITS

Written by Chris Collins <xfire@xware.cx>.

Inspired partially by the long obsolete perlmenu package and my boss.

=cut
