import 'dart:math';

import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_items.dart';
import 'myca_entities.dart';
import 'myca_console.dart';
import 'myca_gamesave.dart';
import 'myca_ui.dart';

import 'myca_features_data.dart';

/*
wood
*/

class ItemWood extends Item {
	TreeBreed breed;
	
	static Map<TreeBreed, ItemWood> _cache = {};
	ItemWood._fresh(this.breed);
	factory ItemWood(TreeBreed breed) {
		if (_cache[breed] == null) {
			_cache[breed] = new ItemWood._fresh(breed);
		}
		return _cache[breed];
	}
	
	@override String name(ItemStack stack) => breed.name + " Wood";
	@override double size(ItemStack stack) => 1.0;
	@override bool stackable(ItemStack stack) => true;
	@override ConsoleColor color(ItemStack stack) => breed.trunkColor;
	@override String desc(ItemStack stack) => "This is some chopped-up wood from a " + breed.name.toLowerCase() + " tree.";
	@override int hardness(ItemStack stack) => 1;
	@override int value(ItemStack stack) => 1;
	@override String materialName(ItemStack stack) => breed.name.toLowerCase() + " wood";
	@override int fuelValue(ItemStack stack) => 1;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		json["class"] = "ItemWood";
		json["breed"] = breed.name;
	}
	@override
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemWood(treeBreeds[json["breed"]]));
	}
}

/*
cobble
*/

class ItemCobble extends Item {
	static ItemCobble _cached;
	ItemCobble.raw();
	factory ItemCobble() {
		if (_cached == null) {
			_cached = new ItemCobble.raw();
		}
		return _cached;
	}
	
	@override String name(ItemStack stack) => "Cobblestone";
	@override double size(ItemStack stack) => 2.0;
	@override bool stackable(ItemStack stack) => true;
	@override ConsoleColor color(ItemStack stack) => ConsoleColor.GREY;
	@override String desc(ItemStack stack) => "This is a pile of rocks. Just boring old rocks. Nothing special, really.";
	@override int hardness(ItemStack stack) => 5;
	@override int value(ItemStack stack) => 1;
	@override String materialName(ItemStack stack) => "stone";
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		json["class"] = "ItemCobble";
	}
	@override
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemCobble());
	}
}

/*
food
*/

abstract class ItemFood extends Item {
	int foodValue(ItemStack stack) => 0;
	String onEatString(ItemStack stack) => "You eat the "+name(stack)+". Delicious!";
	
	ItemFood();
	ItemFood.raw();
	
	@override bool usable(ItemStack stack) => world.player.hunger > 0;
	@override String useText(ItemStack stack) => "Eat";
	@override
	void use(ItemStack stack, Console c) {
		c.onRefresh = handleNotifyDialog(onEatString(stack), (c) {
			world.player.hunger -= foodValue(stack); if (world.player.hunger < 0) {world.player.hunger = 0;}
			stack.take(1);
			
			c.onRefresh = handleInventoryView;
		});
	}
}

class ItemRottenFlesh extends ItemFood {
	static ItemRottenFlesh _cached;
	ItemRottenFlesh.raw();
	factory ItemRottenFlesh() {
		if (_cached == null) {
			_cached = new ItemRottenFlesh.raw();
		}
		return _cached;
	}
	
	@override String name(ItemStack stack) => "Rotten Flesh";
	@override double size(ItemStack stack) => 0.5;
	@override bool stackable(ItemStack stack) => true;
	@override ConsoleColor color(ItemStack stack) => ConsoleColor.MAROON;
	@override String desc(ItemStack stack) => "This slab of meat looks very long-gone. Maybe it would be an unwise idea to try and eat it.";
	@override int value(ItemStack stack) => 1;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		json["class"] = "ItemRottenFlesh";
	}
	@override
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemRottenFlesh());
	}
	
	@override int foodValue(ItemStack stack) => 10;
	@override String onEatString(ItemStack stack) => "You eat a bit of rotten flesh. Tastes terrible...\n\nSuddenly, you don't feel so good... You have been diseased!";
	@override
	void use(ItemStack stack, Console c) {
		super.use(stack, c);
		world.player.status.add(new StatusDisease(10, 4));
	}
}

/*
ores/ingots
*/

class MetalType {
	String name;
	double size;
	int hardness;
	int value;
	ConsoleColor color;
	
	MetalType(this.name, this.size, this.hardness, this.value, this.color);
}

