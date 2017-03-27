import 'dart:math';
import 'dart:collection';

/// What's amazing to me is that Dart's standard library doesn't have this.
class PriorityQueue<T> extends Object with IterableMixin<T> {
	final Map<int,List<T>> _map = {};
	
	List<T> get _items {
		List<T> result = [];
		
		List<int> keys = _map.keys.toList();
		keys.sort();
		for (int key in keys) {
			result.addAll(_map[key]);
		}
		
		return result;
	}
	
	void add(int priority, T value) {
		_map.putIfAbsent(priority, []);
		_map[priority].add(value);
	}
	
	void clear() {
		_map.clear();
	}
	
	@override
	Iterator<T> get iterator => _items.iterator;
}

String repeatString(String s, int n) {
	StringBuffer buf = new StringBuffer();
	for (int i = 0; i < n; i++) {
		buf.write(s);
	}
	return buf.toString();
}

/// Returns a key code for the nth item in a list.
String getKeyForInt(int i) {
	if (i <= 9) {return i.toString();}
	if (i == 10) {return "0";}
	if (i-10 <= 26) {return new String.fromCharCode(96 + i-10);} // 'a' + i-10
	if (i-10-26 <= 26) {return new String.fromCharCode(64 + i-10-26);} // 'A' + i-10
	return null;
}

/// Inserts newlines where appropriate to make the string fit in n characters wide.
String fitToWidth(String s, int n) {
	List<String> lines = s.split("\n");
	StringBuffer sb = new StringBuffer();
	for (String line in lines) {
		List<String> words = line.split(" ");
		int x = 0;
		for (String word in words) {
			if (x + word.length > n) {
				sb.write("\n");
				x = 0;
			} else if (x > 0) {
				sb.write(" ");
			}
			sb.write(word);
			x += word.length + 1;
		}
		sb.write("\n");
	}
	return sb.toString().trimRight();
}

String capitalize(String s) {
	StringBuffer buf = new StringBuffer();
	int space = " ".codeUnitAt(0);
	int lastChar = space;
	for (int c in s.codeUnits) {
		if (lastChar == space) {
			buf.write(new String.fromCharCode(c).toUpperCase());
		} else {
			buf.writeCharCode(c);
		}
		lastChar = c;
	}
	return buf.toString();
}

Random rng = new Random();