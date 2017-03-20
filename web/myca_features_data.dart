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
	
	ItemWood wood;
	ItemSapling sapling;
	Item fruit;
	
	TreeBreed(this.name, {this.trunkColor:  ConsoleColor.MAROON, this.leavesColor:  ConsoleColor.LIME, this.fruit: null}) {
		wood = new ItemWood(this);
		sapling = new ItemSapling(this);
	}
}

Map<String, TreeBreed> treeBreeds = {
	"Oak": new TreeBreed("Oak", fruit: new ItemApple()),
	"Birch": new TreeBreed("Birch", trunkColor: ConsoleColor.SILVER),
};

class FeatureTrees extends Feature {
	TreeBreed breed;
	int numTrees;
	
	FeatureTrees(Tile tile, this.breed, this.numTrees) : super(tile);
	
	String get name => breed.name + " Trees";
	ConsoleColor get color => breed.leavesColor;
	String get desc => "A cluster of " + breed.name.toLowerCase() + " trees. Use an axe to chop them down for wood.";
	int get space => numTrees;
	
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
						
						if (stack.item is ItemDurable) {
							(stack.item as ItemDurable).takeDamage(stack, 10);
						}
					} else {
						dialogText = "You manage to slowly punch a tree until it falls down. Good for you!";
						treesCut = 1;
						timeSpent = 20;
					}
					
					Inventory results = new Inventory();
					
					for (int i = 0; i < treesCut; i++) {
						results.add(new ItemStack(breed.wood, rng.nextInt(7)+2));
						results.add(new ItemStack(breed.sapling, rng.nextInt(2)+1));
						if (breed.fruit != null && rng.nextDouble() < .5) {
							results.add(new ItemStack(breed.fruit, rng.nextInt(2)+1));
						}
					}
					
					dialogText += " You manage to gather:\n\n";
					for (ItemStack stack in results.items) {
						dialogText += stack.name + "\n";
					}
					
					world.player.inventory.addInventory(results);
					numTrees-=treesCut;
					world.passTime(c, timeSpent);
					
					if (numTrees <= 0) {
						dialogText += "\n\nThere are no more " + breed.name.toLowerCase() + " trees to cut down.";
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
Saplings
*/

class FeatureSaplings extends Feature {
	TreeBreed breed;
	int numTrees;
	
	FeatureSaplings(Tile tile, this.breed, this.numTrees) : super(tile);
	
	String get name => breed.name + " Saplings";
	ConsoleColor get color => breed.leavesColor;
	String get desc => "A cluster of " + breed.name.toLowerCase() + " saplings. One day they shall grow tall and strong... One day.";
	int get space => numTrees;
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random treeRng = new Random(hashCode);
		for (int tree = 0; tree < numTrees; tree++) {
			int treeX = treeRng.nextInt(w-3) - (w-3)~/2;
			int treeY = treeRng.nextInt(h~/2);
			
			for (int i = 0; i < 3; i++) {
				int realX = x + w~/2 + treeX;
				int realY = y + h~/2 + treeY + i - 3;
				
				if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
					switch (i) {
						case 0: c.labels.add(new ConsoleLabel(realX, realY, "o", breed.leavesColor)); break;
						case 1: c.labels.add(new ConsoleLabel(realX, realY, "|", breed.trunkColor)); c.labels.add(new ConsoleLabel(realX + 1, realY, "/", breed.leavesColor)); break;
						case 2: c.labels.add(new ConsoleLabel(realX, realY, "|", breed.trunkColor)); break;
					}
				}
			}
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureSaplings";
		json["breed"] = breed.name;
		json["numTrees"] = numTrees;
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		this.breed = treeBreeds[json["breed"]];
		this.numTrees = json["numTrees"];
	}
	
	FeatureSaplings.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureSaplings.raw();
	}
	
	@override
	void onTick(Console c, int delta) {
		for (int i = 0; i < delta; i++) {
			if (rng.nextDouble() < .05) {
				numTrees--;
				if (numTrees <= 0) {
					tile.features.remove(this);
				}
				
				bool planted = false;
				for (Feature f in tile.features) {
					if (f is FeatureTrees && (f as FeatureTrees).breed == breed) {
						(f as FeatureTrees).numTrees++;
						planted = true;
						break;
					}
				}
				
				if (!planted) {
					new FeatureTrees(tile, breed, 1);
				}
			}
		}
	}
}