Map<String, MetalType> metalTypes = {
	"Iron": new MetalType("Iron", 4.0, 10, 20, ConsoleColor.SILVER),
	"Gold": new MetalType("Gold", 8.0, 2, 50, ConsoleColor.YELLOW),
};

class ItemOre extends Item {
	MetalType type;
	
	static Map<MetalType, ItemOre> _cache = {};
	ItemOre._fresh(this.type);
	factory ItemOre(MetalType type) {
		if (_cache[type] == null) {
			_cache[type] = new ItemOre._fresh(type);
		}
		return _cache[type];
	}
	
	@override String name(ItemStack stack) => type.name + " Ore";
	@override double size(ItemStack stack) => type.size;
	@override bool stackable(ItemStack stack) => true;
	@override ConsoleColor color(ItemStack stack) => type.color;
	@override String desc(ItemStack stack) => "This is a hunk of stone bearing some " + type.name.toLowerCase() + ". Smelt it to extract the lovely metal inside!";
	@override int value(ItemStack stack) => type.value ~/ 2;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		json["class"] = "ItemOre";
		json["type"] = type.name;
	}
	@override
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemOre(metalTypes[json["type"]]));
	}
}

class ItemIngot extends Item {
	MetalType type;
	
	static Map<MetalType, ItemIngot> _cache = {};
	ItemIngot._fresh(this.type);
	factory ItemIngot(MetalType type) {
		if (_cache[type] == null) {
			_cache[type] = new ItemIngot._fresh(type);
		}
		return _cache[type];
	}
	
	@override String name(ItemStack stack) => type.name + " Ingot";
	@override double size(ItemStack stack) => type.size;
	@override bool stackable(ItemStack stack) => true;
	@override ConsoleColor color(ItemStack stack) => type.color;
	@override String desc(ItemStack stack) => "This is a solid ingot of " + type.name.toLowerCase() + ". This form makes it shiny, stackable, and suitable for crafting into powerful tools.";
	@override int hardness(ItemStack stack) => type.hardness;
	@override int value(ItemStack stack) => type.value;
	@override String materialName(ItemStack stack) => type.name.toLowerCase();
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		json["class"] = "ItemIngot";
		json["type"] = type.name;
	}
	@override
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemIngot(metalTypes[json["type"]]));
	}
}

class RecipeIngot extends SmeltingRecipe {
	RecipeIngot() {
		name = "Metal Ingot";
		desc = "You need to smelt ores into ingots before crafting with them. Because trust me, you don't want metallic impurities in your tools.";
		inputs = [
			new RecipeInput("of any ore", (stack) => (stack.item is ItemOre), 1),
		];
		timePassed = 2;
		fuel = 1;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]) => [new ItemStack(new ItemIngot((items[0].item as ItemOre).type), factor)];
}

/*
liquids
*/

class LiquidWater extends Liquid {
	static LiquidWater _cached;
	LiquidWater.raw();
	factory LiquidWater() {
		if (_cached == null) {
			_cached = new LiquidWater.raw();
		}
		return _cached;
	}
	
	@override String name(LiquidStack stack) => "Water";
	@override ConsoleColor color(LiquidStack stack) => ConsoleColor.BLUE;
	@override double size(LiquidStack stack) => 0.001;
	
	@override
	void onDrink(LiquidStack stack, Console c, int amt) {
		
	}
	
	@override
	void save(LiquidStack stack, Map<String, Object> json) {
		json["class"] = "LiquidWater";
	}
	@override
	void load(LiquidStack stack, World world, Map<String, Object> json) {
		
	}
	
	static LiquidStack loadClass(World world, Map<String, Object> json) {
		return new LiquidStack(new LiquidWater(), 0);
	}
}

typedef LiquidStack LiquidLoadHandler(World world, Inventory inventory, Map<String, Object> json);
Map<String, LiquidLoadHandler> liquidLoadHandlers = {
	"LiquidWater": LiquidWater.loadClass,
};

/*
liquid containers
*/

abstract class ItemLiquidContainer extends Item {
	int maxLiquid;
	
