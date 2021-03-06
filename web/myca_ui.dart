import 'dart:math';

import 'myca_core.dart';
import 'myca_console.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_entities.dart';
import 'myca_items.dart';
import 'myca_gamesave.dart';

import 'myca_features_data.dart';
import 'myca_item_data.dart';

World world;

void handleTitleScreen(Console c) {
	const String intro = "Iconmaster presents...";
	const String logo = r"""
      __  __ ___ _   _ _______   __     
     |  \/  |_ _| \ | | ____\ \ / /     
     | |\/| || ||  \| |  _|  \ V /      
     | |  | || || |\  | |___  | |       
   __|_|__|_|___|_| \_|_____|_|_|  _    
  / ___|  _ \   / \  |  ___|_   _|/ \   
 | |   | |_) | / _ \ | |_    | | / _ \  
 | |___|  _ < / ___ \|  _|   | |/ ___ \ 
  \____|_| \_/_/   \_|_|     |_/_/   \_\ """;
	const String newGame = "1) New Game";
	const String loadGame = "2) Load Saved Game";
	
	c.labels.add(new ConsoleLabel(c.centerJustified(intro), 1, intro));
	c.labels.addAll(new ConsoleLabel(c.width~/2 - 20, 3, logo).as2DLabel());
	
	c.labels.add(new ConsoleLink(c.centerJustified(newGame), 16, newGame, "1", (c, l) {
		c.onRefresh = handleNewGame;
	}));
	if (getSavedWorlds().isEmpty) {
		c.labels.add(new ConsoleLabel(c.centerJustified(loadGame), 17, loadGame, ConsoleColor.SILVER));
	} else {
		c.labels.add(new ConsoleLink(c.centerJustified(loadGame), 17, loadGame, "2", (c, l) {
			c.onRefresh = handleLoadGame(c, handleTitleScreen);
		}));
	}
}

/// Random names, created by user submissions. So no, any references in here aren't intentional.
final List<String> randomNames = [
	"Bumpus",
	"Jethro",
	"Scrungus",
	"Zoosmell",
	"Slagathor",
	"Elbereth",
	"Mahoney",
	"Shoyler",
	"McDungeons",
	"Balloon",
	"Rossdelly",
	"Andropov",
	"Urazmus",
	"Purple",
	"Jordad",
	"Pinhead",
	"Dudemeister",
	"Hugh",
	"Moist",
	"Schmoicle",
	"Eero",
	"Schmitz",
	"Mickey",
	"Guybrush",
	"Jake",
	"Dewey",
	"Maxime",
	"Benny",
	"Jaunty",
];

void handleNewGame(Console c) {
	List<ConsoleLabel> intro = new ConsoleLabel(0, 1, fitToWidth("You, a simple at sign, have woken up in a mysterious land. This, of course, is the world of MINEYCRAFTA. Will you rise to the challenge and claim the world as yours, or will you die hungry and alone? Let us begin your new journey with haste!\n\nBut first...\nWhat is your name?", c.width-2)).as2DLabel();
	for (ConsoleLabel label in intro) {
		label.x = c.centerJustified(label.text);
	}
	c.labels.addAll(intro);
	
	c.labels.add(new ConsoleLabel(c.width~/2, c.height-4, "@"));
	
	c.labels.add(new ConsoleTextBox(c.width~/4, c.height-2, "", c.width~/2, (c, l, text) {
		Player player = new Player(text);
		
		world = new World(player);
		c.onRefresh = handleTileView;
	}));
}

ConsoleRefreshHandler tileViewOverride;
void handleTileView(Console c) {
	// The override is used for things like getting into encounters and dying.
	if (tileViewOverride != null) {
		c.onRefresh = tileViewOverride;
		tileViewOverride = null;
		c.refresh();
		return;
	}
	
	// gather possible actions for the action bar
	List<ConsoleLink> actions = new List<ConsoleLink>();
	
	actions.add(new ConsoleLink(0, 0, "Inventory", null, (c, l) {
		c.onRefresh = handleInventoryView;
	}));
	actions.add(new ConsoleLink(0, 0, "Look Around", null, (c, l) {
		c.onRefresh = handleInspectView;
	}));
	//actions.add(new ConsoleLink(0, 0, "Craft Item", null, (c, l) {
	//	c.onRefresh = handleCraftItem(c, handRecipes);
	//}));
	actions.add(new ConsoleLink(0, 0, "Craft Structure", null, (c, l) {
		c.onRefresh = handleCraftFeature;
	}));
	
	world.player.tile.addActions(actions);
	for (Feature f in world.player.tile.features) {
		f.addActions(actions);
	}
	for (Entity e in world.player.tile.entities) {
		e.addActions(actions);
	}
	
	/// Add the keybind labels and add to console
	int i = 0;
	int actionsMaxLen = 0;
	for (ConsoleLink link in actions) {
		link.text = getKeyForInt(i+1) + ") " + link.text;
		link.x = 0;
		link.y = i;
		link.key = new ConsoleKeyCode(getKeyForInt(i+1));
		i++;
		
		if (link.text.length > actionsMaxLen) {actionsMaxLen = link.text.length;}
		c.labels.add(link);
	}
	
	/// display the map
	for (int mapX = 0; mapX < 5; mapX++) {
		for (int mapY = 0; mapY < 5; mapY++) {
			WorldTile tile = world.tiles[new Point(world.player.tile.x+mapX-2, world.player.tile.y+mapY-2)];
			if (tile != null) {
				ConsoleLabel label = tile.mapIcon;
				label.x = c.width-5+mapX;
				label.y = mapY+2;
				c.labels.add(label);
			}
		}
	}
	
	c.labels.add(new ConsoleLabel(c.width-6, 1, "+-----+"));
	c.labels.add(new ConsoleLabel(c.width-6, 7, "+-----+"));
	for (int i = 2; i < 7; i++) {
		c.labels.add(new ConsoleLabel(c.width-6, i, "|"));
		c.labels.add(new ConsoleLabel(c.width, i, "|"));
	}
	c.labels.add(new ConsoleLabel(c.width-3, 4, "@"));
	
	c.labels.add(new ConsoleLink(c.width-6, 0,  "?) MAP ", "?", (c, l) {}));
	
	/// display the movement compass
	if (world.player.tile is WorldTile) {
		c.labels.add(new ConsoleLink(c.width-3, 9,  "^", ConsoleKeyCode.UP, (c, l) {
			Point<int> pt = new Point<int>(world.player.tile.x, world.player.tile.y-1);
			if (!world.player.status.any((s) => s is StatusEncumbered) && world.tiles[pt] != null) {
				world.player.move(world.tiles[pt]);
				world.passTime(c);
			}
		}));
		c.labels.add(new ConsoleLink(c.width-5, 10, "<", ConsoleKeyCode.LEFT, (c, l) {
			Point<int> pt = new Point<int>(world.player.tile.x-1, world.player.tile.y);
			if (!world.player.status.any((s) => s is StatusEncumbered) && world.tiles[pt] != null) {
				world.player.move(world.tiles[pt]);
				world.passTime(c);
			}
		}));
		c.labels.add(new ConsoleLink(c.width-1, 10, ">", ConsoleKeyCode.RIGHT, (c, l) {
			Point<int> pt = new Point<int>(world.player.tile.x+1, world.player.tile.y);
			if (!world.player.status.any((s) => s is StatusEncumbered) && world.tiles[pt] != null) {
				world.player.move(world.tiles[pt]);
				world.passTime(c);
			}
		}));
		c.labels.add(new ConsoleLink(c.width-3, 11, "V", ConsoleKeyCode.DOWN, (c, l) {
			Point<int> pt = new Point<int>(world.player.tile.x, world.player.tile.y+1);
			if (!world.player.status.any((s) => s is StatusEncumbered) && world.tiles[pt] != null) {
				world.player.move(world.tiles[pt]);
				world.passTime(c);
			}
		}));
	} else {
		if (world.player.tile.customUp != null) {
			c.labels.add(new ConsoleLink(c.width-3, 9,  "^", ConsoleKeyCode.UP, (c, l) {
				if (!world.player.status.any((s) => s is StatusEncumbered)) {
					world.player.move(world.player.tile.customUp);
					world.passTime(c);
				}
			}));
		}
		
		if (world.player.tile.customDown != null) {
			c.labels.add(new ConsoleLink(c.width-3, 11, "V", ConsoleKeyCode.DOWN, (c, l) {
				if (!world.player.status.any((s) => s is StatusEncumbered)) {
					world.player.move(world.player.tile.customDown);
					world.passTime(c);
				}
			}));
		}
	}
	
	c.labels.add(new ConsoleLink(c.width-3, 10, ".", ".", (c, l) {
		world.passTime(c);
	}));
	
	/// display the status HUD
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 0,  world.player.name));
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 1,  "Health: "+(world.player.hp/world.player.hpMax*100.0).toStringAsFixed(0)+"%"));
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 2,  "Hunger: "+(world.player.hunger/world.player.maxHunger*100.0).toStringAsFixed(0)+"%"));
	
	world.player.onRenderStatus(c);
	int condY = 3;
	Map<String, int> condOccurs = {};
	for (StatusCondition cond in world.player.status) {
		condOccurs[cond.name] = (condOccurs[cond.name] ?? 0) + 1;
	}
	Map<String, bool> condDone = {};
	for (StatusCondition cond in world.player.status) {
		if (condDone[cond.name] == null) {
			condDone[cond.name] = true;
			c.labels.add(new ConsoleLabel(actionsMaxLen+4, condY,  cond.name + (condOccurs[cond.name] != null && condOccurs[cond.name] > 1 ? " x" + condOccurs[cond.name].toString() : ""), cond.color));
			condY++;
		}
	}
	
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 0,  world.player.tile.biome.name));
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 1,  "Light: " + world.lightDescriptor(world.player.tile.light)));
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 2,  "Time: " + world.timeDescriptor()));
	
	/// display the picture box
	int boxX = actionsMaxLen+4;
	int boxY = condY+1;
	int boxW = c.width - actionsMaxLen - 12;
	int boxH = c.height - 8;
	
	for (int row = boxY; row < boxY + boxH; row++) {
		if (row == boxY || row == boxY + boxH - 1) {
			c.labels.add(new ConsoleLabel(boxX, row,  "+"+repeatString("-", boxW-2)+"+"));
		} else {
			c.labels.add(new ConsoleLabel(boxX, row,  "|"));
			c.labels.add(new ConsoleLabel(boxX+boxW-1, row,  "|"));
		}
	}
	
	world.player.tile.drawPicture(c, boxX+1, boxY+1, boxW-2, boxH-2);
	
	c.labels.add(new ConsoleLink(0, c.height-1, "ENTER) Menu", ConsoleKeyCode.ENTER, (c, l) {
		c.onRefresh = handlePauseMenu;
	}));
}

