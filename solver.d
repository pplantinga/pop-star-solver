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
	immutable BOARD_SIZE = 10;

	alias char[BOARD_SIZE][BOARD_SIZE] Board;
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

	// Remove function blasts a chunk of blocks
	int remove( ref Board board, int count, int x, int y )
	{
		int check_x, check_y;
		char color = board[x][y];
		board[x][y] = ' ';
		for ( int i = 0; i < 4; i++ )
		{
			check_x = i % 2 ? x : x + i - 1;
			check_y = i % 2 ? y + i - 2 : y;
			if ( check_x >= 0 && check_x < BOARD_SIZE
					&& check_y >= 0 && check_y < BOARD_SIZE
					&& board[check_x][check_y] == color )
				count = remove( board, count, check_x, check_y ) + 1;
		}
		return count;
	}

	// Gravity function pulls blocks down
	void gravity( ref Board board )
	{
		// j and i are reversed to indicate iterating over columns
		for ( int j = 0; j < BOARD_SIZE; j++ )
		{
			// and then rows, ignoring the top row
			for ( int i = 1; i < BOARD_SIZE; i++ )
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
	in { assert( count >= 2 ); }
	body
	{
		if ( count == MIN_BLOCKS )
			return MIN_BLOCKS_SCORE;
		else
			return score( count - 1 ) + SCORE_INCREASE_START
				+ SCORE_INCREASE_INCREASE * (count - MIN_BLOCKS - 1);
	}			

	// Score function that scores blocks left over
	int endscore( int count ) {
		if ( count == 0 )
			return END_CLEAR_SCORE;
		else
			return endscore( count - 1 ) <= 0 ? 0
				: endscore( count - 1 ) - END_DECREASE_START
				- END_DECREASE_INCREASE * ( count - 1 );
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
	int solve( Board board, int points )
	{
		Board testboard;
		int count = 0;
		int val = 0;
		int bestVal = 0;
		bool end = true;

		// Try every move
		for ( int i = 0; i < BOARD_SIZE; i++ )
		{
			for ( int j = 0; j < BOARD_SIZE; j++ )
			{
				if ( board[i][j] == ' ' )
					continue;
				testboard = board.dup;
				count = remove( testboard, 0, i, j );
				
				// If it's a legal move
				if ( count > 1 )
				{
					gravity( testboard );
					points += score( count );
					end = false;

					// Try subsequent moves
					val = solve( testboard, points );
					bestVal = bestVal > val ? bestVal : val;
				}
			}
		}

		if ( end )
			return endscore( count_remaining( board ) );
		else
			return bestVal;
	}

	// Test functions
	/*int count = remove( board, 1, 1, 0 );
	print_board( board );
	gravity( board );
	print_board( board );
	writeln( count );
	writeln( score( count ) );
	writeln( endscore( count ) );
	writeln( count_remaining( board ) );
	*/
	// Solve board
	int points = solve( board, 0 );
	writeln( points );
}