	@override double size(ItemStack stack) => (stack.data as LiquidStack).size * (stack.data as LiquidStack).amt;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		if ((stack.data as LiquidStack).liquid != null) {
			json["liquid"] = saveLiquid(stack.data);
		}
	}
	@override
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		stack.data = stack.data ?? new LiquidStack.raw();
		
		stack.data = loadLiquid(world, json["liquid"]);
	}
	
	ItemLiquidContainer();
	ItemLiquidContainer.raw();
	
	LiquidStack takeLiquid(ItemStack stack, int amt) {
		LiquidStack lstack = (stack.data as LiquidStack);
		lstack.amt -= amt;
		
		Liquid retLiquid = lstack.liquid;
		int retAmt = amt;
		
		if (lstack.amt <= 0) {
			retAmt += lstack.amt;
			
			lstack.amt = 0;
			lstack.liquid = null;
		}
		
		return new LiquidStack(retLiquid, retAmt);
	}
	
	void giveLiquid(ItemStack stack, LiquidStack toGive) {
		LiquidStack lstack = (stack.data as LiquidStack);
		
		if (lstack.liquid != null && toGive.liquid != lstack.liquid) {
			return;
		}
		
		lstack.amt += toGive.amt;
		lstack.liquid = toGive.liquid;
		
		toGive.amt = 0;
		
		if (lstack.amt > maxLiquid) {
			toGive.amt += lstack.amt - maxLiquid;
			lstack.amt = maxLiquid;
		}
		
		if (toGive.amt == 0) {
			toGive.liquid = null;
		}
	}
}

class ItemBucket extends ItemLiquidContainer {
	ItemStack material;
	
	ItemBucket(this.material);
	
	@override int get maxLiquid => 1000;
	
	@override String name(ItemStack stack) => capitalize(material.materialName) + " Bucket";
	@override double size(ItemStack stack) => super.size(stack) + material.size * 3;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => material.color;
	@override String desc(ItemStack stack) {
		StringBuffer buf = new StringBuffer();
		
		buf.write("This is a bucket. It might even be a pail, who knows. Regardless, you can use it to transport liquids around.\nIt is made of ");
		buf.write(material.materialName);
		buf.write(". ");
		
		LiquidStack data = (stack.data as LiquidStack);
		if (data.liquid == null) {
			buf.write("It is empty.");
		} else {
			buf.write("It is filled with ");
			buf.write(data.amt.toString());
			buf.write(" millibuckets of ");
			buf.write(data.name.toLowerCase());
			buf.write(".");
		}
		
		return buf.toString();
	}
	@override int value(ItemStack stack) => (material.value * 3)*5~/4;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		super.save(stack, json);
		
		json["class"] = "ItemBucket";
		json["material"] = saveItem(material);
	}
	@override
	void load(ItemStack stack, World world, Inventory inv, Map<String, Object> json) {
		super.load(stack, world, inv, json);
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemBucket(loadItem(world, inventory, json["material"])), 1, new LiquidStack.raw());
	}
}

class RecipeBucket extends ItemRecipe {
	RecipeBucket() {
		name = "Bucket";
		desc = "Use a bucket to haul around large amounts of liquid. Any liquid! That's right, hold lava in a wooden bucket!";
		inputs = [
			new RecipeInput("of any wood, metal", filterAnyWoodMetal, 3),
		];
		timePassed = 4;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]) => new List.generate(factor, (i) {
		return new ItemStack(new ItemBucket(items[0]), 1, new LiquidStack.raw());
	});
}

/*
tools
*/

abstract class ItemDurable extends Item {
	int maxDurability;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		json["durability"] = stack.data;
	}
	@override
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		stack.data = json["durability"];
	}
	
	ItemDurable();
	ItemDurable.raw();
	
	void takeDamage(ItemStack stack, int amount) {
		stack.data = max(0, (stack.data as int) - amount);
	}
}

/*
axe
*/

class ItemAxe extends ItemDurable {
	ItemStack head;
	ItemStack handle;
	
	ItemAxe(this.head, this.handle);
	
	@override String name(ItemStack stack) {
		if ((stack.data as int) <= 0) {
			return capitalize(head.materialName) + " Axe (broken)";
		} else {
			return capitalize(head.materialName) + " Axe (" + ((stack.data as int)/maxDurability*100).toStringAsFixed(0)+"%)";
		}
	}
	@override double size(ItemStack stack) => head.size * 4 + handle.size * 2;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => head.color;
	@override String desc(ItemStack stack) => "This is an axe, useful for cutting down trees and demolishing carpentry.\nThe head is made of " + head.materialName + ". The handle is made of " + handle.materialName + ".";
	@override int value(ItemStack stack) => (head.value * 4 + handle.value * 2)*5~/4;
	
	int get maxDurability => head.hardness * 75 + handle.hardness * 25;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		super.save(stack, json);
		