class RecipeTrees extends FeatureRecipe {
	RecipeTrees() {
		name = "Plant Trees";
		desc = "If you actually feel environmentally friendly for a change, how about replanting some of the countless trees you've chopped down?";
		space =  4;
		inputs = [
			new RecipeInput("of any sapling", filterAnySapling, 4),
		];
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) {
		TreeBreed breed = (items[0].item as ItemSapling).breed;
		
		for (Feature f in tile.features) {
			if (f is FeatureSaplings && (f as FeatureSaplings).breed == breed) {
				(f as FeatureSaplings).numTrees += 4;
				f.space += 4;
				return null;
			}
		}
		
		return new FeatureSaplings(tile, breed, 4);
	}
	
	@override
	bool canMakeOn(Tile tile) => tile.outdoors;
}

/*
Grass
*/

class FeatureGrass extends Feature {
	FeatureGrass(Tile tile) : super(tile);
	
	String get name => "Grass";
	ConsoleColor get color => ConsoleColor.LIME;
	String get desc => "Patches of tall grass line the ground. Clearing it out might net you some seeds!";
	int get space => 1;
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random treeRng = new Random(hashCode);
		for (int tree = 0; tree < treeRng.nextInt(40)+20; tree++) {
			int treeX = treeRng.nextInt(w-3) - (w-3)~/2;
			int treeY = treeRng.nextInt(h~/2);
			
			for (int i = 0; i < 1; i++) {
				int realX = x + w~/2 + treeX;
				int realY = y + h~/2 + treeY + i;
				
				if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
					switch (i) {
						case 0: c.labels.add(new ConsoleLabel(realX, realY, ",", ConsoleColor.LIME)); break;
					}
				}
			}
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureGrass";
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		
	}
	
	FeatureGrass.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureGrass.raw();
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Dig Up Grass", null, (c, l) {
			c.onRefresh = handleSelectMaterial(c, new RecipeInput("digging tool", filterAnyDiggingTool, 1, usedUp: false, optional: false), (c, succ, stack) {
				if (succ) {
					if (stack.item is ItemDurable) {
						(stack.item as ItemDurable).takeDamage(stack, 10);
					}
					
					Inventory results = new Inventory();
					
					results.add(new ItemStack(new ItemSeeds(crops["Wheat"]), rng.nextInt(6)+1));
					
					String dialogText = "You dig up a bunch of grass. Eventually, You manage to forage:\n\n";
					for (ItemStack stack in results.items) {
						dialogText += stack.name + "\n";
					}
					
					world.player.inventory.addInventory(results);
					tile.features.remove(this);
					
					world.passTime(c, 10);
					
					c.onRefresh = handleNotifyDialog(dialogText, (c) {
						c.onRefresh = handleTileView;
					});
				} else {
					c.onRefresh = handleTileView;
				}
			});
		}));
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
		innerTile = new TileHut(this);
	}
	
	String get name => capitalize(material.materialName) + " Hut";
	ConsoleColor get color => material.color;
	String get desc => "A tiny hovel, perfect for cowering in. This is made of " + material.materialName + ".";
	int get space => 5;
	
	DeconstructionRecipe get toDeconstruct => (innerTile.features.isEmpty ? new DeconstructHut(this) : null);
	
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
			if (!world.player.status.any((s) => s is StatusEncumbered)) {
				world.player.move(innerTile);
				world.passTime(c);
			}
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

class DeconstructHut extends DeconstructionRecipe {
	FeatureHut feature;
	
	DeconstructHut(this.feature) {
		if (feature.material.item is ItemWood) {
			inputs = [
				new RecipeInput("wood-cutting tool (optional)", filterAnyWoodCuttingTool, 1, usedUp: false, optional: true),
			];
			timePassed = 20;
		} else {
			inputs = [];
		}
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items) {
		if (items[0].item is ItemDurable) {
			(items[0].item as ItemDurable).takeDamage(items[0], 10);
		}
		return [new ItemStack(feature.material.item, rng.nextInt(4)+6)];
	}
}

