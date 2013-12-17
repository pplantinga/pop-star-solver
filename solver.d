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
	immutable BOARD_WIDTH = 10;

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

	// Find_region function finds a chunk of blocks
	void find_region( Board board, ref int[] region, int x, int y )
	{
		int check_x, check_y;
		char color = board[x][y];
		region ~= [100 * x + y];
		for ( int i = 0; i < 4; i++ )
		{
			check_x = i % 2 ? x : x + i - 1;
			check_y = i % 2 ? y + i - 2 : y;
			if ( check_x >= 0 && check_x < BOARD_HEIGHT
					&& check_y >= 0 && check_y < BOARD_WIDTH
					&& board[check_x][check_y] == color
					&& !contains( region, 100 * check_x + check_y ) )
				find_region( board, region, check_x, check_y );
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

	// Solve function finds best moves
	int solve( Board board, int points, int depth )
	{
		if ( depth == 0 )
			return points;

		Board testboard;
		int[] region;
		int val = 0;
		int bestVal = 0;
		int bestMove = 0;
		bool end = true;
		int[] already;

		// Try every move
		for ( int i = 0; i < BOARD_HEIGHT; i++ )
		{
			for ( int j = 0; j < BOARD_WIDTH; j++ )
			{
				if ( board[i][j] == ' ' || contains( already, 100 * i + j ) )
					continue;

				region = null;
				find_region( board, region, i, j );
				
				// If it's a legal move
				if ( region.length > 1 )
				{
					already ~= region;

					testboard = board.dup;
					remove( board, region );
					gravity( testboard );

					points += score( region.length );
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
		else if ( depth == 6 )
			return bestMove;
		else
			return bestVal;
	}

	// Test functions
	/*int[] region;
	find_region( board, region, 1, 0 );
	remove( board, region );
	gravity( board );
	print_board( board );
	writeln( region );
	writeln( score( region.length ) );
	writeln( endscore( region.length ) );
	writeln( count_remaining( board ) );
	*/
	// Solve board
	int move = solve( board, 0, 6 );
	writefln( "x is %s and y is %s", move / 100, move % 100 );

	// print board with pieces removed
	int[] region;
	find_region( board, region, move / 100, move % 100 );
	remove( board, region );
	gravity( board );
	print_board( board );
	writeln( score( region.length ) );
}
