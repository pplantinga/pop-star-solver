import std.stdio;

void main()
{
	immutable MIN_BLOCKS = 2;
	immutable MIN_BLOCKS_SCORE = 20;
	immutable SCORE_INCREASE_START = 25;
	immutable SCORE_INCREASE_INCREASE = 10;
	immutable END_CLEAR_SCORE = 2000;
	immutable END_DECREASE_START = 20;
	immutable END_DECREASE_INCREASE = 40;
	immutable BOARD_HEIGHT = 10;
	immutable BOARD_WIDTH = 12;
	immutable DEPTH = 3;

	alias char[BOARD_WIDTH][BOARD_HEIGHT] Board;
	Board board;
	auto f = File("test.txt", "r");
	int i = 0;
	foreach ( row; f.byLine() )
	{
		board[i++] = row;
	}

	// Pretty print
	void print_board( Board board )
	{
		foreach ( row; board )
			writeln( row );
		writeln( ' ' );
	}

	// See initial position
	print_board( board );

	// See if array contains a value
	bool contains( int[] array, int val )
	{
		foreach ( num; array )
			if ( val == num )
				return true;
		return false;
	}

	bool is_on_board( int pos, bool dimension )
	{
		if ( dimension )
			return pos >= 0 && pos < BOARD_WIDTH;
		else
			return pos >= 0 && pos < BOARD_HEIGHT;
	}
	
	// Find legal squares around a spot
	int[] find_surrounding( int here )
	{
		int[] surrounding = [ here - 1, here - 100, here + 1, here + 100 ];
		int[] legal;

		// Iterate over surrounding squares
		foreach ( square; surrounding )
		{
			// Check if it is on the board
			if ( is_on_board( square / 100, false )
					&& is_on_board( square % 100, true ) )
				legal ~= square;
		}
		return legal;
	}

	// Find_region function finds a chunk of blocks
	void find_region( Board board, ref int[] region, int here )
	{
		if ( board[here / 100][here % 100] == ' ' )
			return;

		// Append this square to the region
		region ~= [here];

		// Iterate over surrounding squares
		int[] surrounding = find_surrounding( here );
		foreach ( square; surrounding )
		{
			// If we're the same and not found already
			if ( board[square / 100][square % 100] == board[here / 100][here % 100]
					&& !contains( region, square ) )
				find_region( board, region, square );
		}
	}

	// removes a region from the board
	void remove( ref Board board, int[] region )
	{
		foreach ( block; region )
			board[block / 100][block % 100] = ' ';
	}

	// Gravity function pulls blocks down
	void gravity( ref Board board )
	{
		// j and i are reversed to indicate iterating over columns
		for ( int j = 0; j < BOARD_WIDTH; j++ )
		{
			// and then rows, ignoring the top row
			for ( int i = 1; i < BOARD_HEIGHT; i++ )
			{
				if ( board[i][j] == ' ' )
				{
					for ( int k = i; k > 0; k-- )
						board[k][j] = board[k-1][j];
					board[0][j] = ' ';
				}
			}
		}
	}

	// Remove empty columns
	void collapse( ref Board board )
	{
		int count = 0;
		char[] slice;
		for ( int i = 0; i < BOARD_WIDTH; i++ )
		{
			if ( board[$-1][i] == ' ' )
			{
				count++;
			}
			else if ( count != 0 )
			{
				// Mind the gap
				for ( int j = 0; j < BOARD_HEIGHT; j++ )
				{
					for ( int k = i - count; k < BOARD_WIDTH; k++ )
					{
						if ( k < BOARD_WIDTH - count )
							board[j][k] = board[j][k + count];
						else
							board[j][k] = ' ';
					}
				}
				i -= count;
				count = 0;
			}
		}
	}

	// Score function scores one blast
	int score( int count )
	{
		int n = count - MIN_BLOCKS;
		return MIN_BLOCKS_SCORE + SCORE_INCREASE_START * n
			+ SCORE_INCREASE_INCREASE * n * (n - 1) / 2;
	}			

	// Score function that scores blocks left over
	int endscore( int count )
	{
		int score = END_CLEAR_SCORE - END_DECREASE_START * count
			- END_DECREASE_INCREASE * count * ( count - 1 ) / 2;
		return score < 0 ? 0 : score;
	}

	// Count remaining squares at end
	int count_remaining( Board board )
	{
		int count = 0;
		foreach ( row; board )
			foreach ( square; row )
				if ( square != ' ' )
					count++;
		return count;
	}

	// Count blastable squares
	int blastable( Board board )
	{
		int count = 0;
		int[] surrounding;

		// Iterate over board
		for ( int i = 0; i < BOARD_HEIGHT; i++ )
		{
			for ( int j = 0; j < BOARD_WIDTH; j++ )
			{
				if ( board[i][j] == ' ' )
					continue;
				
				surrounding = find_surrounding( i * 100 + j );

				// Iterate over surrounding squares
				foreach ( square; surrounding )
				{
					// If we have at least one neighbor that's the same
					if ( board[square / 100][square % 100] == board[i][j] )
					{
						count++;
						break;
					}
				}
			}
		}
		return count;
	}

	// Solve function finds best moves
	int solve( Board board, int points, int depth )
	{
		if ( depth == 0 )
			return points;

		Board testboard;
		int[] region;
		int val = 0;
		int bestVal = -100;
		int bestMove = 0;
		int square = 0;
		bool end = true;
		int[] already;

		// Try every move
		for ( int i = 0; i < BOARD_HEIGHT; i++ )
		{
			for ( int j = 0; j < BOARD_WIDTH; j++ )
			{
				square = 100 * i + j;

				if ( board[i][j] == ' ' || contains( already, square ) )
					continue;

				region = null;
				find_region( board, region, square );
				
				// If it's a legal move
				if ( region.length > 1 )
				{
					already ~= region;

					testboard = board.dup;
					remove( testboard, region );
					gravity( testboard );
					collapse( testboard );

					// Using actual scoring leads to short-sighted strategies
					//points += score( region.length );
					points = blastable( testboard );
					
					end = false;

					// Try subsequent moves
					val = solve( testboard, points, depth - 1 );
					if ( val > bestVal )
					{
						bestVal = val;
						bestMove = region[0];
					}
				}
			}
		}

		if ( end )
			return points + endscore( count_remaining( board ) );
		else if ( depth == DEPTH )
			return bestMove;
		else
			return bestVal;
	}

	// Solve board
	int move = solve( board, -1, DEPTH );
	int[] region;
	while ( move != -1 )
	{
		//writefln( "x is %s and y is %s", move / 100, move % 100 );
	
		// print board with pieces removed
		region = null;
		find_region( board, region, move );
		remove( board, region );
		print_board( board );
		gravity( board );
		collapse( board );

		move = solve( board, -1, DEPTH );
	}
}
