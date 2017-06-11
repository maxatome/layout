package Layout;

use 5.010;
use strict;
use warnings;

use List::Util qw(min max);

use Area;


=head1 NAME

Layout - Group of areas


=head1 DESCRIPTION

Group of areas.


=head1 CONSTRUCTOR

=over 4

=item Layout->new(AREA_LIST)

I<AREA_LIST> is an instance of L<AreaList>.

=cut
sub new
{
    my($class, $monitors) = @_;

    bless
    {
        monitors => $monitors,
        horiz    => $monitors->horizontal_union, # =
        vert     => $monitors->vertical_union,   # ||
    }, ref($class) || $class
}


=back

=head1 MÉTHODES

=over 4

=item $obj->monitors()

Return the layout as an I<AreaList> instance.

=item $obj->horiz()

Return the layout "horizontalized" as an I<AreaList> instance.

=item $obj->vert()

Return the layout "verticalized" as an I<AreaList> instance.

=cut
BEGIN
{
    foreach my $func (qw(monitors horiz vert))
    {
        no strict 'refs';
        *$func = sub { shift->{$func} };
    }
}


=item $obj->_recenter_vertically(AREA)

For internal use only.

Called when I<AREA> (L<Area> instance) is out of layout to recenter it
vertically.

=cut
sub _recenter_vertically
{
    my($self, $far) = @_;

    #  |_V_|
    # L|   |R
    #  |___|
    #  | V |
    my $mit;

    my $big = $self->monitors->big_area;

    # In one of V areas?
    if ($far->x >= $big->x and $far->x <= $big->x2
	or $far->x2 >= $big->x and $far->x2 <= $big->x2)
    {
	# Take it back vertically
	$mit = $self->vert->intersect(Area::->new($far->x, $big->y,
						  $far->width, $big->height));
    }
    # On left? (L area)
    elsif ($far->x2 < $big->x)
    {
	# Take it back vertically with its right border at pos big->x
	$mit = $self->vert->intersect(Area::->new($big->x - $far->width + 1,
						  $big->y,
						  $far->width, $big->height));
    }
    # On right (R area)
    else
    {
	# Take it back vertically with its left border at pos big->x2
	$mit = $self->vert->intersect(Area::->new($big->x2, $big->y,
						  $far->width, $big->height));
    }

    $mit
}


=item $obj->_recenter_horizontally(AREA)

For internal use only.

Called when I<AREA> (L<Area> instance) is out of layout to recenter it
horizontally.

=cut
sub _recenter_horizontally
{
    my($self, $far) = @_;

    # ___T___
    # H|   |H
    # _|___|_
    #    B
    my $mit;

    my $big = $self->monitors->big_area;

    # In one of H areas?
    if ($far->y >= $big->y and $far->y <= $big->y2
	or $far->y2 >= $big->y and $far->y2 <= $big->y2)
    {
	# Take it back horizontally
	$mit = $self->horiz->intersect(Area::->new($big->x, $far->y,
						   $big->width, $far->height));
    }
    # On top? (T area)
    elsif ($far->x2 < $big->x)
    {
	# Take it back horizontally with its bottom border at pos big->y
	$mit = $self->vert->intersect(Area::->new($big->x,
						  $big->y - $far->height + 1,
						  $big->width, $far->height));
    }
    # On bottom (B areas)
    else
    {
	# Take it back horizontally with its top border at pos big->y2
	$mit = $self->vert->intersect(Area::->new($big->x, $big->y2,
						  $big->width, $far->height));
    }

    $mit
}


=item $obj->find_bottom_edge(AREA)

Return the layout bottom edge (ordinate) against which I<AREA>
(L<Area> instance) has to stop to stay visible.

=cut
sub find_bottom_edge
{
    my($self, $window) = @_;

    my $mit = $self->vert->intersect($window);

    unless ($mit->num)
    {
	# Out of screen, try to recenter the window
	$mit = $self->_recenter_vertically($window);
    }

    min(map { $_->y2 } $mit->areas)
}


=item $obj->find_top_edge(AREA)

Return the layout top edge (ordinate) against which I<AREA> (L<Area>
instance) has to stop to stay visible.

=cut
sub find_top_edge
{
    my($self, $window) = @_;

    my $mit = $self->vert->intersect($window);

    unless ($mit->num)
    {
	# Out of screen, try to recenter the window
	$mit = $self->_recenter_vertically($window);
    }

    max(map { $_->y } $mit->areas)
}


=item $obj->find_left_edge(AREA)

Return the layout left edge (abscissa) against which I<AREA> (L<Area>
instance) has to stop to stay visible.