ItemStack selected;
void handleInventoryView(Console c) {
	if (selected != null && selected.inventory != world.player.inventory) {
		selected = null;
	}
	
	c.labels.add(new ConsoleLabel(0, 0,  "Your inventory:"));
	
	String sizeText;
	if (world.player.inventory.maxSize == null) {
		sizeText = "Weight: " + world.player.inventory.size.toStringAsFixed(0);
	} else {
		sizeText = "Weight: " + world.player.inventory.size.toStringAsFixed(0) + " / " + world.player.inventory.maxSize.toStringAsFixed(0);
	}
	c.labels.add(new ConsoleLabel(c.rightJustified(sizeText), 0,  sizeText, (world.player.inventory.maxSize == null || world.player.inventory.size <= world.player.inventory.maxSize) ? ConsoleColor.WHITE : ConsoleColor.RED));
	
	int i = 0;
	String key = "?";
	for (ItemStack stack in world.player.inventory.items) {
		if (stack == selected) {
			key = getKeyForInt(i+1);
			c.labels.add(new ConsoleLabel(0, i+2,  getKeyForInt(i+1) + ") " + stack.name, stack.color));
		} else {
			c.labels.add(new ConsoleLink(0, i+2,  getKeyForInt(i+1) + ") " + stack.name, getKeyForInt(i+1), (c, l) {
				selected = stack;
			}, stack.color));
		}
		i++;
	}
	
	c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", ConsoleKeyCode.ENTER, (c, l) {
		c.onRefresh = handleTileView;
	}));
	
	if (selected != null) {
		int selX = c.width ~/ 3;
		int actX = 2*c.width ~/ 3;
		
		c.labels.add(new ConsoleLabel(selX, 2, selected.name, selected.color));
		c.labels.add(new ConsoleLabel(selX, 3, "Weight: " + (selected.size*selected.amt).toStringAsFixed(2)));
		
		c.labels.addAll(new ConsoleLabel(selX, 5, fitToWidth(selected.desc, actX-selX-2)).as2DLabel());
		
		c.labels.add(new ConsoleLabel(actX, 2, "Actions:"));
		
		if (selected.usable) {
			c.labels.add(new ConsoleLink(actX, 3, key + ") " + selected.useText, key, (c, l) {
				selected.use(c);
			}));
		} else {
			c.labels.add(new ConsoleLabel(actX, 3, key + ") " + selected.useText, ConsoleColor.SILVER));
		}
		
		c.labels.add(new ConsoleLink(actX, 4, ",) Discard", ",", (c, l) {
			selected.take(selected.amt);
		}));
		
		if (selected.amt > 1) {
			c.labels.add(new ConsoleLink(actX, 5, ".) Discard Some...", ".", (c, l) {
				c.onRefresh = handlePickAmount(c, selected.amt, selected.amt, (c, toDrop) {
					selected.take(toDrop);
					
					c.onRefresh = handleInventoryView;
				});
			}));
		} else {
			c.labels.add(new ConsoleLabel(actX, 5, ".) Discard Some...", ConsoleColor.SILVER));
		}
		
		int actionY = 6;
		for (ConsoleLabel action in selected.itemActions) {
			action.x = actX;
			action.y = actionY;
			
			c.labels.add(action);
			actionY++;
		}
	}
}

typedef void NotifyDialogCallback(Console c);
ConsoleRefreshHandler handleNotifyDialog(String message, NotifyDialogCallback onAccept, [String ok = "OK"]) {
	return (c) {
		c.labels.add(new ConsoleLabel(1, 1,  "+"+repeatString("-", c.width-4)+"+"));
		c.labels.add(new ConsoleLabel(1, c.height-2,  "+"+repeatString("-", c.width-4)+"+"));
		
		for (int i = 2; i < c.height-2; i++) {
			c.labels.add(new ConsoleLabel(1, i, "|"));
			c.labels.add(new ConsoleLabel(c.width-2, i, "|"));
		}
		
		c.labels.addAll(new ConsoleLabel(2, 2, fitToWidth(message, c.width-6)).as2DLabel());
		
		c.labels.add(new ConsoleLink(2, c.height - 3,  "ENTER) " + ok, ConsoleKeyCode.ANY, (c, l) {
			onAccept(c);
		}));
	};
}

