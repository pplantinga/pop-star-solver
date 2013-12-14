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
	}

	// See initial position
	print_board( board );

	// Solve function
	int solve( Board board, int points )
	{
		return 0;
	}

	// Solve board
	int points = solve( board, 0 );
	writeln( points );
}