=cut
sub find_left_edge
{
    my($self, $window) = @_;

    my $mit = $self->horiz->intersect($window);

    unless ($mit->num)
    {
	# Out of screen, try to recenter the window
	$mit = $self->_recenter_horizontally($window);
    }

    max(map { $_->x } $mit->areas)
}


=item $obj->find_right_edge(AREA)

Return the layout right edge (abscissa) against which I<AREA> (L<Area>
instance) has to stop to stay visible

=cut
sub find_right_edge
{
    my($self, $window) = @_;

    my $mit = $self->horiz->intersect($window);

    unless ($mit->num)
    {
	# Out of screen, try to recenter the window
	$mit = $self->_recenter_horizontally($window);
    }

    min(map { $_->x2 } $mit->areas)
}


=item $obj->full_horiz(AREA)

Return a new L<Area> instance corresponding to the I<AREA>
horizontally maximized in the layout.

Think of horizontal fullscreen across all monitors.

=cut
sub full_horiz
{
    my($self, $window) = @_;

    my $mit = $self->horiz->intersect($window);

    unless ($mit->num)
    {
	# Out of screen, try to recenter the window
	$mit = $self->_recenter_horizontally($window);
    }

    my $x = max(map { $_->x } $mit->areas);
    my $x2 = min(map { $_->x2 } $mit->areas);

    Area::->new($x, $window->y,
		$x2 - $x + 1, $window->height)
}


=item $obj->full_vert(AREA)

Return a new L<Area> instance corresponding to the I<AREA>
vertically maximized in the layout.

Think of vertical fullscreen across all monitors.

=cut
sub full_vert
{
    my($self, $window) = @_;

    my $mit = $self->vert->intersect($window);

    unless ($mit->num)
    {
	# Out of screen, try to recenter the window
	$mit = $self->_recenter_vertically($window);
    }

    my $y = max(map { $_->y } $mit->areas);
    my $y2 = min(map { $_->y2 } $mit->areas);

    Area::->new($window->x, $y,
		$window->width, $y2 - $y + 1)
}


=item $obj->full(AREA)

Return a new L<Area> instance corresponding to the I<AREA> maximized
in the layout.

Think of fullscreen across all monitors.

=cut
# Full on all monitors (biggest visible area)
sub full
{
    my($self, $window) = @_;

    my $full_horiz = $self->full_horiz($window);
    my $full_vert = $self->full_vert($window); # OK if $full_horiz OK

    my $full1 = $self->full_vert($full_horiz);
    my $full2 = $self->full_horiz($full_vert);

    $full1->area > $full2->area ? $full1 : $full2
}


=item $obj->full_horiz_1(AREA)

Return a new L<Area> instance corresponding to the I<AREA>
horizontally maximized in the biggest intersection area of the layout.

Think of horizontal fullscreen limited to only one monitor.

=cut
sub full_horiz_1
{
    my($self, $window) = @_;

    my $target = $self->full_1($window);

    my $y = max($window->y, $target->y);
    my $y2 = min($window->y2, $target->y2);
    Area::->new($target->x, $y,
		$target->width, $y2 - $y + 1)
}


=item $obj->full_vert_1(AREA)

Return a new L<Area> instance corresponding to the I<AREA> vertically
maximized in the biggest intersection area of the layout.

Think of vertical fullscreen limited to only one monitor.

=cut
sub full_vert_1
{
    my($self, $window) = @_;

    my $target = $self->full_1($window);

    my $x = max($window->x, $target->x);
    my $x2 = min($window->x2, $target->x2);
    Area::->new($x, $target->y,
		$x2 - $x + 1, $target->height)
}


=item $obj->full_1(AREA)

Return a new L<Area> instance corresponding to the I<AREA> maximized
in the biggest intersection area of the layout.

Think of fullscreen limited to only one monitor.

=cut
sub full_1
{
    my($self, $window) = @_;

    my $mit = $self->monitors->intersect($window);

    unless ($mit->num)
    {
	# Out of screen, try to recenter the window
	$mit = $self->_recenter_horizontally($window);
    }

    $mit->best_target($window)
}


=item $obj->display(GOTOXY_CODE[, KIND ])

Draw the layout using I<GOTOXY_CODE> function reference to position
the cursor:

    GOTOXY_CODE->(X, Y)

If defined, I<KIND> can be "horiz" or "vert" to draw the layout in its
horizontal or vertical form.

=cut
sub display
{
    my($self, $ref_gotoxy, $kind) = @_;

    $kind //= 'monitors';

    $self->$kind->display($ref_gotoxy);
}

1;
__END__

=back

=cut