		json["class"] = "ItemAxe";
		json["head"] = saveItem(head);
		json["handle"] = saveItem(handle);
	}
	@override
	void load(ItemStack stack, World world, Inventory inv, Map<String, Object> json) {
		super.load(stack, world, inv, json);
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemAxe(loadItem(world, inventory, json["head"]), loadItem(world, inventory, json["handle"])), 1, (json["durability"] as int));
	}
}

class RecipeAxe extends ItemRecipe {
	RecipeAxe() {
		name = "Axe";
		desc = "Axes are useful for chopping down trees. Much more efficent than just punching trees like a madman.";
		inputs = [
			new RecipeInput("of any wood, metal, stone (head)", filterAnyWoodMetalStone, 4),
			new RecipeInput("of any wood, metal (handle)", filterAnyWoodMetal, 2),
		];
		timePassed = 4;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]) => new List.generate(factor, (i) {
		ItemAxe item = new ItemAxe(items[0], items[1]);
		return new ItemStack(item, 1, item.maxDurability);
	});
}

/*
pick
*/

class ItemPick extends ItemDurable {
	ItemStack head;
	ItemStack handle;
	
	ItemPick(this.head, this.handle);
	
	@override String name(ItemStack stack) {
		if ((stack.data as int) <= 0) {
			return capitalize(head.materialName) + " Pick (broken)";
		} else {
			return capitalize(head.materialName) + " Pick (" + ((stack.data as int)/maxDurability*100).toStringAsFixed(0)+"%)";
		}
	}
	@override double size(ItemStack stack) => head.size * 4 + handle.size * 2;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => head.color;
	@override String desc(ItemStack stack) => "This is a pick. It's the tool you use for getting between the earth and its valuable minerals! Not like the earth needs them anyways.\nThe head is made of " + head.materialName + ". The handle is made of " + handle.materialName + ".";
	@override int value(ItemStack stack) => (head.value * 4 + handle.value * 2)*5~/4;
	
	int get maxDurability => head.hardness * 75 + handle.hardness * 25;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		super.save(stack, json);
		
		json["class"] = "ItemPick";
		json["head"] = saveItem(head);
		json["handle"] = saveItem(handle);
	}
	@override
	void load(ItemStack stack, World world, Inventory inv, Map<String, Object> json) {
		super.load(stack, world, inv, json);
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemPick(loadItem(world, inventory, json["head"]), loadItem(world, inventory, json["handle"])), 1, (json["durability"] as int));
	}
}

class RecipePick extends ItemRecipe {
	RecipePick() {
		name = "Pick";
		desc = "Make a pick to dig through rock, and perhaps more importantly, extract valuable minerals from said rock.";
		inputs = [
			new RecipeInput("of any wood, metal, stone (head)", filterAnyWoodMetalStone, 4),
			new RecipeInput("of any wood, metal (handle)", filterAnyWoodMetal, 2),
		];
		timePassed = 4;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]) => new List.generate(factor, (i) {
		ItemPick item = new ItemPick(items[0], items[1]);
		return new ItemStack(item, 1, item.maxDurability);
	});
}

/*
shovel
*/

class ItemShovel extends ItemDurable {
	ItemStack head;
	ItemStack handle;
	
	ItemShovel(this.head, this.handle);
	
	@override String name(ItemStack stack) {
		if ((stack.data as int) <= 0) {
			return capitalize(head.materialName) + " Shovel (broken)";
		} else {
			return capitalize(head.materialName) + " Shovel (" + ((stack.data as int)/maxDurability*100).toStringAsFixed(0)+"%)";
		}
	}
	@override double size(ItemStack stack) => head.size * 4 + handle.size * 2;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => head.color;
	@override String desc(ItemStack stack) => "This is a shovel. If you like digging holes, you'll love this tool.\nThe head is made of " + head.materialName + ". The handle is made of " + handle.materialName + ".";
	@override int value(ItemStack stack) => (head.value * 4 + handle.value * 2)*5~/4;
	
	int get maxDurability => head.hardness * 75 + handle.hardness * 25;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		super.save(stack, json);
		
		json["class"] = "ItemShovel";
		json["head"] = saveItem(head);
		json["handle"] = saveItem(handle);
	}
	@override
	void load(ItemStack stack, World world, Inventory inv, Map<String, Object> json) {
		super.load(stack, world, inv, json);
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemShovel(loadItem(world, inventory, json["head"]), loadItem(world, inventory, json["handle"])), 1, (json["durability"] as int));
	}
}

