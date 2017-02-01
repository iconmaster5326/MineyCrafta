import 'myca_core.dart';
import 'myca_console.dart';
import 'myca_gamesave.dart';
import 'myca_worldgen.dart';
import 'myca_world.dart';
import 'myca_entities.dart';

import 'myca_item_data.dart';

/*
=============
Items and Inventories
=============
*/

abstract class Item {
	String name(ItemStack stack);
	double size(ItemStack stack) => 0.0;
	bool stackable(ItemStack stack) => true;
	ConsoleColor color(ItemStack stack) => ConsoleColor.WHITE;
	String desc(ItemStack stack) => "";
	int hardness(ItemStack stack) => null;
	int value(ItemStack stack) => 0;
	String materialName(ItemStack stack) => null;
	int fuelValue(ItemStack stack) => null;
	
	bool canMerge(ItemStack stack, ItemStack other) {
		return (stack.stackable && other.stackable && stack.item == other.item);
	}
	ItemStack merge(ItemStack stack, ItemStack other) {
		stack.amt += other.amt;
		return stack;
	}
	
	void take(ItemStack stack, [int toTake = 1]) {
		stack.amt -= toTake;
		if (stack.amt <= 0 && stack.inventory != null) {
			stack.inventory.items.remove(stack);
			stack.inventory = null;
		}
	}
	void give(ItemStack stack, [int toGive = 1]) {
		stack.amt += toGive;
		if (stack.amt <= 0 && stack.inventory != null) {
			stack.inventory.items.remove(this);
			stack.inventory = null;
		}
	}
	
	void onTick(ItemStack stack, Console c, int delta) {}
	
	// ALWAYS override this. Set "class" to your class name, sop it can be loaded later.
	void save(ItemStack stack, Map<String, Object> json) {
		throw new UnimplementedError("This subclass of Item did not implement a save handler.");
	}
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		throw new UnimplementedError("This subclass of Item did not implement a load handler.");
	}
	
	Item();
	Item.raw();
	
	ItemStack clone(ItemStack stack) => new ItemStack(this, stack.amt, stack.data);
	
	/// Use this to add custom battle actions for the player.
	void addBattleActions(ItemStack stack, Battle battle, List<ConsoleLink> actions) {}
	
	bool usable(ItemStack stack) => false;
	void use(ItemStack stack, Console c) {}
	String useText(ItemStack stack) => "Use";
}

class ItemStack {
	Item item;
	int amt;
	Object data;
	
	Inventory inventory;
	
	ItemStack(this.item, [this.amt = 1, this.data]);
	
	get name {
		String nameBase = item.name(this);
		if (stackable && amt != 1) {
			nameBase += " (" + amt.toString() + ")";
		}
		return nameBase;
	}
	
	double get size => item.size(this);
	bool get stackable => item.stackable(this);
	ConsoleColor get color => item.color(this);
	String get desc => item.desc(this);
	int get hardness => item.hardness(this);
	int get value => item.value(this);
	String get materialName => item.materialName(this);
	int get fuelValue => item.fuelValue(this);
	
	bool canMerge(ItemStack other) => item.canMerge(this, other);
	ItemStack merge(ItemStack other) => item.merge(this, other);
	
	void take([int toTake = 1]) => item.take(this, toTake);
	void give([int toGive = 1]) => item.give(this, toGive);
	
	void onTick(Console c, int delta) => item.onTick(this, c, delta);
	
	void save(Map<String, Object> json) => item.save(this, json);
	void load(World world, Inventory inventory, Map<String, Object> json) => item.load(this, world, inventory, json);
	
	ItemStack clone() => item.clone(this);
	
	void addBattleActions(Battle battle, List<ConsoleLink> actions) => item.addBattleActions(this, battle, actions);
	
	bool get usable => item.usable(this);
	void use(Console c) => item.use(this, c);
	String get useText => item.useText(this);
}

class Inventory {
	List<ItemStack> items = new List<ItemStack>();
	
	double maxSize;
	
	get size {
		double sum = 0.0;
		for (ItemStack i in items) {
			sum += i.size * i.amt;
		}
		return sum;
	}
	
	Inventory([this.maxSize]);
	
	void add(ItemStack stack) {
		int i = 0;
		bool merged = false;
		for (ItemStack other in items) {
			if (other.canMerge(stack)) {
				items[i] = other.merge(stack);
				items[i].inventory = this;
				merged = true;
				break;
			}
			i++;
		}
		
		if (!merged) {
			items.add(stack);
			stack.inventory = this;
		}
	}
	
