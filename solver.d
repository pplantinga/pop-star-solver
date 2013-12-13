import std.stdio;

void main() {
	immutable two_blocks = 20;
	immutable start_increase = 25;
	immutable increase_increase = 10;
	immutable clear_board = 2000;
	immutable start_decrease = 20;
	immutable decrease_increase = 40;

	auto f = File("test.txt", "r");
	foreach (row; f.byLine()) {
		writeln(row);
	}
}
