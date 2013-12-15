import std.stdio;

void main()
{
	immutable two_blocks = 20;
	immutable start_increase = 25;
	immutable increase_increase = 10;
	immutable clear_board = 2000;
	immutable start_decrease = 20;
	immutable decrease_increase = 40;
	immutable board_size = 10;

	alias char[board_size][board_size] Board;
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
			if ( check_x >= 0 && check_x < board_size
					&& check_y >= 0 && check_y < board_size
					&& board[check_x][check_y] == color )
				count = remove( board, count, check_x, check_y ) + 1;
		}
		return count;
	}

	// Gravity function pulls blocks down
	void gravity( ref Board board )
	{
		// j and i are reversed to indicate iterating over columns
		for ( int j = 0; j < board_size; j++ )
		{
			// and then rows, ignoring the top row
			for ( int i = 1; i < board_size; i++ )
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

	// Solve function finds best moves
	int solve( Board board, int points )
	{
		Board testboard;
		int count = 0;
		int val = 0;
		int bestVal = 0;
		bool end = true;

		// Try every move
		for ( int i = 0; i < board_size; i++ )
		{
			for ( int j = 0; j < board_size; j++ )
			{
				testboard = board.dup;
				count = remove( testboard, 0, i, j );
				// points += score( count );

				// If it's a legal move
				if ( count > 1 )
				{
					end = false;
					// Try subsequent moves
					val = solve( testboard, points );
					bestVal = bestVal > val ? bestVal : val;
				}
			}
		}
		//if ( end )
		//	return endscore( board );
		//else
			return bestVal;
	}

	// Test remove + gravity function
	int count = remove( board, 1, 1, 0 );
	print_board( board );
	gravity( board );
	print_board( board );
	writeln( count );
	
	// Solve board
	int points = solve( board, 0 );
	writeln( points );
}
