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

class ConsoleKeyCode {
	static final ConsoleKeyCode ANY = new ConsoleKeyCode._raw();
	
	static final ConsoleKeyCode BACK = new ConsoleKeyCode._code(8);
	static final ConsoleKeyCode TAB = new ConsoleKeyCode._code(9);
	static final ConsoleKeyCode ENTER = new ConsoleKeyCode._code(13);
	static final ConsoleKeyCode ESC = new ConsoleKeyCode._code(27);
	static final ConsoleKeyCode PAGE_UP = new ConsoleKeyCode._code(33);
	static final ConsoleKeyCode PAGE_DOWN = new ConsoleKeyCode._code(34);
	static final ConsoleKeyCode END = new ConsoleKeyCode._code(35);
	static final ConsoleKeyCode HOME = new ConsoleKeyCode._code(36);
	static final ConsoleKeyCode LEFT = new ConsoleKeyCode._code(37);
	static final ConsoleKeyCode UP = new ConsoleKeyCode._code(38);
	static final ConsoleKeyCode RIGHT = new ConsoleKeyCode._code(39);
	static final ConsoleKeyCode DOWN = new ConsoleKeyCode._code(40);
	static final ConsoleKeyCode INSERT = new ConsoleKeyCode._code(45);
	static final ConsoleKeyCode DELETE = new ConsoleKeyCode._code(46);
	
	String key;
	int _keyCode;
	bool shift = false;
	bool ctrl = false;
	bool alt = false;
	bool meta = false;
	
	ConsoleKeyCode._raw();
	ConsoleKeyCode._code(this._keyCode, {this.shift: false, this.ctrl: false, this.alt: false, this.meta: false});
	
	ConsoleKeyCode(this.key) {
		this._keyCode = key.codeUnitAt(0);
		
		if ((this._keyCode >= 48 && this._keyCode <= 57) || this._keyCode == 32) {
			// some keys, like number keys or space, are already correct. No alterations needed.
		} else if (this._keyCode >= 65 && this._keyCode <= 90) {
			// uppercase letter, which has the correct keycode already, but needs to specify shift
			this.shift = true;
		} else if (this._keyCode >= 97 && this._keyCode <= 122) {
			// lowercase letter, which needs to be moved upwards
			this._keyCode = key.toUpperCase().codeUnitAt(0);
		} else {
			// A long list of specific symbols that don't map cleanly to char codes. Error if not in this list.
			switch (this.key) {
				case ")": this._keyCode = 48; this.shift = true; break;
				case "!": this._keyCode = 49; this.shift = true; break;
				case "@": this._keyCode = 50; this.shift = true; break;
				case "#": this._keyCode = 51; this.shift = true; break;
				case "\$": this._keyCode = 52; this.shift = true; break;
				case "%": this._keyCode = 53; this.shift = true; break;
				case "^": this._keyCode = 54; this.shift = true; break;
				case "&": this._keyCode = 55; this.shift = true; break;
				case "*": this._keyCode = 56; this.shift = true; break;
				case "(": this._keyCode = 57; this.shift = true; break;
				
				case ";": this._keyCode = 186; break;
				case ":": this._keyCode = 186; this.shift = true; break;
				case "=": this._keyCode = 187; break;
				case "+": this._keyCode = 187; this.shift = true; break;
				case ",": this._keyCode = 188; break;
				case "<": this._keyCode = 188; this.shift = true; break;
				case "-": this._keyCode = 189; break;
				case "_": this._keyCode = 189; this.shift = true; break;
				case ".": this._keyCode = 190; break;
				case ">": this._keyCode = 190; this.shift = true; break;
				case "/": this._keyCode = 191; break;
				case "?": this._keyCode = 191; this.shift = true; break;
				case "`": this._keyCode = 192; break;
				case "~": this._keyCode = 192; this.shift = true; break;
				case "[": this._keyCode = 219; break;
				case "{": this._keyCode = 219; this.shift = true; break;
				case "\\": this._keyCode = 220; break;
				case "|": this._keyCode = 220; this.shift = true; break;
				case "]": this._keyCode = 221; break;
				case "}": this._keyCode = 221; this.shift = true; break;
				case "'": this._keyCode = 222; break;
				case "\"": this._keyCode = 222; this.shift = true; break;
				
				default: throw new StateError("Unknown keycode '$key'");
			}
		}
	}
	
	ConsoleKeyCode withShift([bool modify = false]) {
		ConsoleKeyCode ret = new ConsoleKeyCode._raw();
		ret.key = this.key;
		ret._keyCode = this._keyCode;
		
		ret.shift = modify;
		ret.ctrl = this.ctrl;
		ret.alt = this.alt;
		ret.meta = this.meta;
		
		return ret;
	}
	
	ConsoleKeyCode withCtrl([bool modify = false]) {
		ConsoleKeyCode ret = new ConsoleKeyCode._raw();
		ret.key = this.key;
		ret._keyCode = this._keyCode;
		
		ret.shift = this.shift;
		ret.ctrl = modify;
		ret.alt = this.alt;
		ret.meta = this.meta;
		
		return ret;
	}
	
	ConsoleKeyCode withAlt([bool modify = false]) {
		ConsoleKeyCode ret = new ConsoleKeyCode._raw();
		ret.key = this.key;
		ret._keyCode = this._keyCode;
		
		ret.shift = this.shift;
		ret.ctrl = this.ctrl;
		ret.alt = modify;
		ret.meta = this.meta;
		
		return ret;
	}
	
	ConsoleKeyCode withMeta([bool modify = false]) {
		ConsoleKeyCode ret = new ConsoleKeyCode._raw();
		ret.key = this.key;
		ret._keyCode = this._keyCode;
		
		ret.shift = this.shift;
		ret.ctrl = this.ctrl;
		ret.alt = this.alt;
		ret.meta = modify;
		
		return ret;
	}
	
	bool _matches(KeyboardEvent e) {
		if (this == ANY && (e.keyCode < 37 || e.keyCode > 40)) {
			return true;
		}
		
		if (shift != e.shiftKey) {
			return false;
		}
		if (ctrl != e.ctrlKey) {
			return false;
		}
		if (alt != e.altKey) {
			return false;
		}
		if (meta != e.metaKey) {
			return false;
		}
		
		return _keyCode == e.keyCode;
	}
}

class ConsoleLink extends ConsoleLabel {
	ConsoleKeyCode key;
	ConsoleClickHandler onClick;
	
	ConsoleLink(x, y, text, var rawKey, this.onClick, [fore = ConsoleColor.WHITE, back = ConsoleColor.BLACK]) : super(x, y, text, fore, back) {
		if (rawKey == null || rawKey is ConsoleKeyCode) {
			key = rawKey;
		} else if (rawKey is String) {
			key = new ConsoleKeyCode(rawKey);
		} else {
			throw new StateError("Cannot convert '$rawKey' into a ConsoleKeyCode");
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
						if (link.key != null && link.key._matches(e)) {
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
							e.stopPropagation();
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