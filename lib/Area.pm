package Area;

use 5.010;
use strict;
use warnings;

use List::Util qw(min max);

use overload '""' => \&string;


=head1 NAME

Area


=head1 DESCRIPTION


=head1 CONSTRUCTOR

=over 4

=item Area->new(GEOMETRY_STR)

I<GEOMETRY_STR> can have two forms:

=over 4

=item * NAME:WIDTHxHEIGHT+X+Y

=item * WIDTHxHEIGHT+X+Y

=back

=item Area->new(X, Y, WIDTH, HEIGHT)

Return a new C<Area> instance.

=cut
sub new
{
    my $class = shift;

    if (@_ == 1)
    {
	my $geom = shift;

	unless ($geom =~ /^(?:(\w+):)?(\d+)x(\d+)\+(\d+)\+(\d+)\z/)
	{
	    require Carp;
	    Carp::croak("Bad geom `$geom'\n")
	}

	return bless [ $4, $5, $2, $3, $1 ], ref($class) || $class
    }

    if (@_ == 4)
    {
	return bless [ @_ ], ref($class) || $class
    }

    require Carp;
    Carp::croak("usage: Area->new(GEOMETRY)\n       Area->new(x, y, w, h) (@_)")
}


=back

=head1 METHODS

=over 4

=item $obj->copy()

Return a new C<Area> copying the instance, except its name.

=cut
sub copy
{
    my $self = shift;

    $self->new(@{$self}[0 .. 3])
}


=item $obj->x()

Area left abscissa.

=cut
sub x
{
    shift->[0]
}


=item $obj->y()

Area top ordinate.

=cut
sub y
{
    shift->[1]
}


=item $obj->width()

Area width.

=cut
sub width
{
    shift->[2]
}


=item $obj->height()

Area height.

=cut
sub height
{
    shift->[3]
}


=item $obj->name([ NEW_NAME ])

If I<NEW_NAME> is defined, replace the C<name> of the L<Area> with it.

Return area name (can be C<undef>).

=cut
sub name
{
    my($self, $new_name) = @_;

    defined $new_name ? $self->[4] = $new_name : $self->[4]
}


=item $obj->x2()

Area right abscissa.

=cut
sub x2
{
    my $self = shift;
    $self->x + $self->width - 1
}


=item $obj->y2()

Area bottom ordinate.

=cut
sub y2
{
    my $self = shift;
    $self->y + $self->height - 1
}


=item $obj->area()

Return the area (C<width> x C<height>).

=cut
sub area
{
    my $self = shift;
    $self->width * $self->height
}


=item $obj->intersect(OTHER_AREA)

Return a new Area instance corresponding to the intersection between
the instance and I<OTHER_AREA>.

Return C<undef> when the both areas are disjointed.

=cut
sub intersect
{
    my($self, $other) = @_;

    # [other][self]
    return if $other->x2 < $self->x;

    # [self][other]
    return if $other->x > $self->x2;

    # [other]
    # [self]
    return if $other->y2 < $self->y;

    # [self]
    # [other]
    return if $other->y > $self->y2;

    my($x1, $x2, $y1, $y2);

    $x1 = max($other->x, $self->x);
    $x2 = min($other->x2, $self->x2);

    $y1 = max($other->y, $self->y);
    $y2 = min($other->y2, $self->y2);

    Area::->new($x1, $y1, $x2 - $x1 + 1, $y2 - $y1 + 1)
}


=item $obj->horizontal_union(OTHER_AREA)

Return horizontal Areas (up to 3) matching the union of instance and
I<OTHER_AREA>.

For example:

    +-------+              +-------+
    |       |		   |   1   |
    |   A   +-------+  =>  +-------+-------+
    |       |       |	   |       2       |
    +-------+   B   |	   +-------+-------+
            |       |	           |   3   |
            +-------+	           +-------+

=cut
sub horizontal_union
{
    my($self, $other) = @_;

    # [other]|[self] (perhaps common lines, but areas disjointed)
    return if $other->x2 < $self->x - 1;

    # [self]|[other] (perhaps common lines, but areas disjointed)
    return if $other->x > $self->x2 + 1;

    # No lines in common
    # [other] or [self]
    # [self]     [other]
    if ($other->y2 < $self->y or $other->y > $self->y2)
    {
        # Special case where 2 areas with same width can be join vertically
        if ($self->width == $other->width and $self->x == $other->x)
        {
            # [other]
            # [self-]
            if ($other->y2 + 1 == $self->y)
            {
                return Area::->new(
		    $self->x, $other->y,
		    $self->width, $self->height + $other->height);
            }

            # [self-]
            # [other]
            if ($self->y2 + 1 == $other->y)
            {
                return Area::->new(
		    $self->x, $self->y,
		    $self->width, $self->height + $other->height);
            }
        }
        return
    }

    # At least one line in common

    my $min_x = min($self->x, $other->x);   # most left point
    my $max_x = max($self->x2, $other->x2); # most right point
    my $max_width = $max_x - $min_x + 1;

    my($low, $hi) = $self->y < $other->y ? ($self, $other) : ($other, $self);
    my @res;

    #     [   ]    [   ]            [   ]    [   ]
    # [hi][low] or [low][hi] or [hi][low] or [low][hi]
    #     [   ]	   [   ]	[  ]              [  ]

    if ($hi->y != $low->y)
    {
	push(@res, Area::->new($low->x, $low->y,
			       $low->width, $hi->y - $low->y));
    }

    push(@res, Area::->new($min_x, $hi->y,
			   $max_width,
			   min($low->y2, $hi->y2) - max($low->y, $hi->y) + 1));

    if ($low->y2 != $hi->y2)
    {
	#     [   ]    [   ]
	# [hi][low] or [low][hi]
	#     [   ]    [   ]
	if ($hi->y2 < $low->y2)
	{
	    push(@res, Area::->new($low->x, $hi->y2 + 1,
				   $low->width, $low->y2 - $hi->y2));
	}
	#     [   ]    [   ]
	# [hi][low] or [low][hi]
	# [  ]              [  ]
	else
	{
	    push(@res, Area::->new($hi->x, $low->y2 + 1,
				   $hi->width, $hi->y2 - $low->y2));
	}
    }

    @res
}


