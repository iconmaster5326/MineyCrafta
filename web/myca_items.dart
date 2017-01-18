import 'myca_core.dart';

class Item {
	String name;
	Inventory inventory;
	int size = 0;
	bool stackable = false; int amount = 1;
}

class Inventory {
	List<Item> items = new List<Item>();
	int size = 0; int maxSize;
}