#
# MultiSelect.pm
#
package Curses::Menu::MultiSelect;

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
use Hash::Util qw(lock_keys);
use Carp qw(croak cluck);
use Curses;

require Exporter;

@ISA = qw(Exporter Curses::Menu);
@EXPORT_OK = qw(MENU_CALLBACK_TOGGLE);

@EXPORT = qw(MENU_CALLBACK_TOGGLE);


### "constants"
sub MENU_CALLBACK_TOGGLE {
    my $menu = shift;

    my $itemkey = $menu->{items}->[$menu->{highlighted}];

    $menu->{selected}->{$itemkey} = not $menu->{selected}->{$itemkey};
}

my @badarg = qw(itemmap viewsize);

sub new {
    my $class = shift;
    my %args = (@_);

    my $newinst = {
	items => [],
	itemmap => {},	
	escapes => {},
	escaperows => 2,
	title => undef,

	selected => {},
	highlighted => 0,
	escaped => undef,
	viewsize => undef,
    };

    my $rv = bless $newinst, $class;
    lock_keys(%{$rv});

    for my $i (keys %args) {
	if ($i eq "items") {
	    $rv->additems($args{$i});
	} elsif (grep {$_ eq $i} @badarg) {
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
	    $self->{selected}->{$items->{$i}} = 0;
	}
    } elsif (UNIVERSAL::isa($items, "ARRAY")) {
	for my $i (@{$items}) {
	    if (grep {$_ eq $i} @{$self->{items}}) {
		croak "Attempted to add duplicate key \"".$i."\"";
	    }
	    push @{$self->{items}}, $i;
	    $self->{itemmap}->{$i} = $i;
	    $self->{selected}->{$i} = 0;
	}
    } else {
	croak "bad arguments passed to additems";
    }
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
    if ($sizex-9 < length($itemtext)) {
	$itemtext = substr $itemtext, 0, $sizex-12;
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
    addstr($window, $row, $minx+5, "[ ] ".$itemtext);

    if ($self->{selected}->{$itemkey} != 0) {
	addstr($window, $row, $minx+6, "X");
    }

    if ($self->{highlighted} == $itemnum) {
	# if highlighted, draw the arrow, and revert the reverse flag
	addstr($window, $row, $minx+1, "-->");
	attrset($window, A_NORMAL);
    }
}

sub selected {
    my $self = shift;
    my $newvalue = shift;
    
    if (not defined($newvalue)) {
	my @selected = grep {$self->{selected}->{$_} != 0} keys(%{$self->{selected}});
	return \@selected;
    } else {
	for my $k (keys %{$self->{selected}}) {
	    $self->{selected}->{$k} = 0;
	}
	for my $k (@{$newvalue}) {
	    if (exists $self->{selected}->{$k}) {
		$self->{selected}->{$k} = 1;
	    } else {
		croak "No such key \"$k\"";
	    }
	}
    }	
}

1;

__END__

=head1 NAME

Curses::Menu::MultiSelect - display a multi-selection menu using Curses

=head1 SYNOPSIS

 use Curses::Menu;
 use Curses::Menu::MultiSelect;

 my $menu = new Curses::Menu::MultiSelect(title => "A Menu");

 $menu->additem("Item One");
 $menu->additem("Item Two" => 2);
 $menu->addescape(KEY_ESC, "Cancel", MENU_RETURN, MENU_CANCEL);
 $menu->addescape(KEY_ENTER, "Select", MENU_RETURN, MENU_OK);
 $menu->addescape(ORD('j'), undef, MENU_CALL, \&MENU_UP);
 $menu->addescape(KEY_UP, "Prev Item", MENU_CALL, \&MENU_UP);

 $menu->selected($arrayref);

 $menu->display($window);

 if ($menu->escape() == MENU_OK) {
   @r2 = @{$menu->selected()};
 }

=head1 DESCRIPTION

  Curses::Menu::MultiSelect implements a multiple selection menu on
  top of Curses::Menu.

=head1 CONSTRUCTORS

  The constructor works the same as the Curses::Menu contstructor.

=head1 METHODS

  Only the methods overridded by Curses::Menu::MultiSelect are listed
  here.  Please refer to the Curses::Menu documentation for the rest
  of the methods.

=over 4

=item selected()

=item selected( $arrayref )

Returns or sets the selected item by key.  When provided no arguments,
it returns a reference to an array of menu item keys.

When calling it to set the selected items, it takes a reference for an
array of menu item keys.

=back

=head1 CALLBACKS

Menu::Curses::MultiSelect only defines one additional callback:

=over 4

=item MENU_CALLBACK_TOGGLE

Toggles the select status of the highlighted item.

=head1 CREDITS

Written by Chris Collins <xfire@xware.cx>.

Inspired partially by the long obsolete perlmenu package and my boss.

=cut
