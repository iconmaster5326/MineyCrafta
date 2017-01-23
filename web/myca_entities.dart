import 'dart:math';

import 'myca_core.dart';
import 'myca_items.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_console.dart';
import 'myca_gamesave.dart';
import 'myca_ui.dart';

import 'myca_item_data.dart';

class Entity {
	String name;
	Inventory inventory = new Inventory(100.0);
	int hp; int hpMax;
	Tile tile;
	String char; ConsoleColor color;
	List<StatusCondition> status = [];
	
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
	
	/// The items you drop on death. By default, this is the contents of the inventory.
	List<ItemStack> get deathDrops => inventory.items;
}

class Player extends Entity {
	int hunger; int maxHunger;
	int hungerRate = 1;
	Console c;
	
	String get char => "@";
	ConsoleColor get color => ConsoleColor.WHITE;
	
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
			Battle battle = new Battle();
			battle.allies.add([this]);
			battle.enemies = tile.randomEncounter();
			battle.init();
			
			String dialogText = "Suddenly, you're assaulted by a roving pack of enemies! They include:\n\n";
			for (List<Entity> row in battle.enemies) {
				for (Entity e in row) {
					dialogText += "* " + e.name + "\n";
				}
			}
			
			tileViewOverride = handleNotifyDialog(dialogText, (c) {
				c.onRefresh = handleBattle(c, battle);
			}, "To Battle!");
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
	Inventory loot = new Inventory();
	
	static List<Entity> _flatten(List<List<Entity>> li) => li.reduce((a, b) => new List.from(a)..addAll(b));
	
	void init() {
		for (Entity e in _flatten(allies)) {
			e.turnCooldown = max(0, rng.nextInt(10) - e.cooldownReduction);
		}
		for (Entity e in _flatten(enemies)) {
			e.turnCooldown = max(0, rng.nextInt(10) - e.cooldownReduction);
		}
		
		for (List<Entity> li in new List.from(allies)) {
			if (li.isEmpty) {
				allies.remove(li);
			}
		}
		for (List<Entity> li in new List.from(enemies)) {
			if (li.isEmpty) {
				enemies.remove(li);
			}
		}
	}
	
	void doAction(Entity user, BattleAction action) {
		int passed = action(this);
		user.turnCooldown = max(0, passed - user.cooldownReduction);
	}
	
