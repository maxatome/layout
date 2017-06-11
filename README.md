# layout

POC: algorithms needed to integrate Xrandr in ctwm.

This project allows to simulate a serie of functions needed
when [ctwm](http://www.ctwm.org) will integrate Xrandr extension.

A layout is a set of areas (in fact monitors).

Using Xrandr with more than one monitor raises some problems for ctwm
when the monitors do not have the same size.

For example, one can have 3 monitors using the following layout and
one window:

```
+0---------------------------++1---------------------------++3------------+
|                            ||                            ||             |
|                            ||                            ||             |
|                            ||                            ||             |
|                            ||                            ||             |
|                            ||                            ||             |
|            +window------------+                          ||             |
|            |               || |                          ||             |
|            |               || |                          ||             |
|            |               || |                          ||             |
|            |               || |                          ||             |
|            |               || |                          ||             |
|            |               || |                          ||             |
|            |               || |                          ||             |
|            |               || |                          |+-------------+
|            +------------------+                          |
|                            ||                            |
|                            ||                            |
|                            ||                            |
+----------------------------++----------------------------+
```

Want to horizontally shift most right the window but keeping it visible?
Want to maximize it accross all monitors, still keeping it fully visible?
Want to maximize it in only one monitor?
...

To achieve all possible tasks, one needs 10 functions.

Each function below takes a window (or area) as parameter:
- bottomEdge: detect the bottom edge of the monitors layout for this window;
- topEdge: detect the top edge of the monitors layout for this window;
- leftEdge: detect the left edge of the monitors layout for this window;
- rightEdge: detect the right edge of the monitors layout for this window;
- full: maximize the window across all possible monitors, but staying
  fully visible;
- fullHoriz: horizontally maximize the window across all possible
  monitors, but staying fully visible;
- fullVert: vertically maximize the window across all possible
  monitors, but staying fully visible;
- monitorFull: maximize the window in only one monitor;
- monitorFullHoriz: horizontally maximize the window in only one monitor;
- monitorFullVert: vertically maximize the window in only one monitor.

With `layout.pl` one can simulate all these functions.

```sh
$ ./layout.pl
usage: ./layout.pl LAYOUT_FILE WIN_GEOMETRY
```

Several monitors layouts are given in `layouts/` directory.

`WIN_GEOMETRY` is a classic X11 geometry `WIDTHxHEIGHT+X+Y`. Note that
a name can be given as in `NAME:WIDTHxHEIGHT+X+Y`.

Geometries like `WIDTHxHEIGHT-X-Y` are not allowed. Only `+`.

Example of use:

```sh
$ ./layout.pl layouts/layout4.txt window:20x10+13+6

bottomEdge topEdge leftEdge rightEdge full fullHoriz fullVert monitorFull
monitorFullHoriz monitorFullVert HorizLayout VertLayout clear quit:
+0-----------------++1-----------------+
|                  ||                  |
|                  ||                  |
|                  ||                  |
|                  ||                  |
|                  ||                  |
|            +window------------+      |
|            |     ||           |      |
|            |     ||           |      |
+------------|-----++-----------|------+
+2-------++3-|---------------++4|------+
|        ||  |               || |      |
|        ||  |               || |      |
|        ||  |               || |      |
|        ||  |               || |      |
|        ||  +------------------+      |
|        ||                  ||        |
|        ||                  ||        |
|        ||                  ||        |
+--------++------------------++--------+
```

Each function listed above can be simulating, by typing the
bold-underlined character + `Return`.

Type q + Return to quit.

`HorizLayout` and `VertLayout` allow to show other internal
representations of the layout, respectively horizontalized and
verticalized for debug only.

Try it.