class TileHut extends FeatureTile {
	TileHut(FeatureHut feature) : super(feature) {
		maxFeatureSpace = 4;
	}
	
	double get baseLight => 0.0;
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
	void drawBattlePicture(Console c, int x, int y, int w, int h) {
		c.labels.add(new ConsoleLabel(x, y+1, repeatString("-", w), feature.material.color));
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
	FeatureCraftingTable(Tile tile) : super(tile);
	
	String get name => "Crafting Table";
	ConsoleColor get color => ConsoleColor.SILVER;
	String get desc => "A bench full of tools, suitable for crafting larger and more impressive things.";
	int get space => 1;
	
	DeconstructionRecipe get toDeconstruct => new DeconstructCraftingTable();
	
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

class DeconstructCraftingTable extends DeconstructionRecipe {
	DeconstructCraftingTable() {
		inputs = [
			new RecipeInput("wood-cutting tool (optional)", filterAnyWoodCuttingTool, 1, usedUp: false, optional: true),
		];
		timePassed = 2;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items) {
		if (items[0].item is ItemDurable) {
			(items[0].item as ItemDurable).takeDamage(items[0], 4);
		}
		return [];
	}
}

/*
Furnace
*/

class FeatureFurnace extends Feature {
	int fuel = 0;
	
	FeatureFurnace(Tile tile) : super(tile);
	
	String get name => "Furnace";
	ConsoleColor get color => ConsoleColor.GREY;
	String get desc => "This is a box of stone that you can throw fuel into.";
	int get space => 1;
	
	DeconstructionRecipe get toDeconstruct => new DeconstructFurnace();
	
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
						c.labels.add(new ConsoleLabel(realX, realY, "+---+", ConsoleColor.GREY));
						break;
					case 1:
						c.labels.add(new ConsoleLabel(realX, realY, "|   |", ConsoleColor.GREY));
						break;
					case 2:
						c.labels.add(new ConsoleLabel(realX, realY, "| # |", ConsoleColor.GREY));
						break;
					case 3:
						c.labels.add(new ConsoleLabel(realX, realY, "+---+", ConsoleColor.GREY));
						break;
				}
			}
		}
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Use Furnace", null, (c, l) {
			c.onRefresh = handleSmelting(c, this);
		}));
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureFurnace";
		json["fuel"] = fuel;
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		fuel = json["fuel"];
	}
	
	FeatureFurnace.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureFurnace.raw();
	}
}

class RecipeFurnace extends FeatureRecipe {
	RecipeFurnace() {
		name = "Furnace";
		desc = "A box of stone that you can throw fuel into. Once made hot, you can even cook and melt things in here!";
		space =  1;
		inputs = [
			new RecipeInput("of any stone", filterAnyStone, 8),
		];
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) => new FeatureFurnace(tile);
	
	@override
	bool canMakeOn(Tile tile) => !tile.outdoors;
}

class DeconstructFurnace extends DeconstructionRecipe {
	DeconstructFurnace() {
		inputs = [
			new RecipeInput("mining tool", filterAnyMiningTool, 1, usedUp: false, optional: false),
		];
		timePassed = 2;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items) {
		if (items[0].item is ItemDurable) {
			(items[0].item as ItemDurable).takeDamage(items[0], 4);
		}
		return [];
	}
}

/*
Mineshaft
*/

class FeatureMineshaft extends Feature {
	TileMineshaft innerTile;
	
	FeatureMineshaft(Tile tile) : super(tile) {
		innerTile = new TileMineshaft(this);
	}
	
	String get name => "Mineshaft";
	ConsoleColor get color => ConsoleColor.GREY;
	String get desc => (tile is TileMineshaft ? "This is a shaft leading deeper underground." : "This is a hole, leading to somewhere underground.");
	int get space => tile is TileMineshaft ? 5 : 10;
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random rng = new Random(hashCode);
		