typedef void YesNoDialogCallback(Console c, bool choice);
ConsoleRefreshHandler handleYesNoDialog(String message, YesNoDialogCallback onAccept, [String yes = "Yes", String no = "No"]) {
	return (c) {
		c.labels.add(new ConsoleLabel(1, 1,  "+"+repeatString("-", c.width-4)+"+"));
		c.labels.add(new ConsoleLabel(1, c.height-2,  "+"+repeatString("-", c.width-4)+"+"));
		
		for (int i = 2; i < c.height-2; i++) {
			c.labels.add(new ConsoleLabel(1, i, "|"));
			c.labels.add(new ConsoleLabel(c.width-2, i, "|"));
		}
		
		c.labels.addAll(new ConsoleLabel(2, 2, fitToWidth(message, c.width-6)).as2DLabel());
		
		c.labels.add(new ConsoleLink(2, c.height - 3,  "1) "+yes, "1", (c, l) {
			onAccept(c, true);
		}, ConsoleColor.GREEN));
		
		c.labels.add(new ConsoleLink(c.rightJustified("2) "+no) - 2, c.height - 3,  "2) "+no, "2", (c, l) {
			onAccept(c, false);
		}, ConsoleColor.RED));
	};
}

void handlePauseMenu(Console c) {
	const String menuHeader = "MINEYCRAFTA";
	String quickSave = "1) Quick Save";
	String quickLoad = "2) Quick Load";
	const String save = "3) Save...";
	const String load = "4) Load...";
	const String mainMenu = "5) Quit";
	const String ret = "ENTER) Return To Game";
	
	if (lastSavedFile == null) {
		c.labels.add(new ConsoleLabel(c.centerJustified(quickSave), 2, quickSave, ConsoleColor.SILVER));
		c.labels.add(new ConsoleLabel(c.centerJustified(quickLoad), 3, quickLoad, ConsoleColor.SILVER));
	} else {
		quickSave += " (" + lastSavedFile + ")";
		quickLoad += " (" + lastSavedFile + ")";
		
		c.labels.add(new ConsoleLink(c.centerJustified(quickSave), 2, quickSave, "1", (c, l) {
			saveToDisk(world, lastSavedFile);
			c.onRefresh = handleTileView;
		}));
		c.labels.add(new ConsoleLink(c.centerJustified(quickLoad), 3, quickLoad, "2", (c, l) {
			world = loadFromDisk(lastSavedFile);
			c.onRefresh = handleTileView;
		}));
	}
	
	c.labels.add(new ConsoleLabel(c.centerJustified(menuHeader), 0, menuHeader));
	
	c.labels.add(new ConsoleLink(c.centerJustified(save), 4, save, "3", (c, l) {
		c.onRefresh = handleCreateNewSave;
	}));
	c.labels.add(new ConsoleLink(c.centerJustified(load), 5, load, "4", (c, l) {
		c.onRefresh = handleLoadGame(c, handlePauseMenu);
	}));
	c.labels.add(new ConsoleLink(c.centerJustified(mainMenu), 6, mainMenu, "5", (c, l) {
		world = null;
		c.onRefresh = handleTitleScreen;
	}));
	c.labels.add(new ConsoleLink(c.centerJustified(ret), c.height-1, ret, ConsoleKeyCode.ENTER, (c, l) {
		c.onRefresh = handleTileView;
	}));
}

void handleCreateNewSave(Console c) {
	const String menuHeader = "Save file name:";
	c.labels.add(new ConsoleLabel(c.centerJustified(menuHeader), 0, menuHeader));
	
	c.labels.add(new ConsoleTextBox(c.width~/4, 2, world.player.name, c.width~/2, (c, l, text) {
		if (text == "") {
			c.onRefresh = handlePauseMenu;
			return;
		}
		saveToDisk(world, text.replaceAll("'", "").replaceAll('"', "").replaceAll("\\", "").replaceAll("&", "")); // sanitize input
		c.onRefresh = handleTileView;
	}));
}

ConsoleRefreshHandler handleLoadGame(Console c, ConsoleRefreshHandler onCancel) {
	return (c) {
		const String menuHeader = "Select game to load:";
		c.labels.add(new ConsoleLabel(c.centerJustified(menuHeader), 0, menuHeader));
		
		int i = 0;
		List<String> savedGames = getSavedWorlds();
		for (String gameName in savedGames) {
			String labelText = getKeyForInt(i+1) + ") " + gameName;
			c.labels.add(new ConsoleLink(c.centerJustified(labelText), i+2,  labelText, getKeyForInt(i+1), (c, l) {
				world = loadFromDisk(gameName);
				c.onRefresh = handleTileView;
			}));
			i++;
		}
		
		c.labels.add(new ConsoleLink(0, c.height-1, "ENTER) Cancel", ConsoleKeyCode.ENTER, (c, l) {
			c.onRefresh = onCancel;
		}));
		
		const String delFiles = "DEL) Delete Files";
		c.labels.add(new ConsoleLink(c.rightJustified(delFiles), c.height-1, delFiles, ConsoleKeyCode.DELETE, (c, l) {
			c.onRefresh = handleDeleteGames(c, handleLoadGame(c, onCancel));
		}));
	};
}

ConsoleRefreshHandler handleDeleteGames(Console c, ConsoleRefreshHandler onDone) {
	return (c) {
		const String menuHeader = "Select game(s) to DELETE:";
		c.labels.add(new ConsoleLabel(c.centerJustified(menuHeader), 0, menuHeader, ConsoleColor.RED));
		
		int i = 0;
		List<String> savedGames = getSavedWorlds();
		for (String gameName in savedGames) {
			String labelText = getKeyForInt(i+1) + ") " + gameName;
			c.labels.add(new ConsoleLink(c.centerJustified(labelText), i+2,  labelText, getKeyForInt(i+1), (c, l) {
				deleteSavedWorld(gameName);
			}));
			i++;
		}
		
		c.labels.add(new ConsoleLink(0, c.height-1, "ENTER) Back", ConsoleKeyCode.ENTER, (c, l) {
			c.onRefresh = onDone;
		}));
	};
}

bool autocraft = false;

