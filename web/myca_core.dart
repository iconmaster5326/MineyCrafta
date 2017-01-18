String repeatString(String s, int n) {
	StringBuffer buf = new StringBuffer();
	for (int i = 0; i < n; i++) {
		buf.write(s);
	}
	return buf.toString();
}
