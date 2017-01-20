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
axe
*/

class ItemAxe extends Item {
	ItemStack head;
	ItemStack handle;
	
	ItemAxe(this.head, this.handle);
	
	@override String name(ItemStack stack) => head.item.name(head) + " Axe";
	@override double size(ItemStack stack) => head.size * 4 + handle.size * 2;
	@override bool stackable(ItemStack stack) => false;
	@override ConsoleColor color(ItemStack stack) => head.color;
	@override String desc(ItemStack stack) => "This is an axe, useful for cutting down trees. The head is made of " + head.item.name(head).toLowerCase() + ". The handle is made of " + handle.item.name(handle).toLowerCase() + ".";
	
	@override
	void save(ItemStack stack, Map<String, Object> json) {
		json["class"] = "ItemAxe";
		json["head"] = saveItem(head);
		json["handle"] = saveItem(handle);
	}
	@override
	void load(ItemStack stack, World world, Inventory inventory, Map<String, Object> json) {
		
	}
	
	static ItemStack loadClass(World world, Inventory inventory, Map<String, Object> json) {
		return new ItemStack(new ItemAxe(loadItem(world, inventory, json["head"]), loadItem(world, inventory, json["handle"])));
	}
}

class RecipeAxe extends ItemRecipe {
	RecipeAxe() {
		name = "Axe";
		desc = "Axes are useful for chopping down trees. Much more efficent than just punching trees like a madman.";
		inputs = [
			new RecipeInput("of any wood, metal, stone (head)", filterAnyWoodMetalStone, 4),
			new RecipeInput("of any wood, metal (head)", filterAnyWoodMetal, 2),
		];
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items, [int factor = 1]) => new List.generate(factor, (i) =>
		new ItemStack(new ItemAxe(items[0], items[1]))
	);
}

/*
Load handler map
*/

typedef ItemStack ItemLoadHandler(World world, Inventory inventory, Map<String, Object> json);
Map<String, ItemLoadHandler> itemLoadHandlers = {
	"ItemWood": ItemWood.loadClass,
	"ItemAxe": ItemAxe.loadClass,
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
];