	void addAll(Iterable<ItemStack> other) {
		for (ItemStack stack in other) {
			add(stack);
		}
	}
	
	void addInventory(Inventory other) {
		for (ItemStack stack in other.items) {
			add(stack);
		}
	}
}

/*
=============
Recipes
=============
*/

class Recipe {
	String name;
	String desc;
	List<RecipeInput> inputs;
	int timePassed = 0;
	
	bool canMake(Inventory inv, [int factor = 1]) {
		Map<ItemStack, int> amountUsed = {};
		for (RecipeInput input in inputs) {
			if (input.optional) {continue;}
			
			bool inputSat = false;
			for (ItemStack stack in inv.items) {
				if (input.matches(stack, factor)) {
					int realAmt = stack.amt - (amountUsed[stack] ?? 0);
					if (input.amt*factor <= realAmt) {
						inputSat = true;
						if (input.usedUp) {
							amountUsed[stack] = (amountUsed[stack] ?? 0) + input.amt*factor;
						}
						break;
					}
				}
			}
			if (!inputSat) {
				return false;
			}
		}
		return true;
	}
}

abstract class FeatureRecipe extends Recipe {
	int space;
	Feature craft(Tile tile, List<ItemStack> items);
	bool canMakeOn(Tile tile) => true;
}

abstract class ItemRecipe extends Recipe {
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]);
}

abstract class DeconstructionRecipe extends Recipe {
	List<ItemStack> craft(List<ItemStack> items);
}

abstract class SmeltingRecipe extends Recipe {
	int fuel;
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]);
}

typedef bool RecipeInputFilter(ItemStack stack);
class RecipeInput {
	String name;
	RecipeInputFilter filter;
	int amt;
	bool usedUp;
	bool optional;
	
	RecipeInput(this.name, this.filter, this.amt, {this.usedUp: true, this.optional: false});
	
	bool matches(ItemStack stack, [int factor = 1]) {
		if (stack.amt < amt*factor) {return false;}
		return filter(stack);
	}
	
	bool matchesAny(Inventory inv, [int factor = 1]) {
		if (optional) {return true;}
		
		for (ItemStack stack in inv.items) {
			if (matches(stack, factor)) {
				return true;
			}
		}
		return false;
	}
}

/*
=============
Custom filters
=============
*/

bool filterAnyWoodMetalStone(ItemStack stack) => stack.item is ItemWood || stack.item is ItemCobble || stack.item is ItemIngot;
bool filterAnyWoodMetal(ItemStack stack) => stack.item is ItemWood || stack.item is ItemIngot;
bool filterAnyWood(ItemStack stack) => stack.item is ItemWood;
bool filterAnyStone(ItemStack stack) => stack.item is ItemCobble;
bool filterAnyWoodCuttingTool(ItemStack stack) => stack.item is ItemAxe && (stack.data as int) > 0;
bool filterAnyMiningTool(ItemStack stack) => stack.item is ItemPick && (stack.data as int) > 0;
bool filterAnyDiggingTool(ItemStack stack) => stack.item is ItemShovel && (stack.data as int) > 0;
bool filterAnyFuel(ItemStack stack) => stack.fuelValue != null;
bool filterAnyLiquidContainer(ItemStack stack) => stack.item is ItemLiquidContainer;

RecipeInputFilter filterAnyFillableLiquidContainer(Liquid liquid) {
	return (stack) => (
		stack.item is ItemLiquidContainer &&
		((stack.data as LiquidStack).liquid == null || (stack.data as LiquidStack).liquid == liquid) &&
		(stack.data as LiquidStack).amt < (stack.item as ItemLiquidContainer).maxLiquid
	);
}

RecipeInputFilter filterAnyEmptiableLiquidContainer(Liquid liquid) {
	return (stack) => (
		stack.item is ItemLiquidContainer &&
		(stack.data as LiquidStack).liquid == liquid &&
		(stack.data as LiquidStack).amt > 0
	);
}

/*
=============
Liquids
=============
*/

abstract class Liquid {
	String name(LiquidStack stack);
	ConsoleColor color(LiquidStack stack);
	double size(LiquidStack stack);
	
	void onDrink(LiquidStack stack, Console c, int toDrink);
}

class LiquidStack {
	Liquid liquid;
	int amt = 0;
	
	LiquidStack(this.liquid, [this.amt = 0]);
	LiquidStack.raw();
	
	String get name => liquid.name(this);
	ConsoleColor get color => liquid.color(this);
	double get size => liquid == null ? 0.0 : liquid.size(this);
	
	void onDrink(Console c, int toDrink) => liquid.onDrink(this, c, toDrink);
}