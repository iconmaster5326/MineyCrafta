import 'dart:html';

import 'myca_core.dart';

typedef void ConsoleRefreshHandler(Console c);
typedef void ConsoleClickHandler(Console c, ConsoleLink link);

final String _nbsp = new String.fromCharCode(160);

enum ConsoleColor {
	BLACK,
	MAROON,
	GREEN,
	OLIVE,
	NAVY,
	PURPLE,
	TEAL,
	SILVER,
	GREY,
	RED,
	LIME,
	YELLOW,
	BLUE,
	FUCHSIA,
	AQUA,
	WHITE
}

class ConsoleLabel {
	int x;
	int y;
	String _text;
	
	ConsoleColor fore;
	ConsoleColor back;
	
	ConsoleLabel(this.x, this.y, this._text, [this.fore = ConsoleColor.WHITE, this.back = ConsoleColor.BLACK]) {
		_text = _text.replaceAll(" ", _nbsp);
	}
	
	get text => _text;
	set text(String value) {
		_text = value.replaceAll(" ", _nbsp);
	}
	
	List<ConsoleLabel> as2DLabel() {
		List<String> data = text.split("\n");
		List<ConsoleLabel> ret = new List<ConsoleLabel>();
		int i = 0;
		for (String line in data) {
			ret.add(new ConsoleLabel(x, y+i, line, fore, back));
			i++;
		}
		return ret;
	}
}

class ConsoleLink extends ConsoleLabel {
	String key;
	ConsoleClickHandler onClick;
	
	ConsoleLink(x, y, text, this.key, this.onClick, [fore = ConsoleColor.WHITE, back = ConsoleColor.BLACK]) : super(x, y, text, fore, back);
}

class Console {
	ConsoleRefreshHandler onRefresh;
	int width;
	int height;
	
	List<ConsoleLabel> labels = new List<ConsoleLabel>();
	
	final Element _consoleElement;
	
	Console(this.onRefresh) : _consoleElement = querySelector("#output") {
		refresh();
		
		window.onResize.listen((ev) {
			refresh();
		});
	}
	
	static String _colorToString(ConsoleColor color) {
		switch (color) {
			case ConsoleColor.BLACK: return "black";
			case ConsoleColor.MAROON: return "maroon";
			case ConsoleColor.GREEN: return "green";
			case ConsoleColor.OLIVE: return "olive";
			case ConsoleColor.NAVY: return "navy";
			case ConsoleColor.PURPLE: return "purple";
			case ConsoleColor.TEAL: return "teal";
			case ConsoleColor.SILVER: return "silver";
			case ConsoleColor.GREY: return "grey";
			case ConsoleColor.RED: return "red";
			case ConsoleColor.LIME: return "lime";
			case ConsoleColor.YELLOW: return "yellow";
			case ConsoleColor.BLUE: return "blue";
			case ConsoleColor.FUCHSIA: return "fuchsia";
			case ConsoleColor.AQUA: return "aqua";
			case ConsoleColor.WHITE: return "white";
		}
	}
	
	static ConsoleColor invertColor(ConsoleColor color) {
		return ConsoleColor.values[15 - color.index];
	}
	
	int centerJustified(String s) => width~/2 - s.length~/2;
	int rightJustified(String s) => width - s.length;
	
	void refresh() {
		// clear the screen
		
		for (Element e in _consoleElement.children) {
			e.remove();
		}
		
		// Find the new extents of the console
		
		int windowWidth = window.innerWidth;
		int windowHeight = window.innerHeight;
		
		_consoleElement.text = "X";
		int charWidth = _consoleElement.contentEdge.width.toInt() + 1;
		int charHeight = _consoleElement.contentEdge.height.toInt();
		_consoleElement.text = "";
		
		width = windowWidth ~/ charWidth;
		height = windowHeight ~/ charHeight;
		
		// recreate the HTML structure
		
		for (int row = 0; row < height; row++) {
			Element e = new Element.div();
			e.text = repeatString(_nbsp, width);
			_consoleElement.children.add(e);
		}
		
		// call event
		
		labels.clear();
		
		if (onRefresh != null) {
			onRefresh(this);
		}
		
		// draw labels and links
		
		Map<int, List<ConsoleLabel>> rowMap = new Map<int, List<ConsoleLabel>>();
		for (ConsoleLabel label in labels) {
			rowMap.putIfAbsent(label.y, () => new List<ConsoleLabel>());
			rowMap[label.y].add(label);
		}
		
		for (int row in rowMap.keys) {
			_consoleElement.children[row].text = "";
			
			rowMap[row].sort((a, b) => a.x.compareTo(b.x));
			int x = 0;
			for (ConsoleLabel label in rowMap[row]) {
				int diff = label.x - x;
				Element padding = new Element.div();
				padding.classes.add("inline");
				padding.text = repeatString(_nbsp, diff);
				_consoleElement.children[row].children.add(padding);
				
				if (label is ConsoleLink) {
					ConsoleLink link = label as ConsoleLink;
					
					AnchorElement linkElem = new AnchorElement(href: "javascript:0");
					linkElem.text = label.text;
					linkElem.style.color = _colorToString(label.fore);
					linkElem.style.backgroundColor = _colorToString(label.back);
					
					linkElem.onMouseEnter.listen((e) {
						linkElem.style.color = _colorToString(invertColor(label.fore));
						linkElem.style.backgroundColor = _colorToString(invertColor(label.back));
					});
					linkElem.onMouseLeave.listen((e) {
						linkElem.style.color = _colorToString(label.fore);
						linkElem.style.backgroundColor = _colorToString(label.back);
					});
					var conn;
					conn = window.onKeyPress.listen((e) {
						if (e.key == link.key && link.onClick != null) {
							conn.cancel();
							link.onClick(this, link);
							refresh();
						}
					});
					linkElem.onClick.listen((e) {
						if (link.onClick != null) {
							link.onClick(this, link);
							refresh();
						}
					});
					
					_consoleElement.children[row].children.add(linkElem);
				} else {
					Element labelElem = new Element.div();
					labelElem.classes.add("inline");
					labelElem.text = label.text;
					labelElem.style.color = _colorToString(label.fore);
					labelElem.style.backgroundColor = _colorToString(label.back);
					_consoleElement.children[row].children.add(labelElem);
				}
				
				x = label.x + label.text.length;
			}
			if (x < width) {
				int diff = width - x;
				Element padding = new Element.div();
				padding.classes.add("inline");
				padding.text = repeatString(_nbsp, diff);
				_consoleElement.children[row].children.add(padding);
			}
		}
	}
}