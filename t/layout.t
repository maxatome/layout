use strict;
use warnings;
use 5.010;

use Test::More;

use Layout;
use AreaList;

my $layout = Layout::->new(AreaList::->new("10x20+100+100", "20x10+110+100"));

# _recenter_horizontally
# ___T___
# H|   |H
# _|___|_
#    B

# In left H area
my $mit = $layout->_recenter_horizontally(Area::->new("10x10+50+105"));
is("$mit", "30x10+100+100 / 10x10+100+110");

# In right H area
$mit = $layout->_recenter_horizontally(Area::->new("10x10+180+105"));
is("$mit", "30x10+100+100 / 10x10+100+110");

# In T area
$mit = $layout->_recenter_horizontally(Area::->new("10x10+105+50"));
is("$mit", "30x10+100+100");

$mit = $layout->_recenter_horizontally(Area::->new("10x10+50+50")); # T left
is("$mit", "30x10+100+100");

$mit = $layout->_recenter_horizontally(Area::->new("10x10+180+50")); # T right
is("$mit", "30x10+100+100");

# In B area
$mit = $layout->_recenter_horizontally(Area::->new("10x10+105+180"));
is("$mit", "10x10+100+110");

$mit = $layout->_recenter_horizontally(Area::->new("10x10+50+180")); # B left
is("$mit", "10x10+100+110");

$mit = $layout->_recenter_horizontally(Area::->new("10x10+180+180")); # B right
is("$mit", "10x10+100+110");


# _recenter_vertically
#  |_V_|
# L|   |R
#  |___|
#  | V |

# In top V area
$mit = $layout->_recenter_vertically(Area::->new("10x10+105+50"));
is("$mit", "10x20+100+100 / 20x10+110+100");

# In bottom V area
$mit = $layout->_recenter_vertically(Area::->new("10x10+105+180"));
is("$mit", "10x20+100+100 / 20x10+110+100");

# In L area
$mit = $layout->_recenter_vertically(Area::->new("10x10+50+105"));
is("$mit", "10x20+100+100");

$mit = $layout->_recenter_vertically(Area::->new("10x10+50+50")); # L top
is("$mit", "10x20+100+100");

$mit = $layout->_recenter_vertically(Area::->new("10x10+50+180")); # L bottom
is("$mit", "10x20+100+100");

# In R area
$mit = $layout->_recenter_vertically(Area::->new("10x10+180+105"));
is("$mit", "20x10+110+100");

$mit = $layout->_recenter_vertically(Area::->new("10x10+180+50")); # L top
is("$mit", "20x10+110+100");

$mit = $layout->_recenter_vertically(Area::->new("10x10+180+180")); # L bottom
is("$mit", "20x10+110+100");


done_testing;
