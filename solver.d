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

	// Remove function
	int remove( ref Board board, int count, int x, int y )
	{
		int check_x, check_y;
		char color = board[x][y];
		board[x][y] = ' ';
		for ( int i = 0; i < 4; i++ )
		{
			check_x = i % 2 ? x : x + i - 1;
			check_y = i % 2 ? y + i - 2 : y;
			if ( check_x >= 0 && check_x < 10
					&& check_y >= 0 && check_y < 10
					&& board[check_x][check_y] == color )
				count = remove( board, count, check_x, check_y ) + 1;
		}
		return count;
	}

	// Solve function
	int solve( Board board, int points )
	{
		return 0;
	}

	// Test remove function
	int count = remove( board, 1, 1, 0 );
	print_board( board );
	writeln( count );
	
	// Solve board
	int points = solve( board, 0 );
	writeln( points );
}
