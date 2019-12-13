// $Id: x07c.c 11289 2010-10-29 20:44:17Z airwin $
//
//      Font demo.
//

#ifdef MSDOS
#pragma optimize("",off)
#endif

#include "plcdemos.h"

static int base[20] =
{ 0,     100,    0,  100,  200,  500,  600,  700,  800, 900,
  2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900 };

//--------------------------------------------------------------------------
// main
//
// Displays the entire "plsym" symbol (font) set.
//--------------------------------------------------------------------------

int
main( int argc, const char *argv[] )
{
    char  text[10];
    int   i, j, k, l;
    PLFLT x, y;

// Parse and process command line arguments

    (void) plparseopts( &argc, argv, PL_PARSE_FULL );

// Initialize plplot

    plinit();

    plfontld( 0 );
    for ( l = 0; l < 20; l++ )
    {
        if ( l == 2 )
            plfontld( 1 );
        pladv( 0 );

        // Set up viewport and window

        plcol0( 2 );
        plvpor( 0.15, 0.95, 0.1, 0.9 );
        plwind( 0.0, 1.0, 0.0, 1.0 );

        // Draw the grid using plbox

        plbox( "bcg", 0.1, 0, "bcg", 0.1, 0 );

        // Write the digits below the frame

        plcol0( 15 );
        for ( i = 0; i <= 9; i++ )
        {
            sprintf( text, "%d", i );
            plmtex( "b", 1.5, ( 0.1 * i + 0.05 ), 0.5, text );
        }

        k = 0;
        for ( i = 0; i <= 9; i++ )
        {
            // Write the digits to the left of the frame

            sprintf( text, "%d", base[l] + 10 * i );
            plmtex( "lv", 1.0, ( 0.95 - 0.1 * i ), 1.0, text );
            for ( j = 0; j <= 9; j++ )
            {
                x = 0.1 * j + 0.05;
                y = 0.95 - 0.1 * i;

                // Display the symbols

                plsym( 1, &x, &y, base[l] + k );
                k = k + 1;
            }
        }

        if ( l < 2 )
            plmtex( "t", 1.5, 0.5, 0.5, "PLplot Example 7 - PLSYM symbols (compact)" );
        else
            plmtex( "t", 1.5, 0.5, 0.5, "PLplot Example 7 - PLSYM symbols (extended)" );
    }
    plend();
    exit( 0 );
}
