import 'dart:math';

import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_items.dart';
import 'myca_entities.dart';
import 'myca_console.dart';
import 'myca_ui.dart';
import 'myca_gamesave.dart';

import 'myca_item_data.dart';

/*
Trees
*/

class TreeBreed {
	String name;
	ConsoleColor trunkColor;
	ConsoleColor leavesColor;
	
	Item wood;
	
	TreeBreed(this.name, {this.trunkColor:  ConsoleColor.MAROON, this.leavesColor:  ConsoleColor.LIME}) {
		wood = new ItemWood(this);
	}
}

Map<String, TreeBreed> treeBreeds = {
	"Oak": new TreeBreed("Oak"),
	"Birch": new TreeBreed("Birch", trunkColor: ConsoleColor.SILVER),
};

class FeatureTrees extends Feature {
	TreeBreed breed;
	int numTrees;
	
	FeatureTrees(Tile tile, this.breed, this.numTrees) : super(tile);
	
	String get name => breed.name + " Trees";
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Cut Down " + name, null, (c, l) {
			ItemStack wood = new ItemStack(breed.wood, rng.nextInt(6)+1);
			world.player.inventory.add(wood);
			numTrees--;
			world.passTime(c, 10);
			
			String dialogText = "You cut down some of the trees around you. Soon, you manage to gather:\n\n" + wood.name;
			if (numTrees <= 0) {
				dialogText += "\n\nTHere are no more " + breed.name + " trees to cut down.";
				tile.features.remove(this);
			}
			
			c.onRefresh = handleNotifyDialog(dialogText, (c) {
				c.onRefresh = handleTileView;
			});
		}));
	}
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random treeRng = new Random(hashCode);
		for (int tree = 0; tree < numTrees; tree++) {
			int treeX = treeRng.nextInt(w-3) - (w-3)~/2;
			int treeY = treeRng.nextInt(h~/2);
			
			for (int i = 0; i < 4; i++) {
				int realX = x + w~/2 + treeX;
				int realY = y + h~/2 + treeY + i - 3;
				
				if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
					switch (i) {
						case 0: c.labels.add(new ConsoleLabel(realX, realY, "+-+", breed.leavesColor)); break;
						case 1: c.labels.add(new ConsoleLabel(realX, realY, "+-+", breed.leavesColor)); break;
						case 2: c.labels.add(new ConsoleLabel(realX + 1, realY, "|", breed.trunkColor)); break;
						case 3: c.labels.add(new ConsoleLabel(realX + 1, realY, "|", breed.trunkColor)); break;
					}
				}
			}
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureTrees";
		json["breed"] = breed.name;
		json["numTrees"] = numTrees;
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		this.breed = treeBreeds[json["breed"]];
		this.numTrees = json["numTrees"];
	}
	
	FeatureTrees.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureTrees.raw();
	}
}

/*
Hut
*/

class FeatureHut extends Feature {
	ItemStack material;
	
	FeatureHut(Tile tile, this.material) : super(tile) {
		material.amt = 1;
	}
	
	String get name => material.name + " Hut";
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureHut";
		json["material"] = saveItem(material);
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		this.material = loadItem(world, null, json["material"]);
	}
	
	FeatureHut.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureHut.raw();
	}
}

class RecipeHut extends FeatureRecipe {
	RecipeHut() {
		name = "Hut";
		desc = "A tiny hovel. Perfect for cowering in.";
		inputs = [
			new RecipeInput("10 of any wood, metal, stone", filterAnyWoodMetalStone, 10),
		];
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) {
		FeatureHut result = new FeatureHut(tile, items[0]);
		return result;
	}
}

/*
=================
Load handler map
=================
*/

typedef Tile TileLoadHandler(World world, Map<String, Object> json);
Map<String, TileLoadHandler> tileLoadHandlers = {
	"WorldTile": WorldTile.loadClass,
};

typedef Feature FeatureLoadHandler(World world, Tile tile, Map<String, Object> json);
Map<String, FeatureLoadHandler> featureLoadHandlers = {
	"FeatureTrees": FeatureTrees.loadClass,
	"FeatureHut": FeatureHut.loadClass,
};

/*
=================
Crafting recipes registry
=================
*/

List<FeatureRecipe> featureRecipes = [
	new RecipeHut(),
];