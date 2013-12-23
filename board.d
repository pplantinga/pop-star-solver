import std.datetime;

class Board
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
	char[BOARD_WIDTH][BOARD_HEIGHT] my_board;

	this( string file )
	{
		auto f = File( file, 'r' );
		int i = 0;
		foreach ( row; f.byLine() )
		{
			my_board[i++] = row;
		}
	}

	// Pretty print
	public void print_board()
	{
		foreach ( row; my_board )
			writeln( row );
		writeln( ' ' );
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
	public void find_region( ref int[] region, int here )
	{
		if ( my_board[here / 100][here % 100] == ' ' )
			return;

		// Append this square to the region
		region ~= [here];

		// Iterate over surrounding squares
		int[] surrounding = find_surrounding( here );
		foreach ( square; surrounding )
		{
			// If we're the same and not found already
			if ( board[square / 100][square % 100] == board[here / 100][here % 100]
					&& !region.find(square) )
				find_region( region, square );
		}
	}

	// removes a region from the board
	public void remove( int[] region )
	{
		foreach ( block; region )
			my_board[block / 100][block % 100] = ' ';
	}

	// Gravity function pulls blocks down
	public void gravity()
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
	public void collapse()
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
							my_board[j][k] = my_board[j][k + count];
						else
							my_board[j][k] = ' ';
					}
				}
				i -= count;
				count = 0;
			}
		}
	}

	// Score function scores one blast
	pure int score( int count )
	{
		int n = count - MIN_BLOCKS;
		return MIN_BLOCKS_SCORE + SCORE_INCREASE_START * n
			+ SCORE_INCREASE_INCREASE * n * (n - 1) / 2;
	}			

	// Score function that scores blocks left over
	pure int endscore( int count )
	{
		int score = END_CLEAR_SCORE - END_DECREASE_START * count
			- END_DECREASE_INCREASE * count * ( count - 1 ) / 2;
		return score < 0 ? 0 : score;
	}

	// Count remaining squares at end
	int count_remaining()
	{
		int count = 0;
		foreach ( row; my_board )
			foreach ( square; row )
				if ( square != ' ' )
					count++;
		return count;
	}

	// Count blastable squares
	public int blastable()
	{
		int count = 0;
		int[] surrounding;

		// Iterate over board
		for ( int i = 0; i < BOARD_HEIGHT; i++ )
		{
			for ( int j = 0; j < BOARD_WIDTH; j++ )
			{
				if ( my_board[i][j] == ' ' )
					continue;
				
				surrounding = find_surrounding( i * 100 + j );

				// Iterate over surrounding squares
				foreach ( square; surrounding )
				{
					// If we have at least one neighbor that's the same
					if ( my_board[square / 100][square % 100] == my_board[i][j] )
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
	int solve( int points, int depth, int maxdepth, StopWatch sw )
	{
		if ( depth == 0 || sw.peek().seconds > TIMELIMIT )
			return points;

		Board testboard;
		int[] region;
		int val = 0;
		int bestVal = -100;
		int bestMove = -1;
		int square = 0;
		bool end = true;
		int[] already;

		// Try every move
		for ( int i = 0; i < BOARD_HEIGHT; i++ )
		{
			for ( int j = 0; j < BOARD_WIDTH; j++ )
			{
				square = 100 * i + j;

				if ( board.my_board[i][j] == ' ' || already.find( square ) )
					continue;

				region = null;
				board.find_region( region, square );
				
				// If it's a legal move
				if ( region.length > 1 )
				{
					already ~= region;

					testboard = board.dup;
					testboard.remove( region );
					testboard.gravity();
					testboard.collapse();

					// Using actual scoring leads to short-sighted strategies
					//points += score( region.length );
					points += 10 * testboard.blastable() + testboard.score( region.length );
					
					end = false;

					// Try subsequent moves
					val = testboard.solve( points, depth - 1, maxdepth, sw );
					if ( val > bestVal )
					{
						bestVal = val;
						bestMove = region[0];
					}
				}
			}
		}

		if ( depth == maxdepth )
			return bestMove;
		else if ( end )
			return points + endscore( count_remaining( board ) );
		else
			return bestVal;
	}
}
