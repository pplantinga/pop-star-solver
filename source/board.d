import std.range : iota;
import std.datetime;
import std.stdio;

class Board
{
	static immutable MIN_BLOCKS = 2;
	static immutable MIN_BLOCKS_SCORE = 20;
	static immutable SCORE_INCREASE_START = 25;
	static immutable SCORE_INCREASE_INCREASE = 10;
	static immutable END_CLEAR_SCORE = 2000;
	static immutable END_DECREASE_START = 20;
	static immutable END_DECREASE_INCREASE = 40;
	static immutable BOARD_HEIGHT = 10;
	static immutable BOARD_WIDTH = 12;
	char[BOARD_WIDTH][BOARD_HEIGHT] my_board;
	int remaining = BOARD_WIDTH * BOARD_HEIGHT;

	this(string file)
	{
		auto f = new File(file, "r");
		int i = 0;
		foreach (row; f.byLine())
		{
			my_board[i] = row;
			i += 1;
		}
	}

	this(Board board)
	{
		foreach (i, row; board.my_board)
		{
			my_board[i] = row.dup;
		}
		remaining = board.remaining;
	}

	// Pretty print
	auto print_board()
	{
		foreach (row; my_board)
		{
			writeln(row);
		}
		writeln(' ');
	}

	bool is_on_board(int pos, bool dimension)
	{
		if (dimension)
		{
			return pos >= 0 && pos < BOARD_WIDTH;
		}
		else
		{
			return pos >= 0 && pos < BOARD_HEIGHT;
		}
	}

	// Find legal squares around a spot
	int[] find_surrounding(int here)
	{
		int[] surrounding = [here - 1, here - 100, here + 1, here + 100];
		int[] legal;
		
		// Iterate over surrounding squares
		foreach (square; surrounding)
		{

			// Check if it is on the board
			if (is_on_board(square / 100, false) && is_on_board(square % 100, true))
			{
				legal ~= square;
			}
		}

		return legal;
	}

	bool find(int[] haystack, int needle)
	{
		foreach (straw; haystack)
		{
			if (straw == needle)
			{
				return true;
			}
		}
		return false;
	}

	// Find_region method finds a chunk of blocks
	void find_region(ref int[] region, int here)
	{
		int x = here / 100;
		int y = here % 100;
		if (my_board[x][y] == ' ')
		{
			return;
		}

		// Append this square to the region
		region ~= [here];

		// Iterate over surrounding squares
		int[] surrounding = find_surrounding(here);
		foreach (square; surrounding)
		{

			// If we're the same and not found already
			if ((my_board[square / 100][square % 100] == my_board[x][y]
			 && !find(region, square)
			))
			{
				find_region(region, square);
			}
		}
	}

	// removes a region from the board
	auto remove(int[] region, ref bool[BOARD_WIDTH][BOARD_HEIGHT] already)
	{

		foreach (block; region)
		{
			my_board[block / 100][block % 100] = ' ';
			already[block / 100][block % 100] = true;
		}

		remaining -= region.length;
	}

	// Gravity method pulls blocks down
	auto gravity()
	{

		// j and i are reversed to indicate iterating over columns
		foreach (j; 0 .. BOARD_WIDTH)
		{
			foreach (i; 1 .. BOARD_HEIGHT)
			{
				if (my_board[i][j] == ' ')
				{
					foreach (k; iota(i, 0, -1))
					{
						my_board[k][j] = my_board[k - 1][j];
					}
					my_board[0][j] = ' ';
				}
			}
		}
	}

	// Remove empty columns
	auto collapse()
	{
		int count = 0;
		char[] slice;
		foreach (i; 0 .. BOARD_WIDTH)
		{
			if (my_board[$ - 1][i] == ' ')
			{
				count += 1;
			}

			else if (count != 0)
			{

				// Mind the gap
				foreach (j; 0 .. BOARD_HEIGHT)
				{
					foreach (k; i - count .. BOARD_WIDTH)
					{
						if (k < BOARD_WIDTH - count)
						{
							my_board[j][k] = my_board[j][k + count];
						}
						else
						{
							my_board[j][k] = ' ';
						}
					}
				}

				i -= count;
				count = 0;
			}
		}
	}

	// Score method scores one blast
	auto score(T)(T count)
	{

		T n = count - MIN_BLOCKS;
		return (MIN_BLOCKS_SCORE + SCORE_INCREASE_START * n
		 + SCORE_INCREASE_INCREASE * n * (n - 1) / 2
		);
	}

	// Score method that scores blocks left over
	int endscore(int count)
	{

		int score = (END_CLEAR_SCORE - END_DECREASE_START * count
		 - END_DECREASE_INCREASE * count * (count - 1) / 2
		);
		if (score < 0)
		{
			return 0;
		}
		else
		{
			return score;
		}
	}

	// Count blastable squares
	int blastable()
	{

		int count = 0;
		int[] surrounding;
		
		// Iterate over board columns, then rows
		foreach (j; 0 .. BOARD_WIDTH)
		{
			foreach (i; iota(BOARD_HEIGHT - 1, 0, -1))
			{
				if (my_board[i][j] == ' ')
				{
					break;
				}

				surrounding = find_surrounding(i * 100 + j);

				// Iterate over surrounding squares
				foreach (square; surrounding)
				{

					// If we have at least one neighbor that's the same
					if (my_board[square / 100][square % 100] == my_board[i][j])
					{

						count += 1;
						break;
					}
				}
			}
		}

		return count;
	}

	// Solve method finds best moves
	int solve(int points, int depth, int maxdepth, int limit, StopWatch sw)
	{

		if (depth == 0 || sw.peek().seconds > limit)
		{
			return points;
		}

		Board testboard;
		int[] region;
		int val = 0;
		int bestVal = -100;
		int bestMove = -1;
		int square = 0;
		bool end = true;
		bool[BOARD_WIDTH][BOARD_HEIGHT] already;
		
		// Try every move
		foreach (i; 0 .. BOARD_HEIGHT)
		{
			foreach (j; 0 .. BOARD_WIDTH)
			{
				square = 100 * i + j;

				if (my_board[i][j] == ' ' || already[i][j])
				{
					continue;
				}

				region = null;
				find_region(region, square);
				
				// If it's a legal move
				if (region.length > 1)
				{

					testboard = new Board(this);
					testboard.remove(region, already);
					testboard.gravity();
					testboard.collapse();
					
					// Using actual scoring leads to short-sighted strategies
					 // points += score(region.length)
					points += 10 * testboard.blastable() + testboard.score(region.length);

					end = false;

					// Try subsequent moves
					val = testboard.solve(points, depth - 1, maxdepth, limit, sw);
					if (val > bestVal)
					{

						bestVal = val;
						bestMove = region[0];
					}
				}
			}
		}

		if (depth == maxdepth)
		{
			return bestMove;
		}
		else if (end)
		{
			return points + endscore(remaining);
		}
		else
		{
			return bestVal;
		}
	}
}

