#!/usr/bin/perl

use strict;
use warnings;

############################## Class Figure ####################################
package Figure;
use Scalar::Util qw(blessed);

sub new {
    # In the constructor, the $class variable contains the name of the caller.
    my $class = shift; 
    my $color = pop @_;
    my @pts = @_;

    if (eval @pts < 4) {
        die "Error: There are no enough points to form the \"$class\". " .
                "The minimum number of pairs is 2.\n";
    }
    elsif (eval @pts % 2) {
        die "Error: Incomplete points list to form the \"$class\". " .
                "Points must be entered in pairs: \"X1,Y1 ... Xn,Yn\".\n";
    }

    for (my $i=0; $i<scalar @pts; $i+=2)  {
        for (my $j=$i+2; $j<scalar @pts; $j+=2)  {
            if ($pts[$i] == $pts[$j] and $pts[$i+1] == $pts[$j+1]) {
                die "Error: The point \"$pts[$i],$pts[$i+1]\" " .
                        "is redundant in the points list.\n"
            }
        }
    }

    # TODO No complex polygons are checked.

    my $attr = bless {
        color  => $color, # Figure color.
        points => \@pts   # Figure point list.
    }, $class;

    return $attr;
}

sub color { # ro accessor
    my $self = shift;
    return if not blessed $self;

    return $self->{color};
}

sub points { # ro accessor
    my $self = shift;
    return if not blessed $self;

    return @{$self->{points}};
}

