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
	
	FeatureTrees(Tile tile, this.breed, this.numTrees) : super(tile) {
		space = numTrees;
	}
	
	String get name => breed.name + " Trees";
	ConsoleColor get color => breed.leavesColor;
	String get desc => "A cluster of " + breed.name.toLowerCase() + " trees. Use an axe to chop them down for wood.";
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Cut Down " + name, null, (c, l) {
			c.onRefresh = handleSelectMaterial(c, new RecipeInput("wood-cutting tool (optional)", filterAnyWoodCuttingTool, 1, usedUp: false, optional: true), (c, succ, stack) {
				if (succ) {
					String dialogText;
					int treesCut;
					int timeSpent;
					
					if (stack != null) {
						dialogText = "You cut down some of the trees around you.";
						treesCut = min(numTrees, rng.nextInt(3)+2);
						timeSpent = 10;
					} else {
						dialogText = "You manage to slowly punch a tree until it falls down. Good for you!";
						treesCut = 1;
						timeSpent = 20;
					}
					
					int woodMade = 0;
					for (int i = 0; i < treesCut; i++) {
						woodMade += rng.nextInt(7)+2;
					}
					
					ItemStack wood = new ItemStack(breed.wood, woodMade);
					world.player.inventory.add(wood);
					numTrees-=treesCut; space-=treesCut;
					world.passTime(c, timeSpent);
					
					dialogText += " You manage to gather:\n\n" + wood.name;
					
					if (numTrees <= 0) {
						dialogText += "\n\nTHere are no more " + breed.name + " trees to cut down.";
						tile.features.remove(this);
					}
					
					c.onRefresh = handleNotifyDialog(dialogText, (c) {
						c.onRefresh = handleTileView;
					});
				} else {
					c.onRefresh = handleTileView;
				}
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
	TileHut innerTile;
	
	FeatureHut(Tile tile, this.material) : super(tile) {
		material = material.clone();
		space =  5;
		
		innerTile = new TileHut(this);
	}
	
	String get name => material.item.name(material) + " Hut";
	ConsoleColor get color => material.color;
	String get desc => "A tiny hovel, perfect for cowering in. This is made of " + material.item.name(material).toLowerCase() + ".";
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random rng = new Random(hashCode);
		int drawX = rng.nextInt(w-6) - (w-6)~/2;
		int drawY = rng.nextInt(h~/2);
		
		for (int i = 0; i < 4; i++) {
			int realX = x + w~/2 + drawX;
			int realY = y + h~/2 + drawY + i - 4;
			
			if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
				switch (i) {
					case 0: c.labels.add(new ConsoleLabel(realX, realY, "+---+", material.color)); break;
					case 1: c.labels.add(new ConsoleLabel(realX, realY, "|   |", material.color)); break;
					case 2: c.labels.add(new ConsoleLabel(realX, realY, "|   |", material.color)); break;
					case 3: c.labels.add(new ConsoleLabel(realX, realY, "| # |", material.color)); break;
				}
			}
		}
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Enter " + name, null, (c, l) {
			world.player.move(innerTile);
		}));
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureHut";
		json["material"] = saveItem(material);
		json["innerTile"] = saveTile(innerTile);
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		material = loadItem(world, null, json["material"]);
		innerTile = loadTile(world, json["innerTile"]); innerTile.feature = this;
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
		space =  5;
		inputs = [
			new RecipeInput("of any wood, metal, stone", filterAnyWoodMetalStone, 10),
		];
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) => new FeatureHut(tile, items[0]);
	
	@override
	bool canMakeOn(Tile tile) => tile.outdoors;
}

class TileHut extends FeatureTile {
	TileHut(FeatureHut feature) : super(feature) {
		maxFeatureSpace = 4;
	}
	
	double get light => 0.0;
	Tile get customUp => feature.tile;
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		c.labels.add(new ConsoleLabel(x, y+h~/2, repeatString("-", 3*w~/4), feature.material.color));
		for (int i = 0; i < h~/2; i++) {
			c.labels.add(new ConsoleLabel(x+3*w~/4, y+i, "|", feature.material.color));
		}
		
