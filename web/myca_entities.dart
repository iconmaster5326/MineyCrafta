import 'myca_core.dart';
import 'myca_items.dart';
import 'myca_world.dart';

class Entity {
	String name;
	Inventory inventory;
	int hp; int hpMax;
	Tile tile;
	
	void move(Tile newTile) {
		if (tile != null) {
			tile.entities.removeAt(tile.entities.indexOf(this));
		}
		tile = newTile;
		newTile.entities.add(this);
	}
}

class Player extends Entity {
	
}