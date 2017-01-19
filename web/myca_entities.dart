import 'myca_core.dart';
import 'myca_items.dart';
import 'myca_world.dart';
import 'myca_console.dart';
import 'myca_gamesave.dart';

class Entity {
	String name;
	Inventory inventory = new Inventory(100.0);
	int hp; int hpMax;
	Tile tile;
	
	void move(Tile newTile) {
		if (tile != null) {
			tile.entities.removeAt(tile.entities.indexOf(this));
		}
		tile = newTile;
		newTile.entities.add(this);
	}
	
	void addActions(List<ConsoleLink> actions) {}
	
	void onTick(Console c, int delta) {
		for (ItemStack item in inventory.items) {
			item.onTick(c, delta);
		}
	}
	
	// ALWAYS override this. Set "class" to your class name, sop it can be loaded later.
	void save(Map<String, Object> json) {
		throw new UnimplementedError("This subclass of Entity did not implement a save handler.");
	}
}

class Player extends Entity {
	int hunger; int maxHunger;
	int hungerRate = 1;
	Console c;
	
	Player(String nname) {
		this.name = nname;
		
		hpMax = 100;
		hp = hpMax;
		
		hunger = 0;
		maxHunger = 500;
	}
	
	@override
	void onTick(Console c2, int delta) {
		super.onTick(c2, delta);
		
		c = c2;
		
		if (hunger >= maxHunger) {
			// starvation
			hunger = maxHunger;
			hp -= delta;
		} else {
			// the player gets more hungry every tick
			hunger += hungerRate * delta;
		}
	}
	
	@override
	void move(Tile newTile) {
		if (c != null && tile != null) {
			tile.timeAtLastVisit = tile.world.time;
		}
		
		super.move(newTile);
		
		if (c != null && tile != null) {
			int delta = tile.world.time - tile.timeAtLastVisit;
			for (Feature f in tile.features) {
				f.onTick(c, delta);
			}
			for (Entity e in tile.entities) {
				if (e == this) {continue;}
				e.onTick(c, delta);
			}
			tile.timeAtLastVisit = tile.world.time;
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "Player";
		json["hunger"] = hunger;
		json["maxHunger"] = maxHunger;
		json["hungerRate"] = hungerRate;
	}
}