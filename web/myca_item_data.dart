import 'dart:math';

import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_items.dart';
import 'myca_entities.dart';
import 'myca_console.dart';
import 'myca_gamesave.dart';

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
	@override String desc(ItemStack stack) => "This is some chopped-up wood from a " + breed.name + " tree.";
	
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
			return head.item.name(head) + " Axe (broken)";
		} else {
			return head.item.name(head) + " Axe (" + ((stack.data as int)/maxDurability*100).toStringAsFixed(0)+"%)";
		}
	}
	@override double size(ItemStack stack) => head.size * 4 + handle.size * 2;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => head.color;
	@override String desc(ItemStack stack) => "This is an axe, useful for cutting down trees and demolishing carpentry.\nThe head is made of " + head.item.name(head).toLowerCase() + ". The handle is made of " + handle.item.name(handle).toLowerCase() + ".";
	
	int get maxDurability => 100;
	
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
			return head.item.name(head) + " Pick (broken)";
		} else {
			return head.item.name(head) + " Pick (" + ((stack.data as int)/maxDurability*100).toStringAsFixed(0)+"%)";
		}
	}
	@override double size(ItemStack stack) => head.size * 4 + handle.size * 2;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => head.color;
	@override String desc(ItemStack stack) => "This is a pick. It's the tool you use for getting between the earth and its valuable minerals! Not like the earth needs them anyways.\nThe head is made of " + head.item.name(head).toLowerCase() + ". The handle is made of " + handle.item.name(handle).toLowerCase() + ".";
	
	int get maxDurability => 100;
	
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
			return head.item.name(head) + " Shovel (broken)";
		} else {
			return head.item.name(head) + " Shovel (" + ((stack.data as int)/maxDurability*100).toStringAsFixed(0)+"%)";
		}
	}
	@override double size(ItemStack stack) => head.size * 4 + handle.size * 2;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => head.color;
	@override String desc(ItemStack stack) => "This is a shovel. If you like digging holes, you'll love this tool.\nThe head is made of " + head.item.name(head).toLowerCase() + ". The handle is made of " + handle.item.name(handle).toLowerCase() + ".";
	
	int get maxDurability => 100;
	
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
Load handler map
*/

typedef ItemStack ItemLoadHandler(World world, Inventory inventory, Map<String, Object> json);
Map<String, ItemLoadHandler> itemLoadHandlers = {
	"ItemWood": ItemWood.loadClass,
	"ItemAxe": ItemAxe.loadClass,
	"ItemPick": ItemPick.loadClass,
	"ItemShovel": ItemShovel.loadClass,
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
];