		if (tile is TileMineshaft) {
			int ladderX = x + rng.nextInt(w-5)+2;
			
			for (int i = y + h - 2; i < y + h; i++) {
				c.labels.add(new ConsoleLabel(ladderX, i, "|-|", ConsoleColor.MAROON));
			}
		} else {
			int drawX = rng.nextInt(w-6) - (w-6)~/2;
			int drawY = rng.nextInt(h~/2);
			
			for (int i = 0; i < 4; i++) {
				int realX = x + w~/2 + drawX;
				int realY = y + h~/2 + drawY + i;
				
				if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
					switch (i) {
						case 0:
							c.labels.add(new ConsoleLabel(realX, realY, "+", ConsoleColor.GREY));
							c.labels.add(new ConsoleLabel(realX+1, realY, "|-|", ConsoleColor.MAROON));
							c.labels.add(new ConsoleLabel(realX+4, realY, "+", ConsoleColor.GREY));
							break;
						case 1:
							c.labels.add(new ConsoleLabel(realX, realY, "|", ConsoleColor.GREY));
							c.labels.add(new ConsoleLabel(realX+1, realY, "|-|", ConsoleColor.MAROON));
							c.labels.add(new ConsoleLabel(realX+4, realY, "|", ConsoleColor.GREY));
							break;
						case 2:
							c.labels.add(new ConsoleLabel(realX, realY, "+---+", ConsoleColor.GREY));
							break;
					}
				}
			}
		}
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		if (tile is! TileMineshaft) {
			actions.add(new ConsoleLink(0, 0, "Enter Mineshaft", null, (c, l) {
				if (!world.player.status.any((s) => s is StatusEncumbered)) {
					world.player.move(innerTile);
					world.passTime(c);
				}
			}));
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureMineshaft";
		json["innerTile"] = saveTile(innerTile);
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		innerTile = loadTile(world, json["innerTile"]); innerTile.feature = this;
	}
	
	FeatureMineshaft.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureMineshaft.raw();
	}
}

class RecipeMineshaft extends FeatureRecipe {
	RecipeMineshaft() {
		name = "Mineshaft";
		desc = "Dig down, so you can dig up precious materials. Like cobblestone!";
		space =  10;
		inputs = [
			new RecipeInput("mining tool", filterAnyMiningTool, 1, usedUp: false, optional: false),
			new RecipeInput("digging tool (optional)", filterAnyDiggingTool, 1, usedUp: false, optional: true),
		];
		timePassed = 20;
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) {
		if (items[0].item is ItemDurable) {
			(items[0].item as ItemDurable).takeDamage(items[0], 10);
		}
		if (items.length > 1 && items[1] != null) {
			if (items[1].item is ItemDurable) {
				(items[1].item as ItemDurable).takeDamage(items[1], 5);
			}
		} else {
			timePassed += 10;
		}
		
		return new FeatureMineshaft(tile);
	}
	
	@override
	bool canMakeOn(Tile tile) => tile.outdoors;
}

class RecipeMineshaft2 extends RecipeMineshaft {
	RecipeMineshaft2() : super() {
		desc = "Dig deeper, greedier, ever downwards... More valuable materials lie below. Like MORE cobblestone!";
		space = 5;
	}
	
	@override
	bool canMakeOn(Tile tile) {
		// can only make in a mineshaft that has no mineshaft yet.
		if (tile is! TileMineshaft) {
			return false;
		}
		for (Feature f in tile.features) {
			if (f is FeatureMineshaft) {
				return false;
			}
		}
		return true;
	}
}

class TileMineshaft extends FeatureTile {
	TileMineshaft(FeatureMineshaft feature) : super(feature) {
		maxFeatureSpace = 10;
	}
	
	double get baseLight => 0.0;
	Tile get customUp => feature.tile;
	Tile get customDown {
		for (Feature f in features) {
			if (f is FeatureMineshaft) {
				return (f as FeatureMineshaft).innerTile;
			}
		}
		return null;
	}
	
	bool get outdoors => false;
	bool get underground => true;
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		c.labels.add(new ConsoleLabel(x, y+h~/2, repeatString("-", w), ConsoleColor.GREY));
		
		Random rng = new Random(hashCode);
		
