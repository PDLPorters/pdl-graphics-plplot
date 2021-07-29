//      Polar plot demo.
//

#include "plcdemos.h"

//--------------------------------------------------------------------------
// main
//
// Generates polar plot, with 1-1 scaling.
//--------------------------------------------------------------------------

int
main( int argc, char *argv[] )
{
    int          i;
    PLFLT        dtr, theta, dx, dy, r, offset;
    char         text[4];
    static PLFLT x0[361], y0[361];
    static PLFLT x[361], y[361];

    dtr = M_PI / 180.0;
    for ( i = 0; i <= 360; i++ )
    {
        x0[i] = cos( dtr * i );
        y0[i] = sin( dtr * i );
    }

// Parse and process command line arguments

    (void) plparseopts( &argc, argv, PL_PARSE_FULL );

// Set orientation to portrait - note not all device drivers
// support this, in particular most interactive drivers do not
    plsori( 1 );

// Initialize plplot

    plinit();

// Set up viewport and window, but do not draw box

    plenv( -1.3, 1.3, -1.3, 1.3, 1, -2 );
    // Draw circles for polar grid
    for ( i = 1; i <= 10; i++ )
    {
        plarc( 0.0, 0.0, 0.1 * i, 0.1 * i, 0.0, 360.0, 0.0, 0 );
    }

    plcol0( 2 );
    for ( i = 0; i <= 11; i++ )
    {
        theta = 30.0 * i;
        dx    = cos( dtr * theta );
        dy    = sin( dtr * theta );

        // Draw radial spokes for polar grid

        pljoin( 0.0, 0.0, dx, dy );
        sprintf( text, "%d", ROUND( theta ) );

        // Write labels for angle

        if ( theta < 9.99 )
        {
            offset = 0.45;
        }
        else if ( theta < 99.9 )
        {
            offset = 0.30;
        }
        else
        {
            offset = 0.15;
        }

// Slightly off zero to avoid floating point logic flips at 90 and 270 deg.
        if ( dx >= -0.00001 )
            plptex( dx, dy, dx, dy, -offset, text );
        else
            plptex( dx, dy, -dx, -dy, 1. + offset, text );
    }

// Draw the graph

    for ( i = 0; i <= 360; i++ )
    {
        r    = sin( dtr * ( 5 * i ) );
        x[i] = x0[i] * r;
        y[i] = y0[i] * r;
    }
    plcol0( 3 );
    plline( 361, x, y );

    plcol0( 4 );
    plmtex( "t", 2.0, 0.5, 0.5, "#frPLplot Example 3 - r(#gh)=sin 5#gh" );

// Close the plot at end

    plend();
    exit( 0 );
}