	/// Returns true if the battle is over, and false if we're waiting for the player's input.
	bool doTurn() {
		do {
			// Return if all of one side or the other is dead
			if (allies.isEmpty || enemies.isEmpty) {
				return true;
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
						return false;
					}
					
					doAction(e, ai);
				}
			}
			for (Entity e in _flatten(enemies)) {
				if (e.turnCooldown <= 0) {
					e.turnCooldown = 0;
					BattleAction ai = e.battleAi(this);
					if (ai == null) {
						return false;
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
	
	bool canMoveForwards(Entity entity) {
		int row = getRow(entity);
		List<List<Entity>> side = isEmeny(entity) ? enemies : allies;
		
		if (row == 0 && side[row].length == 1) {
			return false;
		}
		
		return true;
	}
	
	void moveForwards(Entity entity) {
		int row = getRow(entity);
		List<List<Entity>> side = isEmeny(entity) ? enemies : allies;
		side[row].remove(entity);
		
		if (row == 0) {
			side.insert(0, [entity]);
		} else {
			side[row-1].add(entity);
		}
		
		for (List<Entity> li in new List.from(side)) {
			if (li.isEmpty) {
				side.remove(li);
			}
		}
	}
	
	bool canMoveBackwards(Entity entity) {
		int row = getRow(entity);
		List<List<Entity>> side = isEmeny(entity) ? enemies : allies;
		
		if (row == side.length-1 && side[row].length == 1) {
			return false;
		}
		
		return true;
	}
	
	void moveBackwards(Entity entity) {
		int row = getRow(entity);
		List<List<Entity>> side = isEmeny(entity) ? enemies : allies;
		side[row].remove(entity);
		
		if (row == side.length-1) {
			side.add([entity]);
		} else {
			side[row+1].add(entity);
		}
		
		for (List<Entity> li in new List.from(side)) {
			if (li.isEmpty) {
				side.remove(li);
			}
		}
	}
	
	bool isInBattle(Entity entity) {
		for (List<Entity> a in allies) {
			if (a.contains(entity)) {
				return true;
			}
		}
		for (List<Entity> a in enemies) {
			if (a.contains(entity)) {
				return true;
			}
		}
		return false;
	}
	
	void kill(Entity entity) {
		if (entity is Player) {
			log.write("You die...\n");
		} else {
			log.write(entity.name);
			log.write(" dies!\n");
		}
		
		remove(entity);
		loot.addAll(entity.deathDrops);
	}
	
	int getRow(Entity entity) {
		int i;
		
		i = 0;
		for (List<Entity> a in allies) {
			if (a.contains(entity)) {
				return i;
			}
			i++;
		}
		
		i = 0;
		for (List<Entity> a in enemies) {
			if (a.contains(entity)) {
				return i;
			}
			i++;
		}
		
		return null;
	}
	
	bool isEmeny(Entity entity) {
		for (List<Entity> a in allies) {
			if (a.contains(entity)) {
				return false;
			}
		}
		for (List<Entity> a in enemies) {
			if (a.contains(entity)) {
				return true;
			}
		}
		return null;
	}
}

/*
==================
basic actions
==================
*/

BattleAction battleActionDoNothing(Entity user, int time) {
	return (b) {
		return time;
	};
}

BattleAction battleActionAttack(Entity user, Entity target, String withDesc, int dmg, int time) {
	return (b) {
		if (user is Player) {
			b.log.write("You attack ");
			b.log.write(target.name);
			b.log.write(" with your ");
		} else if (target is Player) {
			b.log.write(user.name);
			b.log.write(" attacks you with thier ");
		} else {
			b.log.write(user.name);
			b.log.write(" attacks ");
			b.log.write(target.name);
			b.log.write(" with thier ");
		}
		b.log.write(withDesc);
		b.log.write(", dealing ");
		b.log.write(dmg.toString());
		b.log.write(" damage!\n");
		
		target.hp -= dmg;
		if (target.hp <= 0) {
			b.kill(target);
		}
		
		return time;
	};
}

BattleAction battleActionMiss(Entity user, Entity target, String withDesc, int time) {
	return (b) {
		if (user is Player) {
			b.log.write("You attack ");
			b.log.write(target.name);
			b.log.write(" with your ");
		} else if (target is Player) {
			b.log.write(user.name);
			b.log.write(" attacks you with thier ");
		} else {
			b.log.write(user.name);
			b.log.write(" attacks ");
			b.log.write(target.name);
			b.log.write(" with thier ");
		}
		b.log.write(withDesc);
		b.log.write("... But ");
		b.log.write(user is Player ? "you" : "they");
		b.log.write(" miss!\n");
		
		return time;
	};
}

BattleAction battleActionHitOrMiss(Entity user, Entity target, String withDesc, int dmg, double hitChance, int time) {
	return (b) {
		if (rng.nextDouble() < hitChance) {
			return battleActionAttack(user, target, withDesc, dmg, time)(b);
		} else {
			return battleActionMiss(user, target, withDesc, time)(b);
		}
	};
}

BattleAction battleActionMoveForwards(Entity user) {
	return (b) {
		if (user is Player) {
			b.log.write("You move forwards.\n");
		} else {
			b.log.write(user.name);
			b.log.write(" moves forwards.\n");
		}
		
		b.moveForwards(user);
		
		return 4;
	};
}

BattleAction battleActionMoveBackwards(Entity user) {
	return (b) {
		if (user is Player) {
			b.log.write("You move backwards.\n");
		} else {
			b.log.write(user.name);
			b.log.write(" moves backwards.\n");
		}
		
		b.moveBackwards(user);
		
		return 4;
	};
}

/*
==================
status conditions
==================
*/

abstract class StatusCondition {
	String name;
	ConsoleColor color;
	
	/// Called when `delta` ticks pass.
	void onTick(Entity entity, [int delta = 1]) {}
	/// Called when the afflicted entity's turn comes up in battle. Return true to cancel the entity's battle action.
	bool onBattleTick(Battle battle, Entity entity) => false;
	
	void save(Map<String, Object> json) {
		throw new UnimplementedError("This subclass of StatusCondition did not implement a save handler.");
	}
	void load(World world, Entity entity, Map<String, Object> json) {
		throw new UnimplementedError("This subclass of StatusCondition did not implement a load handler.");
	}
}

class StatusStarvation extends StatusCondition {
	String get name => "Starving";
	ConsoleColor get color => ConsoleColor.RED;
	
	StatusStarvation();
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "StatusStarvation";
	}
	@override
	void load(World world, Entity entity, Map<String, Object> json) {
		
	}
	
	StatusStarvation.raw();
	static StatusCondition loadClass(World world, Entity entity, Map<String, Object> json) {
		return new StatusStarvation.raw();
	}
}

typedef StatusCondition StatusConditionLoadHandler(World world, Entity entity, Map<String, Object> json);
Map<String, StatusConditionLoadHandler> statusConditionLoadHandlers = {
	"StatusStarvation": StatusStarvation.loadClass,
};

/*
==================
custom entities
==================
*/

class EntityZombie extends Entity {
	EntityZombie() {
		name = "Zombie";
		hpMax = 50; hp = hpMax;
	}
	
	String get char => "Z";
	ConsoleColor get color => ConsoleColor.GREEN;
	
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
	
	BattleAction battleAi(Battle battle) {
		Entity target = battle.allies[0][rng.nextInt(battle.allies[0].length)];
		double hitChance = 0.8 - (0.4*battle.getRow(target));
		
		return battleActionHitOrMiss(this, target, "rotten fists", rng.nextInt(4)+1, hitChance, 8);
	}
	
	List<ItemStack> get deathDrops => [new ItemStack(new ItemRottenFlesh(), rng.nextInt(3)+1)];
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