		int numStones = rng.nextInt(w*h~/16)+w*h~/16;
		List<String> stoneIcons = [".", "o", ","];
		for (int i = y; i < numStones; i++) {
			c.labels.add(new ConsoleLabel(x+rng.nextInt(w), y+h~/2+1+rng.nextInt(h~/2), stoneIcons[rng.nextInt(stoneIcons.length)], ConsoleColor.GREY));
		}
		
		int ladderX = x + rng.nextInt(w-5)+2;
		
		for (int i = y; i <= y + h~/2; i++) {
			c.labels.add(new ConsoleLabel(ladderX, i, "|-|", ConsoleColor.MAROON));
		}
		
		for (Feature f in features) {
			f.drawPicture(c, x, y, w, h);
		}
		
		c.labels.add(new ConsoleLabel(x + w~/2, y + h*3~/4, "@"));
	}
	
	@override
	void drawBattlePicture(Console c, int x, int y, int w, int h) {
		Random rng = new Random(hashCode);
		
		int numStones = rng.nextInt(w*h~/16)+w*h~/16;
		List<String> stoneIcons = [".", "o", ","];
		for (int i = y; i < numStones; i++) {
			c.labels.add(new ConsoleLabel(x+rng.nextInt(w), y+rng.nextInt(h), stoneIcons[rng.nextInt(stoneIcons.length)], ConsoleColor.GREY));
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "TileMineshaft";
	}
	@override
	void load(World world, Map<String, Object> json) {
		
	}
	
	TileMineshaft.raw() : super.raw();
	static Tile loadClass(World world, Map<String, Object> json) {
		return new TileMineshaft.raw();
	}
	
	int get depth {
		int i = 0;
		Tile t = feature.tile;
		
		while (t is TileMineshaft) {
			t = (t as TileMineshaft).feature.tile;
			i++;
		}
		
		return i;
	}
}

/*
Tunnel
*/

class MiningLoot {
	Item item;
	double chance;
	int min; int max;
	
	MiningLoot(this.item, this.chance, this.min, this.max);
	
	ItemStack get stack => new ItemStack(item, rng.nextInt(max-min+1)+min);
}

List<List<MiningLoot>> miningLoot = [
	// depth 0
	[
		new MiningLoot(new ItemOre(metalTypes["Iron"]), 0.6, 1, 4),
	],
	// depth 1
	[
		new MiningLoot(new ItemOre(metalTypes["Iron"]), 0.5, 1, 4),
		new MiningLoot(new ItemOre(metalTypes["Gold"]), 0.2, 1, 4),
	],
	// depth 2
	[
		new MiningLoot(new ItemOre(metalTypes["Gold"]), 0.4, 1, 4),
	],
];

class FeatureTunnel extends Feature {
	FeatureTunnel(Tile tile) : super(tile);
	int amtLeft = rng.nextInt(100)+100;
	
	String get name => "Tunnel";
	ConsoleColor get color => ConsoleColor.GREY;
	String get desc => "This is an underground tunnel, made for mining purposes. Who knows where it could lead?" + (amtLeft <= 0 ? "\nThis tunnel has been mined dry of resources, it seems." : "");
	int get space => 4;
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		// only display 1 tunnel at a time
		for (Feature f in tile.features) {
			if (f == this) {
				break;
			}
			if (f is FeatureTunnel) {
				return;
			}
		}
		
		Random rng = new Random(hashCode);
		int drawX = rng.nextInt(w-6);
		