FeatureRecipe selFeatureRecipe;
void handleCraftFeature(Console c) {
	c.labels.add(new ConsoleLabel(0, 0,  "Craft Structure"));
	
	String spaceString = "Space: " + world.player.tile.featureSpace.toString() + " / " + world.player.tile.maxFeatureSpace.toString();
	c.labels.add(new ConsoleLabel(c.rightJustified(spaceString), 0, spaceString, (world.player.tile.featureSpace >= world.player.tile.maxFeatureSpace ? ConsoleColor.RED : ConsoleColor.WHITE)));
	
	List<ConsoleLabel> recipeLabels = [];
	int i = 0;
	int menuI = 0;
	int recipeXMax = 0;
	int selI;
	String selIkey;
	for (FeatureRecipe recipe in featureRecipes) {
		if (recipe.canMakeOn(world.player.tile)) {
			ConsoleColor color = (recipe.canMake(world.player.inventory) && world.player.tile.featureSpace + recipe.space <= world.player.tile.maxFeatureSpace) ? ConsoleColor.GREEN : ConsoleColor.RED;
			if (recipe == selFeatureRecipe) {
				recipeLabels.add(new ConsoleLabel(0, menuI+2, getKeyForInt(menuI+1) + ") " + recipe.name, color));
				selI = i;
				selIkey = getKeyForInt(menuI+1);
			} else {
				recipeLabels.add(new ConsoleLink(0, menuI+2, getKeyForInt(menuI+1) + ") " + recipe.name, getKeyForInt(menuI+1), (c, l) {
					selFeatureRecipe = recipe;
				}, color));
			}
			recipeXMax = max(recipeXMax, recipe.name.length+5);
			menuI++;
		}
		i++;
	}
	c.labels.addAll(recipeLabels);
	
	if (selFeatureRecipe != null) {
		c.labels.add(new ConsoleLabel(recipeXMax, 2, selFeatureRecipe.name));
		
		List<ConsoleLabel> desc = new ConsoleLabel(recipeXMax, 4, fitToWidth(selFeatureRecipe.desc, c.width - recipeXMax - 2)).as2DLabel();
		c.labels.addAll(desc);
		
		c.labels.add(new ConsoleLabel(recipeXMax, desc.length+5, "Requires:"));
		c.labels.add(new ConsoleLabel(recipeXMax, desc.length+6, "* " + selFeatureRecipe.space.toString() + " space", (world.player.tile.featureSpace + selFeatureRecipe.space <= world.player.tile.maxFeatureSpace ? ConsoleColor.GREEN : ConsoleColor.RED)));
		int y = desc.length+7;
		for (RecipeInput input in selFeatureRecipe.inputs) {
			String inputString = fitToWidth("* " + input.amt.toString() + " " + input.name, c.width - recipeXMax - 2);
			ConsoleColor color = input.matchesAny(world.player.inventory) ? ConsoleColor.GREEN : ConsoleColor.RED;
			List<ConsoleLabel> inputLabels = new ConsoleLabel(recipeXMax, y, inputString, color).as2DLabel();
			c.labels.addAll(inputLabels);
			y += inputLabels.length;
		}
		
		if (selFeatureRecipe.canMake(world.player.inventory) && world.player.tile.featureSpace + selFeatureRecipe.space <= world.player.tile.maxFeatureSpace) {
			c.labels.add(new ConsoleLink(recipeXMax, y+1, selIkey+") Craft", selIkey, (c, l) {
				List<ItemStack> items = [];
				
				if (autocraft) {
					// just craft it
					
					for (RecipeInput input in selFeatureRecipe.inputs) {
						int i = 0;
						for (ItemStack stack in new List<ItemStack>.from(world.player.inventory.items)) {
							if (input.matches(stack)) {
								if (input.usedUp) {
									stack.take(input.amt);
								}
								items.add(stack);
								break;
							}
							i++;
						}
					}
					
					selFeatureRecipe.craft(world.player.tile, items);
					world.passTime(c, selFeatureRecipe.timePassed);
					world.player.score += selFeatureRecipe.scoreOnCraft(items);
					
					selFeatureRecipe = null;
					c.onRefresh = handleTileView;
				} else {
					int i = 0;
					SelectMaterialCallback onMatSel;
					onMatSel = (c, succ, stack) {
						if (!succ) {
							i--;
							if (i < 0) {
								c.onRefresh = handleCraftFeature;
							} else {
								ItemStack cancelled = items.removeLast();
								if (selFeatureRecipe.inputs[i].usedUp) {
									cancelled.give(selFeatureRecipe.inputs[i].amt);
								}
								if (!world.player.inventory.items.contains(cancelled)) {
									world.player.inventory.add(cancelled);
								}
								
								c.onRefresh = handleSelectMaterial(c, selFeatureRecipe.inputs[i], onMatSel);
							}
						} else {
							items.add(stack);
							if (selFeatureRecipe.inputs[i].usedUp && stack != null) {
								stack.take(selFeatureRecipe.inputs[i].amt);
							}
							i++;
							
							if (i >= selFeatureRecipe.inputs.length) {
								// craft
								selFeatureRecipe.craft(world.player.tile, items);
								world.passTime(c, selFeatureRecipe.timePassed);
								world.player.score += selFeatureRecipe.scoreOnCraft(items);
								
								selFeatureRecipe = null;
								c.onRefresh = handleTileView;
							} else {
								c.onRefresh = handleSelectMaterial(c, selFeatureRecipe.inputs[i], onMatSel);
							}
						}
					};
					c.onRefresh = handleSelectMaterial(c, selFeatureRecipe.inputs[i], onMatSel);
				}
			}));
		} else {
			c.labels.add(new ConsoleLabel(recipeXMax, y+1, selIkey+") Craft", ConsoleColor.SILVER));
		}
	}
	
	c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", ConsoleKeyCode.ENTER, (c, l) {
		selFeatureRecipe = null;
		c.onRefresh = handleTileView;
	}));
	
	String autocraftString = ".) Autocraft: " + (autocraft ? "ON" : "OFF");
	ConsoleColor autocraftColor = autocraft ? ConsoleColor.GREEN : ConsoleColor.RED;
	c.labels.add(new ConsoleLink(c.rightJustified(autocraftString), c.height - 1,  autocraftString, ".", (c, l) {
		autocraft = !autocraft;
	}, autocraftColor));
}

typedef void SelectMaterialCallback(Console c, bool success, ItemStack stack);
ConsoleRefreshHandler handleSelectMaterial(Console c, RecipeInput input, SelectMaterialCallback onDone, [int factor = 1]) {
	return (c) {
		c.labels.add(new ConsoleLabel(0, 0, "Select " + (input.amt*factor).toString() + " " + input.name + ":"));
		
		int i = 0;
		if (input.optional) {
			c.labels.add(new ConsoleLink(0, i+2,  getKeyForInt(i+1) + ") None", getKeyForInt(i+1), (c, l) {
				onDone(c, true, null);
			}));
			i++;
		}
		
		for (ItemStack stack in world.player.inventory.items) {
			if (input.matches(stack, factor)) {
				c.labels.add(new ConsoleLink(0, i+2,  getKeyForInt(i+1) + ") " + stack.name, getKeyForInt(i+1), (c, l) {
					onDone(c, true, stack);
				}, stack.color));
				i++;
			}
		}
		
		c.labels.add(new ConsoleLink(0, c.height - 1, "ENTER) Back", ConsoleKeyCode.ENTER, (c, l) {
			onDone(c, false, null);
		}));
	};
}

