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
	int scoreOnKill = 0;
	CauseOfDeath causeOfDeath = new CauseOfDeath();
	
	void move(Tile newTile) {
		if (tile != null) {
			tile.entities.removeAt(tile.entities.indexOf(this));
		}
		tile = newTile;
		newTile.entities.add(this);
	}
	
	void addActions(List<ConsoleLink> actions) {}
	
	void onTick(Console c, int delta) {
		for (ItemStack item in new List.from(inventory.items)) {
			item.onTick(c, delta);
		}
		
		for (StatusCondition cond in new List.from(status)) {
			cond.onTick(this, delta);
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
	
	/// Called before all status conditions are rendered on the screen.
	void onRenderStatus(Console c) {
		for (StatusCondition cond in new List.from(status)) {
			cond.onRender(this, c);
		}
	}
}

class Player extends Entity {
	int hunger; int maxHunger;
	int hungerRate = 1;
	Console c;
	
	int regenPeriod = 4;
	int regenAmt = 1;
	
	int score = 0;
	
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
		
		// handle encumberance
		if (inventory.maxSize != null && inventory.size > inventory.maxSize) {
			if (!status.any((s) => s is StatusEncumbered)) {
				status.add(new StatusEncumbered());
			}
		}
		
		// handle hunger
		hunger += hungerRate * delta;
		
		if (hunger >= maxHunger) {
			// starvation
			hunger = maxHunger;
			
			if (!status.any((s) => s is StatusStarvation)) {
				status.add(new StatusStarvation());
			}
		}
		
		// handle natural regeneration
		int regenTimes = (delta + world.time % regenPeriod) ~/ regenPeriod;
		hp += regenTimes * regenAmt;
		if (hp > hpMax) {
			hp = hpMax;
		}
		
		// check if we're dead
		if (hp <= 0) {
			tileViewOverride = handlePlayerDeath;
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
		json["score"] = score;
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		hunger = json["hunger"] ?? 0;
		maxHunger = json["maxHunger"] ?? 500;
		hungerRate = json["hungerRate"] ?? 1;
		score = json["score"] ?? 0;
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

/*
==================
battles
==================
*/

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
		for (StatusCondition cond in user.status) {
			int passed = cond.onBattleTick(this, user);
			if (passed != null) {
				user.turnCooldown = max(0, passed - user.cooldownReduction);
				return;
			}
		}
		
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
	
	void hit(Entity user, Entity target, int dmg) {
		if (user != null) {
			target.causeOfDeath = new CauseAttack(user);
		}
		
		target.hp -= dmg;
		if (target.hp <= 0) {
			kill(target);
			if (user is Player) {
				(user as Player).score += target.scoreOnKill;
			}
		}
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
		
		b.hit(user, target, dmg);
		
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
	/// Called when the afflicted entity's turn comes up in battle. Return an int to cancel the entity's battle action and wait that many ticks.
	int onBattleTick(Battle battle, Entity entity) => null;
	/// Called before all status conditions are rendered on the screen.
	void onRender(Entity entity, Console c) {}
	
	void save(Map<String, Object> json) {
		throw new UnimplementedError("This subclass of StatusCondition did not implement a save handler.");
	}
	void load(World world, Entity entity, Map<String, Object> json) {
		throw new UnimplementedError("This subclass of StatusCondition did not implement a load handler.");
	}
}

abstract class StatusTimed extends StatusCondition {
	int time;
	int severity;
	
	StatusTimed.raw();
	StatusTimed(this.time, this.severity);
	
	@override
	void onTick(Entity entity, [int delta = 1]) {
		time -= delta;
		if (time <= 0) {
			entity.status.remove(this);
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["time"] = time;
		json["severity"] = severity;
	}
	@override
	void load(World world, Entity entity, Map<String, Object> json) {
		time = json["time"];
		severity = json["severity"];
	}
}

class StatusStarvation extends StatusCondition {
	String get name => "Starving";
	ConsoleColor get color => ConsoleColor.RED;
	
	StatusStarvation();
	
	@override
	void onTick(Entity entity, [int delta = 1]) {
		// remove if the player is not starving
		if (entity is Player && (entity as Player).hunger < (entity as Player).maxHunger) {
			entity.status.remove(this);
			return;
		}
		
		entity.causeOfDeath = new CauseStarvation();
		entity.hp -= delta;
	}
	@override
	int onBattleTick(Battle battle, Entity entity) {
		int dmg = rng.nextInt(entity.hpMax~/20)+1;
		battle.log.write("You're hungry! You take ");
		battle.log.write(dmg.toString());
		battle.log.write(" damage due to starvation.\n");
		
		entity.causeOfDeath = new CauseStarvation();
		battle.hit(null, entity, dmg);
		
		return null;
	}
	@override
	void onRender(Entity entity, Console c) {
		// remove if the player is not starving
		if (entity is Player && (entity as Player).hunger < (entity as Player).maxHunger) {
			entity.status.remove(this);
			return;
		}
	}
	
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

class StatusEncumbered extends StatusCondition {
	String get name => "Encumbered";
	ConsoleColor get color => ConsoleColor.SILVER;
	
	StatusEncumbered();
	
	@override
	void onTick(Entity entity, [int delta = 1]) {
		// remove if the player is not encumbered
		if (entity.inventory.maxSize == null || entity.inventory.size <= entity.inventory.maxSize) {
			entity.status.remove(this);
			return;
		}
	}
	@override
	void onRender(Entity entity, Console c) {
		// remove if the player is not encumbered
		if (entity.inventory.maxSize == null || entity.inventory.size <= entity.inventory.maxSize) {
			entity.status.remove(this);
			return;
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "StatusEncumbered";
	}
	@override
	void load(World world, Entity entity, Map<String, Object> json) {
		
	}
	
	StatusEncumbered.raw();
	static StatusCondition loadClass(World world, Entity entity, Map<String, Object> json) {
		return new StatusEncumbered.raw();
	}
}

class StatusDisease extends StatusTimed {
	String get name => "Diseased";
	ConsoleColor get color => ConsoleColor.GREEN;
	
	StatusDisease(int time, int severity) : super(time, severity);
	
	@override
	void onTick(Entity entity, [int delta = 1]) {
		super.onTick(entity, delta);
		delta = time >= 0 ? delta : -time;
		
		if (entity is Player) {
			(entity as Player).hunger += severity * delta;
		}
	}
	@override
	int onBattleTick(Battle battle, Entity entity) {
		return null;
	}
	
	@override
	void save(Map<String, Object> json) {
		super.save(json);
		json["class"] = "StatusDisease";
	}
	@override
	void load(World world, Entity entity, Map<String, Object> json) {
		super.load(world, entity, json);
	}
	
	StatusDisease.raw() : super.raw();
	static StatusCondition loadClass(World world, Entity entity, Map<String, Object> json) {
		return new StatusDisease.raw();
	}
}

typedef StatusCondition StatusConditionLoadHandler(World world, Entity entity, Map<String, Object> json);
Map<String, StatusConditionLoadHandler> statusConditionLoadHandlers = {
	"StatusStarvation": StatusStarvation.loadClass,
	"StatusDisease": StatusDisease.loadClass,
	"StatusEncumbered": StatusEncumbered.loadClass,
};

/*
==================
causes of death
==================
*/

class CauseOfDeath {
	String shortDesc = "Died in some mysterious way.";
	String longDesc = "For whatever reason... You have died.";
	
	List<String> epitaphs = [
		"They died as they lived- Quickly.",
		"Rest In Pieces",
		"Goodbye, World!",
	];
}

class CauseAttack extends CauseOfDeath {
	Entity attacker;
	
	CauseAttack(this.attacker) {
		epitaphs.add("Cut down at thier prime.");
		epitaphs.add("They went down fighting, sort of...");
		epitaphs.add("Punching things until the bitter end.");
	}
	
	String get shortDesc => "Slain by ${attacker.name}.";
	String get longDesc => "As the ${attacker.name.toLowerCase()} hits you, you suddenly feel weak. You fall, and the world fades away around you... The ${attacker.name.toLowerCase()} still looming over you as you pass.\n\nThe ${attacker.name.toLowerCase()} killed you, I'm afriad. You have died.";
}

class CauseStarvation extends CauseOfDeath {
	CauseStarvation() {
		epitaphs.add("Would kill for a bite to eat right now.");
	}
	
	String get shortDesc => "Starved to death.";
	String get longDesc => "You try taking another step forwards, but it's too much. You are too hungry to go on. Collapsing, you feel the last bits of life drain from you as you're left utterly weak, without a drop of blood spilled.\n\nYou starved youself for too long, and as such... You have died.";
}


/*
==================
custom entities
==================
*/

class EntityZombie extends Entity {
	EntityZombie() {
		name = "Zombie";
		hpMax = 50; hp = hpMax;
		scoreOnKill = 5;
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

class EntitySkeleton extends Entity {
	EntitySkeleton() {
		name = "Skeleton";
		hpMax = 30; hp = hpMax;
		scoreOnKill = 5;
	}
	
	String get char => "S";
	ConsoleColor get color => ConsoleColor.WHITE;
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "EntitySkeleton";
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		
	}
	
	EntitySkeleton.raw() : super.raw();
	static Entity loadClass(World world, Tile tile, Map<String, Object> json) {
		return new EntitySkeleton.raw();
	}
	
	BattleAction battleAi(Battle battle) {
		Entity target = battle.allies[0][rng.nextInt(battle.allies[0].length)];
		double hitChance = 0.4 + (0.4*battle.getRow(target));
		
		return battleActionHitOrMiss(this, target, "bow", rng.nextInt(6)+2, hitChance, 8);
	}
	
	List<ItemStack> get deathDrops => [new ItemStack(new ItemBone(), rng.nextInt(3)+1)];
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
	"EntitySkeleton": EntitySkeleton.loadClass,
};