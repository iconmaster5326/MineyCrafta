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