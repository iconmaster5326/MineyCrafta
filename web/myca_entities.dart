import 'dart:math';

import 'myca_core.dart';
import 'myca_items.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
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
	void load(World world, Tile tile, Map<String, Object> json) {
		throw new UnimplementedError("This subclass of Entity did not implement a load handler.");
	}
	
	Entity();
	Entity.raw();
	
	/// These properties are for inside battle. They do not need to be saved.
	int cooldownReduction = 0;
	int turnCooldown;
	
	BattleAction battleAi(Battle battle) {
		return battleActionDoNothing(this, 4);
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
		
		// We need to use the console elsewhere, so save it.
		c = c2;
		
		// handle hunger
		if (hunger >= maxHunger) {
			// starvation
			hunger = maxHunger;
			hp -= delta;
		} else {
			hunger += hungerRate * delta;
		}
		
		// check if we're dead
		if (hp <= 0) {
		
		}
		
		// check if we got into an encounter
		double encounterChance = 0.0;
		if (tile.light < .25) {
			encounterChance = 0.1;
		} else if (tile.light < .5) {
			encounterChance = 0.05;
		}
		encounterChance *= delta;
		
		if (rng.nextDouble() < encounterChance) {
			// trigger encounter
			
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
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		hunger = json["hunger"];
		maxHunger = json["maxHunger"];
		hungerRate = json["hungerRate"];
	}
	
	Player.raw() : super.raw();
	static Entity loadClass(World world, Tile tile, Map<String, Object> json) {
		world.player = new Player.raw();
		return world.player;
	}
	
	@override
	BattleAction battleAi(Battle battle) {
		return null;
	}
}

typedef int BattleAction(Battle battle);
class Battle {
	int time = 0;
	List<List<Entity>> allies = [];
	List<List<Entity>> enemies = [];
	StringBuffer log = new StringBuffer();
	
	static List<Entity> _flatten(List<List<Entity>> li) => li.reduce((a, b) => new List.from(a)..addAll(b));
	
	void init() {
		for (Entity e in _flatten(allies)) {
			e.turnCooldown = max(0, rng.nextInt(10) - e.cooldownReduction);
		}
		for (Entity e in _flatten(enemies)) {
			e.turnCooldown = max(0, rng.nextInt(10) - e.cooldownReduction);
		}
	}
	
	void doAction(Entity user, BattleAction action) {
		int passed = action(this);
		user.turnCooldown = max(0, passed - user.cooldownReduction);
	}
	
	void doTurn() {
		log.clear();
		
		do {
			// Return if all of one side or the other is dead
			if (allies.isEmpty || enemies.isEmpty) {
				return;
			}
			
			// find the entity that will go next
			int minCooldown;
			for (Entity e in _flatten(allies)) {
				if (minCooldown == null || e.turnCooldown < minCooldown) {
					minCooldown = e.turnCooldown;
				}
			}
			for (Entity e in _flatten(enemies)) {
				if (minCooldown == null || e.turnCooldown < minCooldown) {
					minCooldown = e.turnCooldown;
				}
			}
			
			// make time pass
			time += minCooldown;
			
			for (Entity e in _flatten(allies)) {
				e.turnCooldown -= minCooldown;
			}
			for (Entity e in _flatten(enemies)) {
				e.turnCooldown -= minCooldown;
			}
			
			// if any entity has a cooldown of <= 0, do their turn
			for (Entity e in _flatten(allies)) {
				if (e.turnCooldown <= 0) {
					e.turnCooldown = 0;
					BattleAction ai = e.battleAi(this);
					if (ai == null) {
						return;
					}
					
					doAction(e, ai);
				}
			}
			for (Entity e in _flatten(enemies)) {
				if (e.turnCooldown <= 0) {
					e.turnCooldown = 0;
					BattleAction ai = e.battleAi(this);
					if (ai == null) {
						return;
					}
					
					doAction(e, ai);
				}
			}
			
			// end the loop if it's the player's turn (i.e., has a battle ai of null)
		} while (true);
	}
	
	void remove(Entity entity) {
		for (List<Entity> a in new List.from(allies)) {
			if (a.contains(entity)) {
				a.remove(entity);
				if (a.isEmpty) {
					allies.remove(a);
				}
				return;
			}
		}
		for (List<Entity> a in new List.from(enemies)) {
			if (a.contains(entity)) {
				a.remove(entity);
				if (a.isEmpty) {
					enemies.remove(a);
				}
				return;
			}
		}
	}
	
	void moveForwards(Entity entity) {
		
	}
	
	void moveBackwards(Entity entity) {
		
	}
}

BattleAction battleActionDoNothing(Entity user, int time) {
	return (b) {
		b.log.write(user.name);
		b.log.write(" does nothing!");
		return time;
	};
}

/*
==================
custom entities
==================
*/

class EntityZombie extends Entity {
	EntityZombie() {
		name = "Zombie";
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "EntityZombie";
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		
	}
	
	EntityZombie.raw() : super.raw();
	static Entity loadClass(World world, Tile tile, Map<String, Object> json) {
		return new EntityZombie.raw();
	}
}

/*
==================
Load handler map
==================
*/

typedef Entity EntityLoadHandler(World world, Tile tile, Map<String, Object> json);
Map<String, EntityLoadHandler> entityLoadHandlers = {
	"Player": Player.loadClass,
	"EntityZombie": EntityZombie.loadClass,
};