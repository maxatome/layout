#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Term::Cap;

use lib 'lib';
use Layout;
use Area;
use AreaList;


if (@ARGV != 2 or $ARGV[0] =~ /^--?h/)
{
    die "usage: $0 LAYOUT_FILE WIN_GEOMETRY\n";
}

my($LAYOUT_FILE, $WIN_GEOMETRY) = @ARGV;

my $area_list;
if (open(my $fh, '<', $LAYOUT_FILE))
{
    my @areas;
    while (defined(my $line = <$fh>))
    {
	# Comment line
	next if $line =~ /^\s*#/;

	chomp($line);

	# Delete EOL comment
	$line =~ s/\s*#.*//;

	push(@areas, $line);
    }
    close $fh;

    @areas or die "$LAYOUT_FILE does not contain any Area!\n";

    $area_list = AreaList->new(@areas);
}
else
{
    die "Cannot open layout file $LAYOUT_FILE: $!\n"
}

my $window = Area->new($WIN_GEOMETRY);

my $term = Term::Cap::->Tgetent(
    { OSPEED => do
      {
	  use POSIX;
	  my $termios = new POSIX::Termios;
	  $termios->getattr;
	  my $ospeed = $termios->getospeed;
      } });

$term->Trequire(qw(md us me AF cl ce));

my $B = $term->Tputs('md'); # bold
my $U = $term->Tputs('us'); # underline
my $O = $term->Tputs('me'); # turn off all attributes
my $CEOL = $term->Tputs('ce'); # clear to end of line

my $MAGENTA = $term->Tgoto('AF', 0, 5);
my $GREEN = $term->Tgoto('AF', 0, 2);
my $RED = $term->Tgoto('AF', 0, 1);
my $YELLOW = $term->Tgoto('AF', 0, 3);


sub clear ()
{
    $term->Tputs('cl')
}

sub end ()
{
    clear;
    exit 0
}

sub real_gotoxy ($$)
{
    my($col, $line) = @_;

    $term->Tgoto('cm', $col, $line)
}

sub gotoxy ($$)
{
    my($col, $line) = @_;

    real_gotoxy($col, $line + 3)
}

sub hline ($$$)
{
    my($x1, $y, $x2) = @_;

    gotoxy($x1, $y) . '-' x ($x2 - $x1 + 1)
}

sub vline ($$$)
{
    my($x, $y1, $y2) = @_;

    my $ret;
    while ($y1 <= $y2)
    {
	$ret .= gotoxy($x, $y1++) . '|';
    }
    $ret
}

sub title ($)
{
    my $title = shift;

    print real_gotoxy(0, 0) . "$B$title"
}


sub menu ()
{
    local $| = 1;
    for (;;)
    {
	print real_gotoxy(0, 1)
	    . "$B${U}b${O}ottomEdge $B${U}t${O}opEdge "
	    . "$B${U}l${O}eftEdge $B${U}r${O}ightEdge "
	    . "$B${U}f${O}ull full$B${U}H${O}oriz "
	    . "full$B${U}V${O}ert monitorF$B${U}u${O}ll\n"
	    . "monitorFullH$B${U}o${O}riz monitorFullV$B${U}e${O}rt "
	    . "Hori$B${U}z${O}Layout VertL$B${U}a${O}yout "
	    . "$B${U}c${O}lear $B${U}q${O}uit: "
	    . $CEOL;

	chomp(my $resp = <STDIN> // end);

	$resp = lc $resp;
	return $resp if $resp =~ /^[btlrfhvuoeazcq]\z/;
    }
}

my %edge_actions = (b => 'Bottom edge',
		    t => 'Top edge',
		    l => 'Left edge',
		    r => 'Right edge');

my %w_methods = (
    f => { title => 'Full',                    func => 'full' },
    h => { title => 'Full Horizontal',         func => 'full_horiz' },
    v => { title => 'Full Vertical',           func => 'full_vert' },
    u => { title => 'Monitor Full',            func => 'full_1' },
    o => { title => 'Monitor Full Horizontal', func => 'full_horiz_1' },
    e => { title => 'Monitor Full Vertical',   func => 'full_vert_1' },
    );

my %layout_methods = (
    z => { title => 'Layout horizontalized', func => 'horiz' },
    a => { title => 'Layout verticalized',   func => 'vert' },
    );

my $layout = Layout->new($area_list);

print clear;
$layout->display(\&gotoxy);

print $GREEN;
$window->display(\&gotoxy);
print $O;

for (;;)
{
    my $choice = menu;

    print clear;
    $layout->display(\&gotoxy);

    print $GREEN;
    $window->display(\&gotoxy);

    if (defined(my $ref = $w_methods{$choice}))
    {
	my $method = $ref->{func};

	my $w = $layout->$method($window);
	$w->name($ref->{title});

	print $MAGENTA;
	$w->display(\&gotoxy);
	title($ref->{title});
    }
    # Edges detections
    elsif (defined(my $title = $edge_actions{$choice}))
    {
	my $big = $layout->monitors->big_area;

	print $RED;

	if ($choice eq 'b')
	{
	    my $y = $layout->find_bottom_edge($window);

	    print hline($big->x, $y, $big->x2);
	}
	elsif ($choice eq 't')
	{
	    my $y = $layout->find_top_edge($window);

	    print hline($big->x, $y, $big->x2);
	}
	elsif ($choice eq 'l')
	{
	    my $x = $layout->find_left_edge($window);

	    print vline($x, $big->y, $big->y2);
	}
	elsif ($choice eq 'r')
	{
	    my $x = $layout->find_right_edge($window);

	    print vline($x, $big->y, $big->y2);
	}

	title($title);
    }
    # Layout
    elsif (defined($ref = $layout_methods{$choice}))
    {
	print $YELLOW;

	$layout->display(\&gotoxy, $ref->{func});

	title($ref->{title});
    }

    print $O;

    # Quit
    last if $choice eq 'q';
}

end;