		int xx = 3*w~/4;
		int yy = h~/2;
		while (xx < w && yy < h) {
			c.labels.add(new ConsoleLabel(x+xx, y+yy, "\\", feature.material.color));
			
			xx++; yy++;
		}
		
		c.labels.add(new ConsoleLabel(x+7*w~/16, y+h~/4, "+"+repeatString("-", w~/8)+"+", feature.material.color));
		for (int i = h~/4 + 1; i < h~/2; i++) {
			c.labels.add(new ConsoleLabel(x+7*w~/16, y+i, "|", feature.material.color));
			c.labels.add(new ConsoleLabel(x+7*w~/16+1, y+i, repeatString(".", w~/8), biome.groundColor));
			c.labels.add(new ConsoleLabel(x+7*w~/16+w~/8+1, y+i, "|", feature.material.color));
		}
		
		for (Feature f in features) {
			f.drawPicture(c, x, y+h~/8, 3*w~/4, 7*h~/8);
		}
		
		c.labels.add(new ConsoleLabel(x + w~/2, y + h*3~/4, "@"));
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "TileHut";
	}
	@override
	void load(World world, Map<String, Object> json) {
		
	}
	
	TileHut.raw() : super.raw();
	static Tile loadClass(World world, Map<String, Object> json) {
		return new TileHut.raw();
	}
}

/*
Crafting Table
*/

class FeatureCraftingTable extends Feature {
	FeatureCraftingTable(Tile tile) : super(tile) {
		space =  1;
	}
	
	String get name => "Crafting Table";
	ConsoleColor get color => ConsoleColor.SILVER;
	String get desc => "A bench full of tools, suitable for crafting larger and more impressive things.";
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random rng = new Random(hashCode);
		int drawX = rng.nextInt(w-6) - (w-6)~/2;
		int drawY = rng.nextInt(h~/2);
		
		for (int i = 0; i < 4; i++) {
			int realX = x + w~/2 + drawX;
			int realY = y + h~/2 + drawY + i - 4;
			
			if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
				switch (i) {
					case 0:
						c.labels.add(new ConsoleLabel(realX, realY, "+---+", ConsoleColor.MAROON));
						break;
					case 1:
						c.labels.add(new ConsoleLabel(realX, realY, "| | |", ConsoleColor.MAROON));
						c.labels.add(new ConsoleLabel(realX+3, realY, "X", ConsoleColor.SILVER));
						break;
					case 2:
						c.labels.add(new ConsoleLabel(realX, realY, "| | |", ConsoleColor.MAROON));
						c.labels.add(new ConsoleLabel(realX+1, realY, ">", ConsoleColor.SILVER));
						break;
					case 3:
						c.labels.add(new ConsoleLabel(realX, realY, "+---+", ConsoleColor.MAROON));
						break;
				}
			}
		}
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Use Crafting Table", null, (c, l) {
			c.onRefresh = handleCraftItem(c, craftingTableRecipes);
		}));
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureCraftingTable";
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		
	}
	
	FeatureCraftingTable.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureCraftingTable.raw();
	}
}

class RecipeCraftingTable extends FeatureRecipe {
	RecipeCraftingTable() {
		name = "Crafting Table";
		desc = "A bench full of tools, suitable for crafting larger and more impressive things.";
		space =  1;
		inputs = [
			new RecipeInput("of any wood", filterAnyWood, 4),
		];
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) => new FeatureCraftingTable(tile);
	
	@override
	bool canMakeOn(Tile tile) => !tile.outdoors;
}

/*
=================
Load handler map
=================
*/

typedef Tile TileLoadHandler(World world, Map<String, Object> json);
Map<String, TileLoadHandler> tileLoadHandlers = {
	"WorldTile": WorldTile.loadClass,
	"TileHut": TileHut.loadClass,
};

typedef Feature FeatureLoadHandler(World world, Tile tile, Map<String, Object> json);
Map<String, FeatureLoadHandler> featureLoadHandlers = {
	"FeatureTrees": FeatureTrees.loadClass,
	"FeatureHut": FeatureHut.loadClass,
	"FeatureCraftingTable": FeatureCraftingTable.loadClass,
};

/*
=================
Crafting recipes registry
=================
*/

List<FeatureRecipe> featureRecipes = [
	new RecipeHut(),
	new RecipeCraftingTable(),
];