import std.stdio;

void main() {
	auto f = File("test.txt", "r");
	foreach (row; f.byLine()) {
		writeln(row);
	}
}
