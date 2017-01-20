import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_items.dart';
import 'myca_entities.dart';
import 'myca_console.dart';
import 'myca_gamesave.dart';

import 'myca_features_data.dart';

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
Load handler map
*/

typedef ItemStack ItemLoadHandler(World world, Inventory inventory, Map<String, Object> json);
Map<String, ItemLoadHandler> itemLoadHandlers = {
	"ItemWood": ItemWood.loadClass,
};