=item $obj->vertical_union(OTHER_AREA)

Return vertical Areas (up to 3) matching the union of instance and
I<OTHER_AREA>.

For example:

    +-------+          +---+---+
    |   A   |          | 1 |   |
    +---+---+---+  =>  +---+ 2 +---+
        |   B   |          |   | 3 |
        +-------+          +---+---+

=cut
sub vertical_union
{
    my($self, $other) = @_;

    # [other]
    # ------- (perhaps common columns, but areas disjointed)
    # [self]
    return if $other->y2 < $self->y - 1;

    # [self]
    # ------- (perhaps common columns, but areas disjointed)
    # [other]
    return if $other->y > $self->y2 + 1;

    # No columns in common
    # [other][self] or [self][other]
    if ($other->x2 < $self->x or $other->x > $self->x2)
    {
        # Special case where 2 areas with same height can be join horizontally
        if ($self->height == $other->height and $self->y == $other->y)
        {
            # [other][self]
            if ($other->x2 + 1 == $self->x)
            {
                return Area::->new($other->x, $self->y,
				   $self->width + $other->width, $self->height);
            }

            # [self][other]
            if ($self->x2 + 1 == $other->x)
            {
                return Area::->new($self->x, $self->y,
				   $self->width + $other->width, $self->height);
            }
        }
        return
    }

    my $min_y = min($self->y, $other->y);   # top point
    my $max_y = max($self->y2, $other->y2); # bottom point
    my $max_height = $max_y - $min_y + 1;

    my($left, $right) = $self->x < $other->x
	? ($self, $other)
	: ($other, $self);

    my @res;

    # [--left--] or  [right]  or    [right] or [left]
    #  [right]     [--left--]    [left]          [right]
    if ($right->x != $left->x)
    {
	push(@res, Area::->new($left->x, $left->y,
			       $right->x - $left->x, $left->height));
    }

    push(@res, Area::->new(
	     $right->x, $min_y,
	     min($left->x2, $right->x2) - max($left->x, $right->x) + 1,
	     $max_height));

    if ($left->x2 != $right->x2)
    {
	# [--left--] or  [right]
	#  [right]     [--left--]
	if ($right->x2 < $left->x2)
	{
	    push(@res, Area::->new($right->x2 + 1, $left->y,
				   $left->x2 - $right->x2, $left->height));
	}
	#     [right] or [left]
	#  [left]          [right]
	else
	{
	    push(@res, Area::->new($left->x2 + 1, $right->y,
				   $right->x2 - $left->x2,
				   $right->height));
	}
    }

    @res
}


=item $obj->string()

Return the Area as a geometry string, as C<new> method accepts it.

=cut
sub string
{
    my $self = shift;
    sprintf('%s%dx%d+%d+%d',
	    defined $self->name ? $self->name .':' : '',
	    $self->width, $self->height, $self->x, $self->y)
}


=item $obj->display(GOTOXY_CODE)

Draw the rectangle corresponding to this Area using I<GOTOXY_CODE>
function reference to position the cursor:

    GOTOXY_CODE->(X, Y)

=cut
sub display
{
    my($self, $ref_gotoxy) = @_;

    my($x, $y) = ($self->x, $self->y);

    my $hline = '-' x ($self->width - 2);
    if (length $hline and defined(my $name = $self->name))
    {
	if (length($name) >= length($hline))
	{
	    $hline = substr($name, 0, length($hline));
	}
	else
	{
	    substr($hline, 0, length($name), $name);
	}
    }

    print $ref_gotoxy->($x, $y) . "+$hline+";

    my $x2 = $self->x2;
    for (my $h = $self->height - 2; $h > 0; $h--)
    {
	$y++;
	print $ref_gotoxy->($x, $y) . '|' . $ref_gotoxy->($x2, $y) . '|';
    }

    $y++;
    print $ref_gotoxy->($x, $y) . '+' . ('-' x ($self->width - 2)) . '+';
}

1;
__END__

=back

=cut
