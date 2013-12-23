import board;
import std.stdio;
import std.datetime;

void main()
{
	immutable TIMELIMIT = 5;
	Board board = new Board("test.txt");

	// See initial position
	board.print_board();

	// Solve board
	StopWatch sw;
	int move = board.solve( 0, 1, 1, sw, TIMELIMIT );
	int temp = move;
	int[] region;
	int points;
	while ( move != -1 )
	{
		//writefln( "x is %s and y is %s", move / 100, move % 100 );
	
		// print board with pieces removed
		region = null;
		board.find_region( region, move );
		points += board.score( region.length );
		board.remove( region );
		board.print_board();
		board.gravity();
		board.collapse();

		sw.reset();
		sw.start();
		for ( int depth = 0; sw.peek().seconds < TIMELIMIT; depth++ )
		{
			move = temp;
			temp = board.solve( 0, depth, depth, sw, TIMELIMIT );
			if ( sw.peek().seconds > TIMELIMIT )
				writeln( depth );
		}
	}

	points += board.endscore( board.count_remaining() );
	writeln( "You get ", points, " points!" );
}