		c.labels.add(new ConsoleLabel(x+drawX, y+h~/2-4, "+---+", ConsoleColor.GREY));
		c.labels.add(new ConsoleLabel(x+drawX, y+h~/2-3, "|...|", ConsoleColor.GREY));
		c.labels.add(new ConsoleLabel(x+drawX, y+h~/2-2, "|...|", ConsoleColor.GREY));
		c.labels.add(new ConsoleLabel(x+drawX, y+h~/2-1, "|...|", ConsoleColor.GREY));
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Mine In Tunnel", null, (c, l) {
			SelectMaterialCallback onMine;
			onMine = (c, succ, stack) {
				if (!succ) {
					c.onRefresh = handleTileView;
					return;
				}
				
				if (stack.item is ItemDurable) {
					(stack.item as ItemDurable).takeDamage(stack, 10);
				}
				
				Inventory results = new Inventory();
				results.add(new ItemStack(new ItemCobble(), rng.nextInt(4)+6));
				if (amtLeft > 0) {
					int depth = (tile as TileMineshaft).depth;
					if (depth >= miningLoot.length) {
						depth = miningLoot.length - 1;
					}
					
					for (MiningLoot loot in miningLoot[depth]) {
						if (rng.nextDouble() < loot.chance) {
							results.add(loot.stack);
						}
					}
				}
				
				world.player.inventory.addInventory(results);
				world.passTime(c, 10);
				
				String dialogText = "You extend the tunnel, collecting resources along the way. You mined out:\n\n";
				
				for (ItemStack item in results.items) {
					dialogText += "* " + item.name + "\n";
				}
				
				amtLeft--;
				if (amtLeft <= 0) {
					dialogText += "\nThe tunnel has run dry of resources, it seems.\n";
				}
				
				if (stack.item is ItemDurable && (stack.data as int) <= 0) {
					dialogText += "\nYour tool is now broken.";
					c.onRefresh = handleNotifyDialog(dialogText, (c) {
						c.onRefresh = handleTileView;
					});
				} else {
					dialogText += "\nWill you continue to mine in this tunnel?";
					
					c.onRefresh = handleYesNoDialog(dialogText, (c, choice) {
						if (choice) {
							onMine(c, true, stack);
						} else {
							c.onRefresh = handleTileView;
						}
					});
				}
			};
			
			c.onRefresh = handleSelectMaterial(c, new RecipeInput("mining tool", filterAnyMiningTool, 1, usedUp: false, optional: false), onMine);
		}));
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureTunnel";
		json["amtLeft"] = amtLeft;
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		amtLeft = json["amtLeft"];
	}
	
	FeatureTunnel.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureTunnel.raw();
	}
}

class RecipeTunnel extends FeatureRecipe {
	RecipeTunnel() {
		name = "Tunnel";
		desc = "You can dig tunnels underground to search for resources. Once made, a tunnel can be extended until you've mined it dry.";
		space =  4;
		inputs = [
			new RecipeInput("mining tool", filterAnyMiningTool, 1, usedUp: false, optional: false),
		];
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) {
		if (items[0].item is ItemDurable) {
			(items[0].item as ItemDurable).takeDamage(items[0], 5);
		}
		
		return new FeatureTunnel(tile);
	}
	
	@override
	bool canMakeOn(Tile tile) => tile is TileMineshaft;
}

/*
Torches
*/

class FeatureTorches extends Feature {
	FeatureTorches(Tile tile) : super(tile);
	
	String get name => "Torches";
	ConsoleColor get color => ConsoleColor.RED;
	String get desc => "A bunch of torches, placed to make sure there is absolutely no darkness for evil to breed in.";
	double get lightProvided => 0.5;
	int get space => 1;
	
	DeconstructionRecipe get toDeconstruct => new DeconstructTorches();
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random rng = new Random(hashCode);
		int numTorches = rng.nextInt(8)+4;
		for (int torch = 0; torch < numTorches; torch++) {
			int torchX = rng.nextInt(w-1) - (w-1)~/2;
			int torchY = rng.nextInt(h~/2);
			
			for (int i = 0; i < 2; i++) {
				int realX = x + w~/2 + torchX;
				int realY = y + h~/2 + torchY + i - 1;
				
				if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
					switch (i) {
						case 0: c.labels.add(new ConsoleLabel(realX, realY, "*", ConsoleColor.YELLOW)); break;
						case 1: c.labels.add(new ConsoleLabel(realX, realY, "|", ConsoleColor.MAROON)); break;
					}
				}
			}
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureTorches";
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		
	}
	
	FeatureTorches.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureTorches.raw();
	}
}

class RecipeTorches extends FeatureRecipe {
	RecipeTorches() {
		name = "Torches";
		desc = "Place down some torches to keep evil at bay! Also, place them so you can see what you're doing indoors.";
		space =  1;
		inputs = [
			new RecipeInput("of any wood", filterAnyWood, 2),
			new RecipeInput("of any fuel", filterAnyFuel, 1),
		];
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) => new FeatureTorches(tile);
}