ItemRecipe selItemRecipe;
int selFactor = 1;
ConsoleRefreshHandler handleCraftItem(Console c, List<ItemRecipe> recipes) {
	return (c) {
		c.labels.add(new ConsoleLabel(0, 0,  "Craft Item"));
		
		List<ConsoleLabel> recipeLabels = [];
		int i = 0;
		int menuI = 0;
		int recipeXMax = 0;
		int selI;
		for (ItemRecipe recipe in recipes) {
			ConsoleColor color = (recipe.canMake(world.player.inventory, selFactor)) ? ConsoleColor.GREEN : ConsoleColor.RED;
			if (recipe == selItemRecipe) {
				recipeLabels.add(new ConsoleLabel(0, menuI+2, getKeyForInt(menuI+1) + ") " + recipe.name, color));
				selI = i;
			} else {
				recipeLabels.add(new ConsoleLink(0, menuI+2, getKeyForInt(menuI+1) + ") " + recipe.name, getKeyForInt(menuI+1), (c, l) {
					selItemRecipe = recipe;
				}, color));
			}
			recipeXMax = max(recipeXMax, recipe.name.length+5);
			menuI++;
			i++;
		}
		c.labels.addAll(recipeLabels);
		
		if (selItemRecipe != null) {
			c.labels.add(new ConsoleLabel(recipeXMax, 2, selItemRecipe.name));
			
			List<ConsoleLabel> desc = new ConsoleLabel(recipeXMax, 4, fitToWidth(selItemRecipe.desc, c.width - recipeXMax - 2)).as2DLabel();
			c.labels.addAll(desc);
			
			c.labels.add(new ConsoleLabel(recipeXMax, desc.length+5, "Requires:"));
			int y = desc.length+6;
			for (RecipeInput input in selItemRecipe.inputs) {
				String inputString = fitToWidth("* " + (input.amt*selFactor).toString() + " " + input.name, c.width - recipeXMax - 2);
				ConsoleColor color = input.matchesAny(world.player.inventory, selFactor) ? ConsoleColor.GREEN : ConsoleColor.RED;
				List<ConsoleLabel> inputLabels = new ConsoleLabel(recipeXMax, y, inputString, color).as2DLabel();
				c.labels.addAll(inputLabels);
				y += inputLabels.length;
			}
			
			if (selItemRecipe.canMake(world.player.inventory, selFactor)) {
				c.labels.add(new ConsoleLink(recipeXMax, y+1, getKeyForInt(selI+1)+") Craft", getKeyForInt(selI+1), (c, l) {
					List<ItemStack> items = [];
					
					if (autocraft) {
						// just craft it
						
						for (RecipeInput input in selItemRecipe.inputs) {
							int i = 0;
							for (ItemStack stack in new List<ItemStack>.from(world.player.inventory.items)) {
								if (input.matches(stack)) {
									if (input.usedUp) {
										stack.take(input.amt*selFactor);
									}
									items.add(stack);
								}
								i++;
							}
						}
						
						world.player.inventory.addAll(selItemRecipe.craft(items, selFactor));
						world.passTime(c, selItemRecipe.timePassed);
						world.player.score += selItemRecipe.scoreOnCraft(items) * selFactor;
						
						selItemRecipe = null;
						c.onRefresh = handleCraftItem(c, recipes);
					} else {
						int i = 0;
						SelectMaterialCallback onMatSel;
						onMatSel = (c, succ, stack) {
							if (!succ) {
								i--;
								if (i < 0) {
									c.onRefresh = handleCraftItem(c, recipes);
								} else {
									ItemStack cancelled = items.removeLast();
									if (selItemRecipe.inputs[i].usedUp) {
										cancelled.give(selItemRecipe.inputs[i].amt*selFactor);
									}
									if (!world.player.inventory.items.contains(cancelled)) {
										world.player.inventory.add(cancelled);
									}
									
									c.onRefresh = handleSelectMaterial(c, selItemRecipe.inputs[i], onMatSel, selFactor);
								}
							} else {
								items.add(stack);
								if (selItemRecipe.inputs[i].usedUp && stack != null) {
									stack.take(selItemRecipe.inputs[i].amt*selFactor);
								}
								i++;
								
								if (i >= selItemRecipe.inputs.length) {
									// craft
									world.player.inventory.addAll(selItemRecipe.craft(items, selFactor));
									world.passTime(c, selItemRecipe.timePassed);
									world.player.score += selItemRecipe.scoreOnCraft(items) * selFactor;
									
									selItemRecipe = null;
									c.onRefresh = handleCraftItem(c, recipes);
								} else {
									c.onRefresh = handleSelectMaterial(c, selItemRecipe.inputs[i], onMatSel, selFactor);
								}
							}
						};
						c.onRefresh = handleSelectMaterial(c, selItemRecipe.inputs[i], onMatSel, selFactor);
					}
				}));
			} else {
				c.labels.add(new ConsoleLabel(recipeXMax, y+1, getKeyForInt(selI+1)+") Craft", ConsoleColor.SILVER));
			}
		}
		
		c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", ConsoleKeyCode.ENTER, (c, l) {
			selItemRecipe = null;
			c.onRefresh = handleTileView;
		}));
		
		String autocraftString = ".) Autocraft: " + (autocraft ? "ON" : "OFF");
		ConsoleColor autocraftColor = autocraft ? ConsoleColor.GREEN : ConsoleColor.RED;
		c.labels.add(new ConsoleLink(c.rightJustified(autocraftString), c.height - 1,  autocraftString, ".", (c, l) {
			autocraft = !autocraft;
		}, autocraftColor));
		
		String factorString = selFactor.toString();
		c.labels.add(new ConsoleLabel(c.centerJustified(factorString), c.height - 1,  factorString));
		c.labels.add(new ConsoleLink(c.width~/2-2, c.height - 1,  "-", "-", (c, l) {
			if (selFactor > 1) {selFactor--;}
		}));
		c.labels.add(new ConsoleLink(c.width~/2+2, c.height - 1,  "+", "=", (c, l) {
			selFactor++;
		}));
	};
}

Feature selFeature;
void handleInspectView(Console c) {
	c.labels.add(new ConsoleLabel(0, 0,  "Looking around you, you see:"));
	
	String spaceString = "Space: " + world.player.tile.featureSpace.toString() + " / " + world.player.tile.maxFeatureSpace.toString();
	c.labels.add(new ConsoleLabel(c.rightJustified(spaceString), c.height - 1, spaceString, (world.player.tile.featureSpace >= world.player.tile.maxFeatureSpace ? ConsoleColor.RED : ConsoleColor.WHITE)));
	
	int i = 0;
	for (Feature feature in world.player.tile.features) {
		c.labels.add(new ConsoleLink(0, i+2,  getKeyForInt(i+1) + ") " + feature.name, getKeyForInt(i+1), (c, l) {
			selFeature = feature;
		}, feature.color));
		i++;
	}
	
	c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", ConsoleKeyCode.ENTER, (c, l) {
		selFeature = null;
		c.onRefresh = handleTileView;
	}));
	
	if (selFeature != null) {
		int selX = c.width ~/ 3;
		int actX = 2*c.width ~/ 3;
		
		c.labels.add(new ConsoleLabel(selX, 2, selFeature.name, selFeature.color));
		c.labels.add(new ConsoleLabel(selX, 4, "Space used: "+selFeature.space.toString()));
		c.labels.addAll(new ConsoleLabel(selX, 5, fitToWidth(selFeature.desc, actX-selX-2)).as2DLabel());
		
		c.labels.add(new ConsoleLabel(actX, 2, "Actions:"));
		
		DeconstructionRecipe decon = selFeature.toDeconstruct;
		if (decon != null) {
			c.labels.add(new ConsoleLink(actX, 3, ",) Deconstruct", ",", (c, l) {
				int i = 0;
				List<ItemStack> items = [];
				
				SelectMaterialCallback onMatSel;
				onMatSel = (c, succ, stack) {
					if (!succ) {
						i--;
						if (i < 0) {
							c.onRefresh = handleInspectView;
						} else {
							ItemStack cancelled = items.removeLast();
							if (decon.inputs[i].usedUp) {
								cancelled.give(decon.inputs[i].amt);
							}
							if (!world.player.inventory.items.contains(cancelled)) {
								world.player.inventory.add(cancelled);
							}
							
							c.onRefresh = handleSelectMaterial(c, decon.inputs[i], onMatSel);
						}
					} else {
						items.add(stack);
						if (decon.inputs[i].usedUp && stack != null) {
							stack.take(decon.inputs[i].amt);
						}
						i++;
						
						if (i >= decon.inputs.length) {
							// craft
							List<ItemStack> results = decon.craft(items);
							world.player.inventory.addAll(results);
							selFeature.tile.features.remove(selFeature);
							
							world.passTime(c, decon.timePassed);
							
							String dialogText = "You deconstruct the " + selFeature.name + ".";
							
							if (results.isNotEmpty) {
								dialogText += " You manage to salvage:\n\n";
								for (ItemStack stack in results) {
									dialogText += "* " + stack.name + "\n";
								}
							}
							
							c.onRefresh = handleNotifyDialog(dialogText, (c) {
								selFeature = null;
								c.onRefresh = handleInspectView;
							});
						} else {
							c.onRefresh = handleSelectMaterial(c, decon.inputs[i], onMatSel);
						}
					}
				};
				c.onRefresh = handleSelectMaterial(c, decon.inputs[i], onMatSel);
			}));
		} else {
			c.labels.add(new ConsoleLabel(actX, 3, ",) Deconstruct", ConsoleColor.SILVER));
		}
	}
}

