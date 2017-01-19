import 'dart:html';
import 'dart:math';
import 'dart:async';

import 'myca_core.dart';

typedef void ConsoleRefreshHandler(Console c);
typedef void ConsoleClickHandler(Console c, ConsoleLink link);
typedef void ConsoleTextBoxHandler(Console c, ConsoleTextBox box, String text);

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
	
	ConsoleLabel clone() {
		return new ConsoleLabel(x, y, text, fore, back);
	}
}

class ConsoleLink extends ConsoleLabel {
	int key;
	ConsoleClickHandler onClick;
	
	static const int ANY_KEY = -1;
	
	ConsoleLink(x, y, text, var keyString, this.onClick, [fore = ConsoleColor.WHITE, back = ConsoleColor.BLACK]) : super(x, y, text, fore, back) {
		if (keyString is String) {
			key = keyString.codeUnitAt(0);
		} else if (keyString is int) {
			key = keyString;
		}
	}
	
	@override
	ConsoleLabel clone() {
		return new ConsoleLink(x, y, text, key, onClick, fore, back);
	}
}

class ConsoleTextBox extends ConsoleLabel {
	int size;
	String initText;
	ConsoleTextBoxHandler onTextEntry;
	
	ConsoleTextBox(x, y, this.initText, this.size, this.onTextEntry, [fore = ConsoleColor.WHITE, back = ConsoleColor.BLACK]) : super(x, y, repeatString(" ", size), fore, back);
	
	@override
	ConsoleLabel clone() {
		return new ConsoleTextBox(x, y, initText, size, onTextEntry, fore, back);
	}
}

class Console {
	ConsoleRefreshHandler onRefresh;
	int width;
	int height;
	
	List<ConsoleLabel> labels = new List<ConsoleLabel>();
	
	final Element _consoleElement;
	List<StreamSubscription> _conns = new List<StreamSubscription>();
	int _charWidth;
	int _charHeight;
	
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
		
		for (StreamSubscription conn in _conns) {
			conn.cancel();
		}
		_conns.clear();
		
		// Find the new extents of the console
		
		int windowWidth = window.innerWidth;
		int windowHeight = window.innerHeight;
		
		_consoleElement.text = "X";
		_charWidth = _consoleElement.contentEdge.width.toInt();
		_charHeight = _consoleElement.contentEdge.height.toInt();
		_consoleElement.text = "";
		
		width = windowWidth ~/ (_charWidth  + 1);
		height = windowHeight ~/ _charHeight;
		
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
			// alter the row map so that all labels are in increasing order, and do not overlap.
			// rowMap[row].sort((a, b) => a.x.compareTo(b.x));
			
			List<ConsoleLabel> onTop = new List<ConsoleLabel>();
			for (int i = 0; i <= width; i++) {
				onTop.add(null);
				for (ConsoleLabel label in rowMap[row]) {
					if (label.x <= i && label.x + label.text.length > i) {
						onTop[i] = label;
					}
				}
			}
			
			rowMap[row].clear();
			ConsoleLabel currLabel;
			ConsoleLabel lastLabel;
			for (int i = 0; i <= width; i++) {
				ConsoleLabel label = onTop[i];
				if (label == null) {
					if (currLabel !=  null) {
						rowMap[row].add(currLabel);
					}
					currLabel = null;
					lastLabel = null;
				} else {
					if (currLabel != null && lastLabel == label) {
						currLabel.text += new String.fromCharCode(label.text.codeUnitAt(i - label.x));
					} else {
						if (currLabel != null) {
							rowMap[row].add(currLabel);
						}
						
						currLabel = label.clone();
						currLabel.text = new String.fromCharCode(label.text.codeUnitAt(i - label.x));
						currLabel.x = i;
						
						lastLabel = label;
					}
				}
			}
			if (currLabel !=  null) {
				rowMap[row].add(currLabel);
			}
		}
		
		for (int row in rowMap.keys) {
			_consoleElement.children[row].text = "";
			
			int x = 0;
			for (ConsoleLabel label in rowMap[row]) {
				int diff = label.x - x;
				// Add the padding between the two labels, then add the label proper
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
					
					_conns.add(linkElem.onMouseEnter.listen((e) {
						linkElem.style.color = _colorToString(invertColor(label.fore));
						linkElem.style.backgroundColor = _colorToString(invertColor(label.back));
					}));
					_conns.add(linkElem.onMouseLeave.listen((e) {
						linkElem.style.color = _colorToString(label.fore);
						linkElem.style.backgroundColor = _colorToString(label.back);
					}));
					_conns.add(window.onKeyUp.listen((e) {
						if (e.keyCode == link.key || link.key == ConsoleLink.ANY_KEY) {
							if (link.onClick != null) {
								link.onClick(this, link);
								refresh();
							}
						}
					}));
					_conns.add(linkElem.onClick.listen((e) {
						if (link.onClick != null) {
							link.onClick(this, link);
							refresh();
						}
					}));
					
					_consoleElement.children[row].children.add(linkElem);
				} else if (label is ConsoleTextBox) {
					ConsoleTextBox box = label as ConsoleTextBox;
					
					TextInputElement boxElem = new TextInputElement();
					boxElem.classes.add("inline");
					boxElem.value = box.initText;
					boxElem.style.color = _colorToString(label.fore);
					boxElem.style.backgroundColor = _colorToString(label.back);
					
					boxElem.style.width = ((_charWidth-1)*box.size).toString() + "px";
					boxElem.style.height = _charHeight.toString() + "px";
					
					_conns.add(boxElem.onKeyUp.listen((e) {
						if (e.keyCode == 13 && box.onTextEntry != null) {
							box.onTextEntry(this, box, boxElem.value);
							refresh();
						}
					}));
					
					_consoleElement.children[row].children.add(boxElem);
					boxElem.focus();
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