class RecipeShovel extends ItemRecipe {
	RecipeShovel() {
		name = "Shovel";
		desc = "Shovels can be used to dig up dirt faster than you can by using your bare hands. Let's face it, digging holes with your bare hands sounds unpleasent.";
		inputs = [
			new RecipeInput("of any wood, metal, stone (head)", filterAnyWoodMetalStone, 4),
			new RecipeInput("of any wood, metal (handle)", filterAnyWoodMetal, 2),
		];
		timePassed = 4;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]) => new List.generate(factor, (i) {
		ItemShovel item = new ItemShovel(items[0], items[1]);
		return new ItemStack(item, 1, item.maxDurability);
	});
}

/*
sword
*/

class ItemSword extends ItemDurable {
	ItemStack head;
	ItemStack handle;
	
	ItemSword(this.head, this.handle);
	
	@override String name(ItemStack stack) {
		if ((stack.data as int) <= 0) {
			return capitalize(head.materialName) + " Sword (broken)";
		} else {
			return capitalize(head.materialName) + " Sword (" + ((stack.data as int)/maxDurability*100).toStringAsFixed(0)+"%)";
		}
	}
	@override double size(ItemStack stack) => head.size * 4 + handle.size * 2;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => head.color;
	@override String desc(ItemStack stack) => "This is a sword, your most basic of melee weapons. It works best on the front row of enemies.\nThe head is made of " + head.materialName + ". The handle is made of " + handle.materialName + ".";
	@override int value(ItemStack stack) => (head.value * 4 + handle.value * 2)*5~/4;
	
	int get maxDurability => head.hardness * 75 + handle.hardness * 25;
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		super.save(stack, json);
		
		json["class"] = "ItemSword";
		json["head"] = saveItem(head);
		json["handle"] = saveItem(handle);
	}
	@override
	void load(ItemStack stack, World world, Inventory inv, Map<String, Object> json) {
		super.load(stack, world, inv, json);
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemSword(loadItem(world, inventory, json["head"]), loadItem(world, inventory, json["handle"])), 1, (json["durability"] as int));
	}
	
	@override
	void addBattleActions(ItemStack stack, Battle battle, List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Attack With " + name(stack), null, (c, l) {
			battle.log.clear();
			
			double hitChance = 0.9 - (0.3*battle.getRow(selBattleTarget));
			battle.doAction(world.player, battleActionHitOrMiss(world.player, selBattleTarget, name(stack), rng.nextInt(head.hardness * 4) + head.hardness * 4, hitChance, size(stack)~/2));
			stack.data = (stack.data as int) - 2;
			
			battle.doTurn();
		}));
	}
}

class RecipeSword extends ItemRecipe {
	RecipeSword() {
		name = "Sword";
		desc = "Swords are the tried-and-true tool for doing damage to enemies in the front row. The further away you go, though, the less effective it is.";
		inputs = [
			new RecipeInput("of any wood, metal, stone (head)", filterAnyWoodMetalStone, 4),
			new RecipeInput("of any wood, metal (handle)", filterAnyWoodMetal, 2),
		];
		timePassed = 4;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]) => new List.generate(factor, (i) {
		ItemSword item = new ItemSword(items[0], items[1]);
		return new ItemStack(item, 1, item.maxDurability);
	});
}

/*
=================
Load handler map
=================
*/

typedef ItemStack ItemLoadHandler(World world, Inventory inventory, Map<String, Object> json);
Map<String, ItemLoadHandler> itemLoadHandlers = {
	"ItemWood": ItemWood.loadClass,
	"ItemCobble": ItemCobble.loadClass,
	"ItemRottenFlesh": ItemRottenFlesh.loadClass,
	"ItemOre": ItemOre.loadClass,
	"ItemIngot": ItemIngot.loadClass,
	"ItemAxe": ItemAxe.loadClass,
	"ItemPick": ItemPick.loadClass,
	"ItemShovel": ItemShovel.loadClass,
	"ItemSword": ItemSword.loadClass,
	"ItemBucket": ItemBucket.loadClass,
};

/*
=================
Crafting recipes registry
=================
*/

List<ItemRecipe> handRecipes = [
	
];

List<ItemRecipe> craftingTableRecipes = [
	new RecipeAxe(),
	new RecipePick(),
	new RecipeShovel(),
	new RecipeSword(),
	new RecipeBucket(),
];

List<SmeltingRecipe> smeltingRecipes = [
	new RecipeIngot(),
];