Entity selBattleTarget;
ConsoleRefreshHandler handleBattle(Console c, Battle battle) {
	return (c) {
		bool isDoneBattling = (battle.enemies.isEmpty || battle.allies.isEmpty);
		
		// handle what happens when selBattleTarget is null, or the target is no longer in the fight
		if (selBattleTarget == null || !battle.isInBattle(selBattleTarget)) {
			if (battle.enemies.isEmpty && battle.allies.isEmpty) {
				selBattleTarget = world.player;
			} else if (battle.enemies.isEmpty) {
				selBattleTarget = battle.allies[0][0];
			} else {
				selBattleTarget = battle.enemies[0][0];
			}
		}
		
		int actionsMaxLen = 0;
		if (isDoneBattling) {
			c.labels.add(new ConsoleLink(0, 0, "ENTER) Continue", ConsoleKeyCode.ANY, (c, l) {
				selBattleTarget = null;
				
				if (world.player.hp > 0) {
					if (battle.loot.items.isNotEmpty) {
						String dialogText = "You emerge victorious! Gathering the spoils of battle, you find:\n\n";
						for (ItemStack item in battle.loot.items) {
							dialogText += "* " + item.name + "\n";
						}
						c.onRefresh = handleNotifyDialog(dialogText, (c) {
							world.player.inventory.addAll(battle.loot.items);
							
							c.onRefresh = handleTileView;
						});
					} else {
						c.onRefresh = handleTileView;
					}
				} else {
					c.onRefresh = handlePlayerDeath;
				}
			}));
			actionsMaxLen = 15;
		} else {
			// gather possible actions for the action bar
			List<ConsoleLink> actions = new List<ConsoleLink>();
			
			actions.add(new ConsoleLink(0, 0, "Attack With Fists", null, (c, l) {
				battle.log.clear();
				
				double hitChance = 0.9 - (0.4*battle.getRow(selBattleTarget));
				battle.doAction(world.player, battleActionHitOrMiss(world.player, selBattleTarget, "fists", rng.nextInt(4) + 2, hitChance, 5));
				
				battle.doTurn();
			}));
			
			for (ItemStack stack in world.player.inventory.items) {
				stack.addBattleActions(battle, actions);
			}
			
			if (battle.canMoveForwards(world.player)) {
				actions.add(new ConsoleLink(0, 0, "Move Forwards", null, (c, l) {
					battle.log.clear();
					battle.doAction(world.player, battleActionMoveForwards(world.player));
					battle.doTurn();
				}));
			}
			
			if (battle.canMoveBackwards(world.player)) {
				actions.add(new ConsoleLink(0, 0, "Move Backwards", null, (c, l) {
					battle.log.clear();
					battle.doAction(world.player, battleActionMoveBackwards(world.player));
					battle.doTurn();
				}));
			}
			
			actions.add(new ConsoleLink(0, 0, "Flee", null, (c, l) {
				battle.log.clear();
				battle.log.write("You attempt to flee... ");
				
				double fleeChance = .4;
				if (rng.nextDouble() < fleeChance) {
					battle.log.write("You manage to get away safely!\n");
					battle.enemies.clear();
				} else {
					battle.log.write("You can't escape!\n");
					battle.doAction(world.player, battleActionDoNothing(world.player, 4));
					battle.doTurn();
				}
			}));
			
			// Add the action bar
			int i = 0;
			for (ConsoleLink link in actions) {
				link.text = getKeyForInt(i+1) + ") " + link.text;
				link.x = 0;
				link.y = i;
				link.key = new ConsoleKeyCode(getKeyForInt(i+1));
				i++;
				
				if (link.text.length > actionsMaxLen) {actionsMaxLen = link.text.length;}
				c.labels.add(link);
			}
		}
		
		// Add the player's info
		c.labels.add(new ConsoleLabel(actionsMaxLen+4, 0,  "You:"));
		c.labels.add(new ConsoleLabel(actionsMaxLen+4, 1,  world.player.name));
		c.labels.add(new ConsoleLabel(actionsMaxLen+4, 2,  "Health: "+(world.player.hp/world.player.hpMax*100.0).toStringAsFixed(0)+"%"));
		
		world.player.onRenderStatus(c);
		int condY = 3;
		Map<String, int> condOccurs = {};
		for (StatusCondition cond in world.player.status) {
			condOccurs[cond.name] = (condOccurs[cond.name] ?? 0) + 1;
		}
		Map<String, bool> condDone = {};
		for (StatusCondition cond in world.player.status) {
			if (condDone[cond.name] == null) {
				condDone[cond.name] = true;
				c.labels.add(new ConsoleLabel(actionsMaxLen+4, condY,  cond.name + (condOccurs[cond.name] != null && condOccurs[cond.name] > 1 ? " x" + condOccurs[cond.name].toString() : ""), cond.color));
				condY++;
			}
		}
		
		// Add the target's info
		selBattleTarget.onRenderStatus(c);
		int targetCondY = 3;
		if (!isDoneBattling) {
			c.labels.add(new ConsoleLabel(actionsMaxLen+20, 0,  "Target:"));
			c.labels.add(new ConsoleLabel(actionsMaxLen+20, 1,  selBattleTarget.name));
			c.labels.add(new ConsoleLabel(actionsMaxLen+20, 2,  "Health: "+(selBattleTarget.hp/selBattleTarget.hpMax*100.0).toStringAsFixed(0)+"%"));
			
			Map<String, int> targetCondOccurs = {};
			for (StatusCondition cond in selBattleTarget.status) {
				targetCondOccurs[cond.name] = (targetCondOccurs[cond.name] ?? 0) + 1;
			}
			Map<String, bool> targetCondDone = {};
			for (StatusCondition cond in selBattleTarget.status) {
				if (targetCondDone[cond.name] == null) {
					targetCondDone[cond.name] = true;
					c.labels.add(new ConsoleLabel(actionsMaxLen+4, targetCondY,  cond.name + (targetCondOccurs[cond.name] != null && targetCondOccurs[cond.name] > 1 ? " x" + targetCondOccurs[cond.name].toString() : ""), cond.color));
					targetCondY++;
				}
			}
		}
		
		// Add the battle graphic
		int boxX = actionsMaxLen+2;
		int boxY = max(condY, targetCondY)+1;
		int boxW = c.width - boxX - 2;
		int boxH = (c.height-5) ~/ 2;
		
		for (int row = boxY; row < boxY + boxH; row++) {
			if (row == boxY || row == boxY + boxH - 1) {
				c.labels.add(new ConsoleLabel(boxX, row,  "+"+repeatString("-", boxW-2)+"+"));
			} else {
				c.labels.add(new ConsoleLabel(boxX, row,  "|"));
				c.labels.add(new ConsoleLabel(boxX+boxW-1, row,  "|"));
			}
		}
		
		world.player.tile.drawBattlePicture(c, boxX+1, boxY+1, boxW-2, boxH-2);
		
		int ex = 0;
		for (List<Entity> col in battle.allies) {
			int ey = 0;
			for (Entity e in col) {
				ConsoleColor fore = (e == selBattleTarget ? Console.invertColor(e.color) : e.color);
				ConsoleColor back = (e == selBattleTarget ? ConsoleColor.WHITE : ConsoleColor.BLACK);
				
				ConsoleKeyCode key = null;
				if (!isDoneBattling) {
					if (ey > 0 && battle.allies[ex][ey-1] == selBattleTarget) {
						key = ConsoleKeyCode.UP;
					} else if (ey < battle.allies[ex].length-1 && battle.allies[ex][ey+1] == selBattleTarget) {
						key = ConsoleKeyCode.DOWN;
					} else if (ex > 0 && battle.allies[ex-1][min(ey, battle.allies[ex-1].length-1)] == selBattleTarget) {
						key = ConsoleKeyCode.LEFT;
					} else if (ex < battle.allies.length-1 && battle.allies[ex+1][min(ey, battle.allies[ex+1].length-1)] == selBattleTarget) {
						key = ConsoleKeyCode.RIGHT;
					} else if (battle.enemies[0][min(ey, battle.enemies[0].length-1)] == selBattleTarget) {
						key = ConsoleKeyCode.LEFT;
					}
				}
				
				c.labels.add(new ConsoleLink(boxX+boxW~/2-(ex/battle.allies.length*boxW/2).toInt()-2-((boxW~/2-1)~/(2*battle.allies.length)), boxY+((boxH-2)~/(2*col.length))+(ey/col.length*(boxH-2)).toInt()+1, e.char, key, (c, l) {
					if (!isDoneBattling) {
						selBattleTarget = e;
					}
				}, fore, back));
				ey++;
			}
			ex++;
		}
		
		ex = 0;
		for (List<Entity> col in battle.enemies) {
			int ey = 0;
			for (Entity e in col) {
				ConsoleColor fore = (e == selBattleTarget ? Console.invertColor(e.color) : e.color);
				ConsoleColor back = (e == selBattleTarget ? ConsoleColor.WHITE : ConsoleColor.BLACK);
				
				ConsoleKeyCode key = null;
				if (!isDoneBattling) {
					if (ey > 0 && battle.enemies[ex][ey-1] == selBattleTarget) {
						key = ConsoleKeyCode.DOWN;
					} else if (ey < battle.enemies[ex].length-1 && battle.enemies[ex][ey+1] == selBattleTarget) {
						key = ConsoleKeyCode.UP;
					} else if (ex > 0 && battle.enemies[ex-1][min(ey, battle.enemies[ex-1].length-1)] == selBattleTarget) {
						key = ConsoleKeyCode.RIGHT;
					} else if (ex < battle.enemies.length-1 && battle.enemies[ex+1][min(ey, battle.enemies[ex+1].length-1)] == selBattleTarget) {
						key = ConsoleKeyCode.LEFT;
					} else if (battle.allies[0][min(ey, battle.allies[0].length-1)] == selBattleTarget) {
						key = ConsoleKeyCode.RIGHT;
					}
				}
				
				c.labels.add(new ConsoleLink(boxX+boxW~/2+(ex/battle.enemies.length*boxW/2).toInt()+2-((boxW~/2-1)~/(2*battle.enemies.length)), boxY+((boxH-2)~/(2*col.length))+(ey/col.length*(boxH-2)).toInt()+1, e.char, key, (c, l) {
					if (!isDoneBattling) {
						selBattleTarget = e;
					}
				}, fore, back));
				ey++;
			}
			ex++;
		}
		
		// Add the log
		c.labels.addAll(new ConsoleLabel(boxX, boxY + boxH + 2, fitToWidth(battle.log.toString(), boxW)).as2DLabel());
	};
}

