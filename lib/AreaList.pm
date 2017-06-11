package AreaList;

use 5.010;
use strict;
use warnings;

use overload '""' => \&string;

use Area;


=head1 NAME

AreaList - List of Area instances


=head1 DESCRIPTION

List of L<Area> instances.


=head1 CONSTRUCTOR

=over 4

=item AreaList->new(AREA | GEOMETRY_STR, ...)

I<AREA> is instance of L<Area>.

I<GEOMETRY_STR> is a geometry string. See the C<new> constructor of L<Area>.

=cut
sub new
{
    my $class = shift;

    bless [ map { ref eq 'Area' ? $_ : Area::->new($_) } @_ ],
	ref($class) || $class
}


=back

=head1 METHODS

=over 4

=item $obj->copy()

Return a new C<AreaList> copying the instance. Note that L<Area>
instances are not copied.

=cut
sub copy
{
    my $self = shift;

    bless [ @$self ], ref($self)
}


=item $obj->string()

Return a string of all geometries of areas of the list.

=cut
sub string
{
    join(' / ', map "$_", @{shift()})
}


=item $obj->areas()

Return the list of L<Area>.

=cut
sub areas
{
    @{shift()}
}


=item $obj->num()

Number of areas in the list.

=cut
sub num
{
    scalar @{shift()}
}


=item $obj->horizontal_union()

Like C<horizontal_union> of L<Area> but for this list of L<Area>s.

=cut
sub horizontal_union
{
    my $copy = shift->copy;

  refine:
    @$copy = sort { $a->x <=> $b->x or $a->y <=> $b->y } @$copy;

    for (my $i = 0; $i < @$copy - 1; $i++)
    {
        for (my $j = $i + 1; $j < @$copy; $j++)
        {
            if (my @repl = $copy->[$i]->horizontal_union($copy->[$j]))
            {
                splice(@$copy, $j, 1);
                splice(@$copy, $i, 1);
                push(@$copy, @repl);
                goto refine
            }
        }
    }

    $copy
}


=item $obj->vertical_union()

Like C<vertical_union> of L<Area> but for this list of L<Area>s.

=cut
sub vertical_union
{
    my $copy = shift->copy;

  refine:
    @$copy = sort { $a->y <=> $b->y or $a->x <=> $b->x } @$copy;

    for (my $i = 0; $i < @$copy - 1; $i++)
    {
        for (my $j = $i + 1; $j < @$copy; $j++)
        {
            if (my @repl = $copy->[$i]->vertical_union($copy->[$j]))
            {
                splice(@$copy, $j, 1);
                splice(@$copy, $i, 1);
                push(@$copy, @repl);
                goto refine
            }
        }
    }

    $copy
}


=item $obj->intersect(AREA)

Return new L<AreaList> with only areas that intersect with I<AREA>.

=cut
sub intersect
{
    my($self, $area) = @_;

    $self->new(grep { defined $_->intersect($area) } @$self)
}


=item $obj->big_area()

Return an L<Area> instance that contains all the list areas.

=cut
sub big_area
{
    my $self = shift;

    my($x, $y, $x2, $y2);

    foreach my $area (@$self)
    {
        $x = $area->x if not defined $x or $area->x < $x;
        $y = $area->y if not defined $y or $area->y < $y;

        $x2 = $area->x2 if not defined $x2 or $area->x2 > $x2;
        $y2 = $area->y2 if not defined $y2 or $area->y2 > $y2;
    }

    Area::->new($x, $y,
		$x2 - $x + 1, $y2 - $y + 1)
}


=item $obj->best_target(AREA)

Return the area of the list with the greater intersection with I<AREA>.

=cut
sub best_target
{
    my($self, $window) = @_;

    my($max_area, $full_area);
    foreach my $area ($self->areas)
    {
	my $it = $window->intersect($area);
	if (not defined $max_area or $it->area > $max_area)
	{
	    $max_area = $it->area;
	    $full_area = $area;
	}
    }

    $full_area
}


=item $obj->display()

Draw the rectangles corresponding to each Area using I<GOTOXY_CODE>
function reference to position the cursor:

    GOTOXY_CODE->(X, Y)

=cut
sub display
{
    my($self, $ref_gotoxy) = @_;

    foreach my $area (@$self)
    {
	$area->display($ref_gotoxy);
    }
}

1;
__END__

=back

=cut