class DeconstructTorches extends DeconstructionRecipe {
	DeconstructTorches() {
		inputs = [
			
		];
		timePassed = 2;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items) {
		return [];
	}
}

/*
Lake
*/

class FeatureLake extends Feature {
	FeatureLake(Tile tile) : super(tile);
	
	String get name => "Lake";
	ConsoleColor get color => ConsoleColor.BLUE;
	String get desc => "A rippling pool of water. That's a spot of water in the thing, ayup. What a lake.";
	int get space => 5;
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random rng = new Random(hashCode);
		int drawX = rng.nextInt(w-6) - (w-6)~/2;
		int drawY = rng.nextInt(h~/2);
		
		for (int i = 0; i < 4; i++) {
			int realX = x + w~/2 + drawX;
			int realY = y + h~/2 + drawY + i - 1;
			
			if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
				switch (i) {
					case 0:
						c.labels.add(new ConsoleLabel(realX, realY, "------", ConsoleColor.BLUE));
						break;
					case 1:
						c.labels.add(new ConsoleLabel(realX, realY, "-.....-", ConsoleColor.BLUE));
						break;
					case 2:
						c.labels.add(new ConsoleLabel(realX, realY, "-......-", ConsoleColor.BLUE));
						break;
					case 3:
						c.labels.add(new ConsoleLabel(realX+1, realY, "------", ConsoleColor.BLUE));
						break;
				}
			}
		}
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Scoop Up Water", null, (c, l) {
			c.onRefresh = handleSelectMaterial(c, new RecipeInput("liquid container", filterAnyFillableLiquidContainer(new LiquidWater()), 1, usedUp: false, optional: false), (c, succ, stack) {
				if (succ) {
					LiquidStack water = new LiquidStack(new LiquidWater(), 250);
					(stack.item as ItemLiquidContainer).giveLiquid(stack, water);
					world.passTime(c, 2);
					
					String dialogText = "You manage to scoop up "+(250-water.amt).toString()+" millibuckets of water into your "+stack.name.toLowerCase()+".";
					
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
	void save(Map<String, Object> json) {
		json["class"] = "FeatureLake";
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		
	}
	
	FeatureLake.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureLake.raw();
	}
}

/*
Farm
*/

class FeatureFarm extends Feature {
	FeatureFarm(Tile tile) : super(tile);
	
	Crop crop;
	int growthStage;
	
	String get name => "Farm";
	ConsoleColor get color => ConsoleColor.MAROON;
	String get desc => "This is a plot of fertile land, drawn out into rows. " + (crop == null ? "Currently, the fields lay bare." : "A patch of " + crop.name.toLowerCase() + " is currently growing in it.");
	int get space => 6;
	
	DeconstructionRecipe get toDeconstruct => new DeconstructFarm();
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		if (w <= 1 || h <= 1) {return;}
		
		Random rng = new Random(hashCode);
		
		int torchX = rng.nextInt(w-1) - (w-1)~/2;
		int torchY = rng.nextInt(h~/2);
		
		for (int i = 0; i < 6; i++) {
			int realX = x + w~/2 + torchX;
			int realY = y + h~/2 + torchY + i - 1;
			
			if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
				if (crop == null || i%2 == 0) {
					c.labels.add(new ConsoleLabel(realX, realY, repeatString(crop.icons[growthStage], 8), crop.iconColors[growthStage]));
				} else {
					c.labels.add(new ConsoleLabel(realX, realY, "________", ConsoleColor.MAROON));
				}
			}
		}
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "FeatureFarm";
		json["crop"] = crop?.name;
		json["growthStage"] = growthStage;
	}
	@override
	void load(World world, Tile tile, Map<String, Object> json) {
		if (json["crop"] != null) {
			crop = crops[json["crop"]];
		}
		growthStage = json["growthStage"];
	}
	
	FeatureFarm.raw() : super.raw();
	static Feature loadClass(World world, Tile tile, Map<String, Object> json) {
		return new FeatureFarm.raw();
	}
	
	@override
	void onTick(Console c, int delta) {
		if (tile.light >= .5 && crop != null && growthStage != crop.growthStages-1 && rng.nextDouble() < crop.growChancePerTick) {
			growthStage++;
		}
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		if (crop == null) {
			actions.add(new ConsoleLink(0, 0, "Sow Seeds", null, (c, l) {
				c.onRefresh = handleSelectMaterial(c, new RecipeInput("seeds", (ItemStack stack) => stack.item is ItemSeeds, 8, usedUp: true, optional: false), (c, succ, stack) {
					if (succ) {
						stack.take(8);
						crop = (stack.item as ItemSeeds).crop;
						growthStage = 0;
					}
					c.onRefresh = handleTileView;
				});
			}));
		}
		
		if (crop != null && growthStage == crop.growthStages-1) {
			actions.add(new ConsoleLink(0, 0, "Harvest " + crop.name, null, (c, l) {
				Inventory results = new Inventory();
				
				results.add(new ItemStack(crop.product, rng.nextInt(crop.maxPerHarvest-crop.minPerHarvest)+crop.minPerHarvest));
				results.add(new ItemStack(new ItemSeeds(crop), rng.nextInt(1)+1));
				
				String dialogText = "You reap the rewards of your harvest. They include:\n\n";
				for (ItemStack stack in results.items) {
					dialogText += stack.name + "\n";
				}
				
				growthStage = 0;
				world.player.inventory.addInventory(results);
				world.passTime(c, 20);
				
				c.onRefresh = handleNotifyDialog(dialogText, (c) {
					c.onRefresh = handleTileView;
				});
			}));
		}
	}
}