typedef void PickAmountCallback(Console c, int amt);
ConsoleRefreshHandler handlePickAmount(Console c, int before, int selAmt, PickAmountCallback onDone) {
	return (c) {
		const String howMany = "How Many?";
		c.labels.add(new ConsoleLabel(c.centerJustified(howMany), 0, howMany));
		
		String amtString = selAmt.toString();
		c.labels.add(new ConsoleLabel(c.centerJustified(amtString), 3, amtString));
		
		c.labels.add(new ConsoleLink(c.width~/2-3, 3, "-", null, (c, l) {
			if (selAmt > 0) {
				selAmt--;
			}
		}));
		c.labels.add(new ConsoleLink(c.width~/2-5, 3, "<", null, (c, l) {
			selAmt = 0;
		}));
		c.labels.add(new ConsoleLink(c.width~/2+3, 3, "+", null, (c, l) {
			if (selAmt < before) {
				selAmt++;
			}
		}));
		c.labels.add(new ConsoleLink(c.width~/2+5, 3, ">", null, (c, l) {
			selAmt = before;
		}));
		
		const String takeString = "Take:";
		c.labels.add(new ConsoleLabel(c.centerJustified(takeString), 2, takeString));
		
		c.labels.add(new ConsoleLabel(c.width~/2-13, 2, "Before:"));
		String beforeString = before.toString();
		c.labels.add(new ConsoleLabel(c.width~/2-6-beforeString.length, 3, beforeString));
		
		c.labels.add(new ConsoleLabel(c.width~/2+7, 2, "After:"));
		String afterString = (before-selAmt).toString();
		c.labels.add(new ConsoleLabel(c.width~/2+7, 3, afterString));
		
		const String confirm = "ENTER) Confirm";
		c.labels.add(new ConsoleLink(c.centerJustified(confirm), 5, confirm, ConsoleKeyCode.ENTER, (c, l) {
			onDone(c, selAmt);
		}));
	};
}