sub area { # Function based on the shoelace algorithm.
    my $self = shift;
    return if not blessed $self;

    my @pts = $self->points();
    my $lace = ($pts[$#_-1] * $pts[1]) - ($pts[$#_] * $pts[0]);
    for (my ($x, $y)=(2, 3); $y<scalar @pts; $x+=2, $y+=2) {
        $lace += ($pts[$x-2] * $pts[$y]) - ($pts[$y-2] * $pts[$x]); 
    }

    return $lace < 0 ? -$lace/2 : $lace/2;
}

sub render {
    my $self = shift;
    return if not blessed $self;
    Graphics::render_figure($self, 'polygon');
}

############################## Class Rectangle #################################
package Rectangle;
use parent -norequire, "Figure";

sub new {
    my $class = shift;
    my $color = pop @_;

    if (scalar @_ != 4) {
        die "Error: Wrong number of points to form the \"$class\". " .
                "There must be exactly 2 pairs: \"X1,Y1 X2,Y2\".\n";
    }

    # Generalizing the 'Rectangle' in a 'Figure': (X1,Y1, X2,Y1, X2,Y2, X1,Y2).
    my @points = ($_[0], $_[1], $_[2], $_[1], $_[2], $_[3], $_[0], $_[3]);

    return $class->SUPER::new(@points, $color);
}

############################## Class Square ####################################
package Square;
use parent -norequire, "Rectangle";

sub new {
    my $class = shift;
    my $color = pop @_;

    my $self = $class->SUPER::new(@_, $color);
    my ($x1, $y1, $x2, $y2) = @_;

    if (($x2 - $x1) != ($y2 - $y1)) {
        die "Error: The points pair: \"$x1,$y1 $x2,$y2\" not form a Square.\n";
    }

    return $self;
}

############################## Class Triangle ##################################
package Triangle;
use parent -norequire, "Figure";

sub new {
    my $class = shift;
    my $color = pop @_;

    if (scalar @_ != 6) {
        die "Error: Wrong number of points to form the \"$class\". " .
                "There must be exactly 3 pairs: \"X1,Y1 X2,Y2 X3,Y3\".\n";
    }

    return $class->SUPER::new(@_, $color);
}

############################## Class Circle ####################################
package Circle;
use Math::Trig;
use parent -norequire, "Figure";

sub new {
    my $class = shift;
    my $color = pop @_;

    if (scalar @_ != 4) {
        die "Error: Wrong number of points to form the \"$class\". " .
                "There must be exactly 2 pairs: \"X1,Y1 X2,Y2\".\n";
    }

    return $class->SUPER::new(@_, $color);
}

sub area {
    my $self = shift;
    return if not blessed $self;
    my $rad = Graphics::radius($self->points());

    return pi * $rad * $rad;
}

sub render {
    my $self = shift;
    return if not blessed $self;
    Graphics::render_figure($self, 'circle');
}

############################## Graphics utils using Tk #########################
package Graphics;
use Tk;
use List::Util qw(min max);

use constant BOX_SIZE => 50;
use constant PADDING_SIZE => 50;

# Checking the presence of Tk module.
if ( not eval { require Tk; } ) {
    die "Error: 'Tk' module was not found. " .
            "This program requiere 'Tk' module to run.\n"
}

sub radius {
    return sqrt(($_[0]-$_[2])*($_[0]-$_[2]) + ($_[1]-$_[3])*($_[1]-$_[3]));
};

my $text_vertex = sub {
    my ($cX, $cY, $pX, $pY) = @_;

    my $rad = radius($cX, $cY, $pX, $pY);

    if ($rad > 0) {
        my $tX = ($rad + PADDING_SIZE/2) * ($pX - $cX) / $rad + $cX;
        my $tY = ($rad + PADDING_SIZE/2) * ($pY - $cY) / $rad + $cY;

        return ($tX, $tY);
    }
};

my $draw_all = sub {
    my ($canvas, $canvasW, $canvasH, $figure, $type) = @_;

    my @real = $figure->points();
    my @pts = $figure->points();

    if ($type eq 'circle') {
        my $rad = radius($pts[0], $pts[1], $pts[2], $pts[3]);
        @pts = ($pts[0]-$rad, $pts[1]-$rad, $pts[0]+$rad, $pts[1]+$rad, $pts[2], $pts[3]);
    }

    # Extracting the bounding rectangle of figure.
    my ($minX, $minY, $maxX, $maxY) = ($pts[0], $pts[1]) x 2;
    for (my $i=2; $i<scalar @pts; $i+=2) {
        $minX = min $minX, $pts[$i];
        $minY = min $minY, $pts[$i+1];
        $maxX = max $maxX, $pts[$i];
        $maxY = max $maxY, $pts[$i+1];
    }

    # Scaling the figure.
    my ($w, $h) = (($maxX - $minX), ($maxY - $minY));
    my $viewSize = BOX_SIZE + PADDING_SIZE;
    my ($viewW, $viewH) = (($canvasW - $viewSize*2), ($canvasH - $viewSize*2));
    my $scale = min $viewW/$w, $viewH/$h;
    for my $p(@pts) { $p *= $scale; }

    # Centering the figure.
    my ($cX, $cY) = ($canvasW/2, $canvasH/2);
    my $offsetX = $cX - ($w*$scale)/2 - ($minX*$scale);
    my $offsetY = $cY - ($h*$scale)/2 - ($minY*$scale);
    for (my $i=0; $i<scalar @pts; $i+=2) {
        $pts[$i] += $offsetX;
        $pts[$i+1] += $offsetY;
    }

    # Normally the origin of the canvas coordinate system is at the upper-left
    # corner of the window. Here its transformed into the lower-left classic system.
    $offsetY = $canvasH - $offsetY;
    for (my $i=0; $i<scalar @pts; $i+=2) {
        $pts[$i+1] = $canvasH - $pts[$i+1];
    }

    # Drawing the figure.
    if ($type eq 'circle') {
        $canvas->createOval(@pts[0..3], -fill => $figure->color());
        $canvas->createOval($cX-2, $cY-2, $cX+2, $cY+2, -fill => 'black');
        $canvas->createText($cX, $cY, -text => "($real[0], $real[1])", -anchor => "ne");

        my ($tX, $tY) = $text_vertex->($cX, $cY, $pts[4], $pts[5]);
        if (defined $tX and defined $tY) {
            $canvas->createOval($pts[4]-2, $pts[5]-2, $pts[4]+2, $pts[5]+2, -fill => 'black');
            $canvas->createText($tX, $tY, -text => "($real[2], $real[3])", -anchor => "center");

        }
    }
    elsif ($type eq 'polygon') {
        my $function_name = (scalar @real > 4) ? 'createPolygon' : 'createLine';
        $canvas->$function_name(@pts, -fill => $figure->color());

        for (my $i=0; $i<scalar @pts; $i+=2) {
            my ($tX, $tY) = $text_vertex->($cX, $cY, $pts[$i], $pts[$i+1]);
            if (defined $tX and defined $tY) {
                $canvas->createOval($pts[$i]-1, $pts[$i+1]-1, $pts[$i]+1, $pts[$i+1]+1, -fill => 'black');
                $canvas->createText($tX , $tY, -text => "($real[$i], $real[$i+1])", -anchor => "center");
            }
        }
    }

    # Drawing the central axes.
    if ($offsetX > BOX_SIZE and $offsetX < $canvasW - BOX_SIZE) {
        $canvas->createLine($offsetX, BOX_SIZE, $offsetX, $canvasH - BOX_SIZE,
                -arrow => "first", -arrowshape => [10, 12, 3], -dash => '.');
        $canvas->createText($offsetX, BOX_SIZE * 0.8, -text => "Y", -anchor => "center");
    }
    else {
        $canvas->createText(BOX_SIZE, BOX_SIZE * 0.8, -text => "Y", -anchor => "w");
    }

    if ($offsetY > BOX_SIZE and $offsetY < $canvasH - BOX_SIZE) {
        $canvas->createLine(BOX_SIZE, $offsetY, $canvasW - BOX_SIZE, $offsetY,
                -arrow => "last", -arrowshape => [10, 12, 3], -dash => '.');
        $canvas->createText($canvasW - BOX_SIZE * 0.8, $offsetY, -text => "X", -anchor => "center");
    }
    else {
        $canvas->createText($canvasW - BOX_SIZE * 0.8, $canvasH - BOX_SIZE, -text => "X", -anchor => "s");
    }

    # Drawing the viewport.
    $canvas->createLine(BOX_SIZE, BOX_SIZE, $canvasW - BOX_SIZE, BOX_SIZE);
    $canvas->createLine($canvasW - BOX_SIZE, BOX_SIZE, $canvasW - BOX_SIZE, $canvasH - BOX_SIZE);
    $canvas->createLine(BOX_SIZE, $canvasH - BOX_SIZE, $canvasW - BOX_SIZE, $canvasH - BOX_SIZE);
    $canvas->createLine(BOX_SIZE, BOX_SIZE, BOX_SIZE, $canvasH - BOX_SIZE);

    # Drawing the figure info.
    my $info;
    if ($type eq 'polygon') {
        $info = sprintf("[ area = %.2f ]", $figure->area());
    }
    elsif ($type eq 'circle') {
        $info = sprintf("[ radius = %.2f ] [ area = %.2f ]", radius(@real), $figure->area());
    }

    $canvas->createText($cX , $canvasH - BOX_SIZE * 0.6, -text => $info, -anchor => "center");
};

sub render_figure {
    my ($figure, $type) = @_;
    return if not blessed $figure;

    # Creating the main window.
    my $window = MainWindow->new(-title => 'Figure renderer');
    $window->geometry("600x400+200+100");
    my $minsize = (BOX_SIZE + PADDING_SIZE) * 2;
    $window->minsize($minsize, $minsize);

    # Creating canvas for drawing.
    my $canvas = $window->Canvas(-bg => 'white');
    $canvas->pack(-expand => 1, -fill => 'both');

    # Callback when the canvas is resized.
    $canvas->CanvasBind('<Configure>' => sub {
        my $event = shift;
        $canvas->delete('all');
        $draw_all->($canvas, $event->width, $event->height, $figure, $type);
    });

    MainLoop;
}

############################## DB utils using DBI ##############################
package DB;
use DBI;

# Checking the presence of DBI module.
if ( not eval { require DBI; } ) {
    die "Error: 'DBI' module was not found. " .
            "This program requiere 'DBI' module to run.\n"
}

# Data connection. Modify this information to use another DB.
my $dbname   = 'perldb';
my $hostname = 'localhost';
my $port     = '3306';
my $username = 'root';
my $password = 'mysql';


# Unable to connect to DB.
my $dsn = "DBI:mysql:database=$dbname;host=$hostname;port=$port";
my $dbh = DBI->connect($dsn, $username, $password, {'PrintError' => 0});
if (not $dbh) {
    die "Error: Unable to connect to DB: " . $DBI::errstr . "\n";
}

my $cmd = "
CREATE TABLE IF NOT EXISTS figures (
    id     SERIAL,
    type   VARCHAR(10),
    points TEXT, 
    color  VARCHAR(10)
);";

if (not $dbh->do($cmd)) {
    die "Error: Unable to execute command: " . $DBI::errstr . "\n";
}

my $exists_figure = sub {
    my ($type, $points, $color) = @_;
    my $sql = "SELECT id FROM figures
            WHERE type='$type' AND points='$points' AND color='$color';";

    my $sth = $dbh->prepare($sql);
    $sth->execute() or die $sth->errstr . "\n";

    if (my @row = $sth->fetchrow_array()) {
        return $row[0];
    }
};

sub save_figure {
    my ($figure) = @_;
    return if not blessed $figure;

    my $type = blessed $figure;

    my @points = $figure->points();
    if ($type eq 'Rectangle' or $type eq 'Square') {
        @points = ($points[0], $points[1], $points[4], $points[5]);
    }
    my $p_str = join ',', @points;

    my $color = $figure->color();

    my $id = $exists_figure->($type, $p_str, $color);
    if ($id) {
        die "Warning: This \"$type\" already exists in the DB with id \"$id\". " .
                "Print \"render $id\" if you want to show it.\n";
    }

    my $rows_inserted = $dbh->do(
            "INSERT INTO figures(type, points, color) VALUES (?, ?, ?);",
            undef, $type, $p_str, $color);

    if (not $rows_inserted) {
        die "Error: Unable to insert to DB: " . $DBI::errstr . "\n";
    }
}

sub drop_figure {
    my $id = $_[0];
    if (not defined $id) { return; }

    my $sql = "DELETE FROM figures";
    if ($id >= 0) {
        $sql .= " WHERE id = '$id'";
    }
    $sql .= ";";

    return 0 if $id < -1;

    my $rows_deleted = $dbh->do($sql) or die $dbh->errstr;

    return ($rows_deleted eq '0E0') ? 0 : $rows_deleted;
}

sub get_figure {
    my $id = $_[0];
    if (not $id) { return; }

    my $sql = "SELECT type, points, color FROM figures WHERE id='$id';";

    my $sth = $dbh->prepare($sql);
    $sth->execute() or die $sth->errstr . "\n";

    if (my @row = $sth->fetchrow_array()) {
        my @points = split ',', $row[1];
        return $row[0]->new(@points, $row[2]);
    }
}

sub print_figures {
    my $sql = "SELECT id, type, points, color FROM figures ORDER BY id;";
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die $sth->errstr . "\n";

    my $last_id;
    while (my @row = $sth->fetchrow_array()) {
        print sprintf("id %2d: $row[1] ", $row[0]);

        my @points = split ',', $row[2];
        for (my $i=0; $i<scalar @points; $i+=2) {
            print "$points[$i],$points[$i+1] ";
        }

        print "$row[3]\n";

        $last_id = $row[1];
    }

    if (not $last_id) {
        print "Warning: No figures were found in the DB.\n";
    }
}

################################################################################
package main;

my $help = "Figure Render 2.0.0
Usage: <command> [arguments [...]]

Available commands:

create  Render a new figure, and then it's saved to DB.

        Sintax: create <figure type> <points> [color]

        Figure types:
            figure    X1,Y1 ... Xn,Yn   [color]
            rectangle X1,Y1 X2,Y2       [color]
            square    X1,Y1 X2,Y2       [color]
            triangle  X1,Y1 X2,Y2 X3,Y3 [color]
            circle    X1,Y1 X2,Y2       [color]

        Available colors (optional):
            snow  white     black   gray   navy   
            blue  turquoise cyan    green  yellow 
            brown salmon    orange  coral  red    
            pink  maroon    magenta violet purple

            If no color used, one will be selected randomly.

        Examples:
            create figure 0,10 3,3 10,0 3,-3 0,-10 -3,-3 -10,0 -3,3 cyan
            create rectangle -0.10,-0.07 -0.02,-0.01
            create triangle -2,7 5,1 -3,-4 turquoise
            create circle -100.5,-100.5 10, 8

list    Print all figures existing in the DB.

render  Render a figure existing in the DB.

        Sintax: render <figureID>

drop    Remove a figure from the DB.

        Sintax: drop <figureID>

        If -1 is used as ID, all figures will be removed.

help    Print this message.

exit    Exit the program.
";

sub trim {
    return if not $_[0];
    $_[0] =~ s/^\s+|\s+$//g;
};

my $create_cmd = sub {
    my %figures = (
        figure   => "Figure",  rectangle => "Rectangle",
        square   => "Square",  circle    => "Circle",
        triangle => "Triangle"
    );
    my %colors = (
        snow   => "", white   => "", black     => "", gray   => "",
        navy   => "", blue    => "", turquoise => "", cyan   => "",
        green  => "", yellow  => "", brown     => "", salmon => "",
        orange => "", coral   => "", red       => "", pink   => "",
        maroon => "", magenta => "", violet    => "", purple => ""
    );

    if (not defined $_[0]) {
        print STDERR "Error: Command \"create\" requires arguments. " .
                "Type \"help\" for more information.\n";
        return;
    }

    my @args = split /\s+/, $_[0], 2;
    my $type = lc $args[0];
 
    if (not exists $figures{$type}) {
        print STDERR "Error: Invalid figure type \"$args[0]\". " .
                "Type \"help\" for more information.\n";
        return;
    }
    if (not $args[1]) {
        print STDERR "Error: Figure type \"$args[0]\" requires arguments. " .
                "Type \"help\" for more information.\n";
        return;
    }

    my (@points, $color);
    my $num_rgx = '[-+]?([0-9]+\.[0-9]+|[1-9][0-9]*|[0-9])';
    my $coord_rgx = "($num_rgx)\\s*,\\s*($num_rgx)";

    if (not $args[1] =~ /^(($coord_rgx)\s+($coord_rgx)*)+([a-zA-Z]+)?$/) {
        print STDERR "Error: Invalid arguments syntax for type \"$args[0]\". " .
                "Type \"help\" for more information.\n";
        return;
    }

    while ($args[1] =~ /$coord_rgx/g) {
        push @points, $1, $3;
    }

    $args[1] =~ s/$coord_rgx\s*//g;
    $color = $args[1];

    if ($color) {
        if (not exists $colors{lc $color}) {
            print STDERR "Error: Unknown color type \"$color\". " .
                    "Type \"help\" for more information.\n";
            return;
        }
        else {
            $color = lc $color;
        }
    }
    else { # Selecting random color.
        my $index = int(rand(scalar keys %colors));
        my @sorted = sort keys %colors;

        # Avoiding white and black.
        while ($sorted[$index] eq 'white' or $sorted[$index] eq 'black') {
            $index = int(rand(scalar keys %colors));
        }

        $color = $sorted[$index];
    }

    eval {
        my $figure = $figures{$type}->new(@points, $color);

        DB::save_figure($figure);

        $figure->render();
    };

    if ($@) {
        print STDERR $@;
    }
};

my $validate_one_numeric_arg = sub {
    trim($_[0]);

    if (not defined $_[0]) {
        print STDERR "Error: Command \"$_[1]\" requires a figure ID argument. " .
                "Type \"help\" for more information.\n";
        return;
    }

    if (not $_[0] =~ /^[-+]?\d+$/) {
        print STDERR "Error: The figure ID argument is just a numeric value.\n";
        return;
    }

    return $_[0];
};

my $render_cmd = sub {
    my $id = $_[0];

    if (defined $validate_one_numeric_arg->($id, 'render')) {
        my $figure = DB::get_figure($id);

        if ($figure) {
            $figure->render();
        }
        else {
            print STDERR "Error: There is no figure in DB with ID \"$id\".\n";
        }
    }
};

my $drop_cmd = sub {
    my $id = $_[0];

    if (defined $validate_one_numeric_arg->($id, 'drop')) {
        if (not DB::drop_figure($id)) {
            print STDERR "Warning: There is no figure in DB with ID \"$id\".\n";
        }
    }
};

my %commands = (
    create => sub { $create_cmd->(@_);   },
    list   => sub { DB::print_figures(); },
    render => sub { $render_cmd->(@_);   },
    drop   => sub { $drop_cmd->(@_);     },
    help   => sub { print "$help\n";     },
    'exit' => sub { exit 0;              },
);

print "Figure Render 2.0.0
Usage: <command> [arguments [...]]
Type \"help\" for more information.\n";

for (;;) {
    print ">> ";
    trim(my $command = <STDIN>);

    if (not defined $command) {
        print "\n";
        exit 0;
    }

    my @args = split /\s+/, $command, 2;
    if (not scalar @args) {
        next;
    }

    if (not exists $commands{lc $args[0]}) {
        print STDERR "Error: Invalid command syntax \"$args[0]\".\n"
    }
    else {
        $commands{lc $args[0]}->(defined $args[1] ? $args[1] : undef);
    }
}