class RecipeFarm extends FeatureRecipe {
	RecipeFarm() {
		name = "Farm";
		desc = "Farming is the tried-and-true method of not starving. Just plant seeds, wait, and reap the benefits!";
		space =  6;
		inputs = [
			new RecipeInput("hoe", (ItemStack stack) => stack.item is ItemHoe, 1, usedUp: false),
			new RecipeInput("bucket of water", filterAnyEmptiableLiquidContainer(new LiquidWater(), 1000), 1, usedUp: false),
		];
	}
	
	@override
	Feature craft(Tile tile, List<ItemStack> items) {
		if (items[0].item is ItemDurable) {
			(items[0].item as ItemDurable).takeDamage(items[0], 10);
		}
		if (items[1].item is ItemLiquidContainer) {
			(items[1].item as ItemLiquidContainer).takeLiquid(items[1], 1000);
		}
		return new FeatureFarm(tile);
	}
	
	@override
	bool canMakeOn(Tile tile) => tile.outdoors;
}

class DeconstructFarm extends DeconstructionRecipe {
	DeconstructFarm() {
		inputs = [
			
		];
		timePassed = 2;
	}
	
	@override
	List<ItemStack> craft(List<ItemStack> items) {
		return [];
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
	"TileHut": TileHut.loadClass,
	"TileMineshaft": TileMineshaft.loadClass,
};

typedef Feature FeatureLoadHandler(World world, Tile tile, Map<String, Object> json);
Map<String, FeatureLoadHandler> featureLoadHandlers = {
	"FeatureTrees": FeatureTrees.loadClass,
	"FeatureSaplings": FeatureSaplings.loadClass,
	"FeatureGrass": FeatureGrass.loadClass,
	"FeatureHut": FeatureHut.loadClass,
	"FeatureCraftingTable": FeatureCraftingTable.loadClass,
	"FeatureFurnace": FeatureFurnace.loadClass,
	"FeatureMineshaft": FeatureMineshaft.loadClass,
	"FeatureTunnel": FeatureTunnel.loadClass,
	"FeatureTorches": FeatureTorches.loadClass,
	"FeatureLake": FeatureLake.loadClass,
	"FeatureFarm": FeatureFarm.loadClass,
};

/*
=================
Crafting recipes registry
=================
*/

List<FeatureRecipe> featureRecipes = [
	new RecipeHut(),
	new RecipeCraftingTable(),
	new RecipeFurnace(),
	new RecipeMineshaft(),
	new RecipeMineshaft2(),
	new RecipeTunnel(),
	new RecipeTorches(),
	new RecipeTrees(),
	new RecipeFarm(),
];