SmeltingRecipe selSmeltingRecipe;
ConsoleRefreshHandler handleSmelting(Console c, FeatureFurnace furnace) {
	return (c) {
		c.labels.add(new ConsoleLabel(0, 0,  "Smelt Item"));
		
		List<ConsoleLabel> recipeLabels = [];
		int i = 0;
		int menuI = 0;
		int recipeXMax = 0;
		int selI;
		for (SmeltingRecipe recipe in smeltingRecipes) {
			ConsoleColor color = (recipe.canMake(world.player.inventory, selFactor) && furnace.fuel >= recipe.fuel * selFactor) ? ConsoleColor.GREEN : ConsoleColor.RED;
			if (recipe == selSmeltingRecipe) {
				recipeLabels.add(new ConsoleLabel(0, menuI+2, getKeyForInt(menuI+1) + ") " + recipe.name, color));
				selI = i;
			} else {
				recipeLabels.add(new ConsoleLink(0, menuI+2, getKeyForInt(menuI+1) + ") " + recipe.name, getKeyForInt(menuI+1), (c, l) {
					selSmeltingRecipe = recipe;
				}, color));
			}
			recipeXMax = max(recipeXMax, recipe.name.length+5);
			menuI++;
			i++;
		}
		c.labels.addAll(recipeLabels);
		
		if (selSmeltingRecipe != null) {
			c.labels.add(new ConsoleLabel(recipeXMax, 2, selSmeltingRecipe.name));
			
			List<ConsoleLabel> desc = new ConsoleLabel(recipeXMax, 4, fitToWidth(selSmeltingRecipe.desc, c.width - recipeXMax - 2)).as2DLabel();
			c.labels.addAll(desc);
			
			c.labels.add(new ConsoleLabel(recipeXMax, desc.length+5, "Requires:"));
			c.labels.add(new ConsoleLabel(recipeXMax, desc.length+6, "* " + (selSmeltingRecipe.fuel*selFactor).toString() + " fuel", furnace.fuel >= selSmeltingRecipe.fuel * selFactor ? ConsoleColor.GREEN : ConsoleColor.RED));
			int y = desc.length+7;
			for (RecipeInput input in selSmeltingRecipe.inputs) {
				String inputString = fitToWidth("* " + (input.amt*selFactor).toString() + " " + input.name, c.width - recipeXMax - 2);
				ConsoleColor color = input.matchesAny(world.player.inventory, selFactor) ? ConsoleColor.GREEN : ConsoleColor.RED;
				List<ConsoleLabel> inputLabels = new ConsoleLabel(recipeXMax, y, inputString, color).as2DLabel();
				c.labels.addAll(inputLabels);
				y += inputLabels.length;
			}
			
			if (selSmeltingRecipe.canMake(world.player.inventory, selFactor) && furnace.fuel >= selSmeltingRecipe.fuel * selFactor) {
				c.labels.add(new ConsoleLink(recipeXMax, y+1, getKeyForInt(selI+1)+") Smelt", getKeyForInt(selI+1), (c, l) {
					List<ItemStack> items = [];
					
					if (autocraft) {
						// just craft it
						
						for (RecipeInput input in selSmeltingRecipe.inputs) {
							int i = 0;
							for (ItemStack stack in new List<ItemStack>.from(world.player.inventory.items)) {
								if (input.matches(stack)) {
									if (input.usedUp) {
										stack.take(input.amt*selFactor);
									}
									items.add(stack);
								}
								i++;
							}
						}
						
						world.player.inventory.addAll(selSmeltingRecipe.craft(items, selFactor));
						furnace.fuel -= selSmeltingRecipe.fuel * selFactor;
						world.passTime(c, selSmeltingRecipe.timePassed);
						world.player.score += selSmeltingRecipe.scoreOnCraft(items) * selFactor;
						
						selSmeltingRecipe = null;
						c.onRefresh = handleSmelting(c, furnace);
					} else {
						int i = 0;
						SelectMaterialCallback onMatSel;
						onMatSel = (c, succ, stack) {
							if (!succ) {
								i--;
								if (i < 0) {
									c.onRefresh = handleSmelting(c, furnace);
								} else {
									ItemStack cancelled = items.removeLast();
									if (selSmeltingRecipe.inputs[i].usedUp) {
										cancelled.give(selSmeltingRecipe.inputs[i].amt*selFactor);
									}
									if (!world.player.inventory.items.contains(cancelled)) {
										world.player.inventory.add(cancelled);
									}
									
									c.onRefresh = handleSelectMaterial(c, selSmeltingRecipe.inputs[i], onMatSel, selFactor);
								}
							} else {
								items.add(stack);
								if (selSmeltingRecipe.inputs[i].usedUp && stack != null) {
									stack.take(selSmeltingRecipe.inputs[i].amt*selFactor);
								}
								i++;
								
								if (i >= selSmeltingRecipe.inputs.length) {
									// craft
									world.player.inventory.addAll(selSmeltingRecipe.craft(items, selFactor));
									furnace.fuel -= selSmeltingRecipe.fuel * selFactor;
									world.passTime(c, selSmeltingRecipe.timePassed);
									world.player.score += selSmeltingRecipe.scoreOnCraft(items) * selFactor;
									
									selSmeltingRecipe = null;
									c.onRefresh = handleSmelting(c, furnace);
								} else {
									c.onRefresh = handleSelectMaterial(c, selSmeltingRecipe.inputs[i], onMatSel, selFactor);
								}
							}
						};
						c.onRefresh = handleSelectMaterial(c, selSmeltingRecipe.inputs[i], onMatSel, selFactor);
					}
				}));
			} else {
				c.labels.add(new ConsoleLabel(recipeXMax, y+1, getKeyForInt(selI+1)+") Smelt", ConsoleColor.SILVER));
			}
		}
		
		c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", ConsoleKeyCode.ENTER, (c, l) {
			selSmeltingRecipe = null;
			c.onRefresh = handleTileView;
		}));
		
		String autocraftString = ".) Autosmelt: " + (autocraft ? "ON" : "OFF");
		ConsoleColor autocraftColor = autocraft ? ConsoleColor.GREEN : ConsoleColor.RED;
		c.labels.add(new ConsoleLink(c.rightJustified(autocraftString), c.height - 1,  autocraftString, ".", (c, l) {
			autocraft = !autocraft;
		}, autocraftColor));
		
		String factorString = selFactor.toString();
		c.labels.add(new ConsoleLabel(c.centerJustified(factorString), c.height - 1,  factorString));
		c.labels.add(new ConsoleLink(c.width~/2-2, c.height - 1,  "-", "-", (c, l) {
			if (selFactor > 1) {selFactor--;}
		}));
		c.labels.add(new ConsoleLink(c.width~/2+2, c.height - 1,  "+", "=", (c, l) {
			selFactor++;
		}));
		
		String fuelString = ",) Fuel: " + furnace.fuel.toString();
		c.labels.add(new ConsoleLink(c.rightJustified(fuelString), 0,  fuelString, ",", (c, l) {
			c.onRefresh = handleSelectMaterial(c, new RecipeInput(" or more fuel", filterAnyFuel, 1), (c, succ, stack) {
				if (succ) {
					c.onRefresh = handlePickAmount(c, stack.amt, stack.amt, (c, toAdd) {
						stack.take(toAdd);
						furnace.fuel += stack.fuelValue * toAdd;
						
						c.onRefresh = handleSmelting(c, furnace);
					});
				} else {
					c.onRefresh = handleSmelting(c, furnace);
				}
			});
		}));
	};
}

void handlePlayerDeath(Console c) {
	c.onRefresh = handleYesNoDialog(world.player.causeOfDeath.longDesc, (c, choice) {
		if (choice) {
			c.onRefresh = handleGravestone;
		} else {
			c.onRefresh = handleLoadGame(c, handlePlayerDeath);
		}
	}, "Accept Death", "Turn Back Time");
	c.refresh();
}

void handleGravestone(Console c) {
	int graveWidth = c.width - 4;
	int graveTopWidth = graveWidth - 8;
	
	c.labels.add(new ConsoleLabel((c.width-graveTopWidth)~/2, 2, repeatString("-", graveTopWidth-1), ConsoleColor.GREY));
	
	for (int i = 3; i <= 6; i++) {
		c.labels.add(new ConsoleLabel((c.width-graveTopWidth)~/2 - (i-2), i, "/", ConsoleColor.GREY));
		c.labels.add(new ConsoleLabel(graveTopWidth + (c.width-graveTopWidth)~/2 + (i-4), i, "\\", ConsoleColor.GREY));
	}
	
	for (int i = 7; i <= c.height - 4; i++) {
		c.labels.add(new ConsoleLabel(2, i, "|", ConsoleColor.GREY));
		c.labels.add(new ConsoleLabel(c.width-4, i, "|", ConsoleColor.GREY));
	}
	
	c.labels.add(new ConsoleLabel(0, c.height - 3, repeatString("-", c.width), ConsoleColor.GREEN));
	
	Random rng = new Random(world.player.hashCode);
	
	String hereLies = "HERE LIES";
	String playerName = world.player.name;
	String cause = world.player.causeOfDeath.shortDesc;
	String lifespan = "Survived ${world.day} days,";
	String score = "and earned ${world.player.score} points.";
	String epitaph = "\"${world.player.causeOfDeath.epitaphs[rng.nextInt(world.player.causeOfDeath.epitaphs.length)]}\"";
	String toMainMenu = "ENTER) Continue";
	
	c.labels.add(new ConsoleLabel(c.centerJustified(hereLies), 8, hereLies));
	c.labels.add(new ConsoleLabel(c.centerJustified(playerName), 9, playerName));
	c.labels.add(new ConsoleLabel(c.centerJustified(cause), 11, cause));
	c.labels.add(new ConsoleLabel(c.centerJustified(lifespan), 12, lifespan));
	c.labels.add(new ConsoleLabel(c.centerJustified(score), 13, score));
	c.labels.add(new ConsoleLabel(c.centerJustified(epitaph), 15, epitaph));
	
	c.labels.add(new ConsoleLink(c.centerJustified(toMainMenu), c.height-1, toMainMenu, ConsoleKeyCode.ANY, (c, l) {
		c.onRefresh = handleTitleScreen;
	}));
}