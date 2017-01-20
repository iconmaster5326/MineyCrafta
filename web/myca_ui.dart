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

void handleTileView(Console c) {
	/// gather possible actions for the action bar
	List<ConsoleLink> actions = new List<ConsoleLink>();
	
	actions.add(new ConsoleLink(0, 0, "Inventory", null, (c, l) {
		c.onRefresh = handleInventoryView;
	}));
	actions.add(new ConsoleLink(0, 0, "Look Around", null, (c, l) {
		c.onRefresh = handleInspectView;
	}));
	actions.add(new ConsoleLink(0, 0, "Craft Item", null, (c, l) {
		c.onRefresh = handleCraftItem(c, handRecipes);
	}));
	actions.add(new ConsoleLink(0, 0, "Craft Structure", null, (c, l) {
		c.onRefresh = handleCraftFeature;
	}));
	
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
		link.key = getKeyForInt(i+1).codeUnitAt(0);
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
		c.labels.add(new ConsoleLink(c.width-3, 9,  "^", 38, (c, l) {
			Point<int> pt = new Point<int>(world.player.tile.x, world.player.tile.y-1);
			if (world.tiles[pt] != null) {
				world.player.move(world.tiles[pt]);
				world.passTime(c);
			}
		}));
		c.labels.add(new ConsoleLink(c.width-5, 10, "<", 37, (c, l) {
			Point<int> pt = new Point<int>(world.player.tile.x-1, world.player.tile.y);
			if (world.tiles[pt] != null) {
				world.player.move(world.tiles[pt]);
				world.passTime(c);
			}
		}));
		c.labels.add(new ConsoleLink(c.width-1, 10, ">", 39, (c, l) {
			Point<int> pt = new Point<int>(world.player.tile.x+1, world.player.tile.y);
			if (world.tiles[pt] != null) {
				world.player.move(world.tiles[pt]);
				world.passTime(c);
			}
		}));
		c.labels.add(new ConsoleLink(c.width-3, 11, "V", 40, (c, l) {
			Point<int> pt = new Point<int>(world.player.tile.x, world.player.tile.y+1);
			if (world.tiles[pt] != null) {
				world.player.move(world.tiles[pt]);
				world.passTime(c);
			}
		}));
	} else {
		if (world.player.tile.customUp != null) {
			c.labels.add(new ConsoleLink(c.width-3, 9,  "^", 38, (c, l) {
				world.player.move(world.player.tile.customUp);
				world.passTime(c);
			}));
		}
		
		if (world.player.tile.customDown != null) {
			c.labels.add(new ConsoleLink(c.width-3, 11, "V", 40, (c, l) {
				world.player.move(world.player.tile.customDown);
				world.passTime(c);
			}));
		}
	}
	
	c.labels.add(new ConsoleLink(c.width-3, 10, ".", 190, (c, l) {
		world.passTime(c);
	}));
	
	/// display the status HUD
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 0,  world.player.name));
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 1,  "Health: "+(world.player.hp/world.player.hpMax*100.0).toStringAsFixed(0)+"%"));
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 2,  "Hunger: "+(world.player.hunger/world.player.maxHunger*100.0).toStringAsFixed(0)+"%"));
	
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 0,  world.player.tile.biome.name));
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 1,  "Light: " + world.lightDescriptor(world.player.tile.light)));
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 2,  "Time: " + world.timeDescriptor()));
	
	/// display the picture box
	int boxX = actionsMaxLen+4;
	int boxY = 6;
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
	
	c.labels.add(new ConsoleLink(0, c.height-1, "ENTER) Menu", 13, (c, l) {
		c.onRefresh = handlePauseMenu;
	}));
}

ItemStack selected;
void handleInventoryView(Console c) {
	c.labels.add(new ConsoleLabel(0, 0,  "Your inventory:"));
	
	String sizeText;
	if (world.player.inventory.maxSize == null) {
		sizeText = "Weight: " + world.player.inventory.size.toStringAsFixed(0);
	} else {
		sizeText = "Weight: " + world.player.inventory.size.toStringAsFixed(0) + " / " + world.player.inventory.maxSize.toStringAsFixed(0);
	}
	c.labels.add(new ConsoleLabel(c.rightJustified(sizeText), 0,  sizeText));
	
	int i = 0;
	for (ItemStack stack in world.player.inventory.items) {
		c.labels.add(new ConsoleLink(0, i+2,  getKeyForInt(i+1) + ") " + stack.name, getKeyForInt(i+1), (c, l) {
			selected = stack;
		}, stack.color));
		i++;
	}
	
	c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", 13, (c, l) {
		selected = null;
		c.onRefresh = handleTileView;
	}));
	
	if (selected != null) {
		int selX = c.width ~/ 3;
		int actX = 2*c.width ~/ 3;
		
		c.labels.add(new ConsoleLabel(selX, 2, selected.name, selected.color));
		c.labels.add(new ConsoleLabel(selX, 3, "Weight: " + (selected.size*selected.amt).toString()));
		
		c.labels.addAll(new ConsoleLabel(selX, 5, fitToWidth(selected.desc, actX-selX-2)).as2DLabel());
		
		c.labels.add(new ConsoleLabel(actX, 2, "Actions:"));
		c.labels.add(new ConsoleLink(actX, 3, ",) Discard", 188, (c, l) {
			world.player.inventory.items.remove(selected);
			selected = null;
		}));
	}
}

typedef void NotifyDialogCallback(Console c);
ConsoleRefreshHandler handleNotifyDialog(String message, NotifyDialogCallback onAccept) {
	return (c) {
		c.labels.add(new ConsoleLabel(1, 1,  "+"+repeatString("-", c.width-4)+"+"));
		c.labels.add(new ConsoleLabel(1, c.height-2,  "+"+repeatString("-", c.width-4)+"+"));
		
		for (int i = 2; i < c.height-2; i++) {
			c.labels.add(new ConsoleLabel(1, i, "|"));
			c.labels.add(new ConsoleLabel(c.width-2, i, "|"));
		}
		
		c.labels.addAll(new ConsoleLabel(2, 2, fitToWidth(message, c.width-6)).as2DLabel());
		
		c.labels.add(new ConsoleLink(2, c.height - 3,  "ENTER) OK", ConsoleLink.ANY_KEY, (c, l) {
			onAccept(c);
		}));
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
	c.labels.add(new ConsoleLink(c.centerJustified(ret), c.height-1, ret, 13, (c, l) {
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
		
		c.labels.add(new ConsoleLink(0, c.height-1, "ENTER) Cancel", 13, (c, l) {
			c.onRefresh = onCancel;
		}));
		
		const String delFiles = "DEL) Delete Files";
		c.labels.add(new ConsoleLink(c.rightJustified(delFiles), c.height-1, delFiles, 46, (c, l) {
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
		
		c.labels.add(new ConsoleLink(0, c.height-1, "ENTER) Back", 13, (c, l) {
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
	for (FeatureRecipe recipe in featureRecipes) {
		if (recipe.canMakeOn(world.player.tile)) {
			ConsoleColor color = (recipe.canMake(world.player.inventory) && world.player.tile.featureSpace + recipe.space <= world.player.tile.maxFeatureSpace) ? ConsoleColor.GREEN : ConsoleColor.RED;
			if (recipe == selFeatureRecipe) {
				recipeLabels.add(new ConsoleLabel(0, menuI+2, getKeyForInt(menuI+1) + ") " + recipe.name, color));
				selI = i;
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
			c.labels.add(new ConsoleLink(recipeXMax, y+1, getKeyForInt(selI+1)+") Craft", getKeyForInt(selI+1), (c, l) {
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
			c.labels.add(new ConsoleLabel(recipeXMax, y+1, getKeyForInt(selI+1)+") Craft", ConsoleColor.SILVER));
		}
	}
	
	c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", 13, (c, l) {
		selFeatureRecipe = null;
		c.onRefresh = handleTileView;
	}));
	
	String autocraftString = ".) Autocraft: " + (autocraft ? "ON" : "OFF");
	ConsoleColor autocraftColor = autocraft ? ConsoleColor.GREEN : ConsoleColor.RED;
	c.labels.add(new ConsoleLink(c.rightJustified(autocraftString), c.height - 1,  autocraftString, 190, (c, l) {
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
		
		c.labels.add(new ConsoleLink(0, c.height - 1, "ENTER) Back", 13, (c, l) {
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
		
		c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", 13, (c, l) {
			selItemRecipe = null;
			c.onRefresh = handleTileView;
		}));
		
		String autocraftString = ".) Autocraft: " + (autocraft ? "ON" : "OFF");
		ConsoleColor autocraftColor = autocraft ? ConsoleColor.GREEN : ConsoleColor.RED;
		c.labels.add(new ConsoleLink(c.rightJustified(autocraftString), c.height - 1,  autocraftString, 190, (c, l) {
			autocraft = !autocraft;
		}, autocraftColor));
		
		String factorString = selFactor.toString();
		c.labels.add(new ConsoleLabel(c.centerJustified(factorString), c.height - 1,  factorString));
		c.labels.add(new ConsoleLink(c.width~/2-2, c.height - 1,  "-", 189, (c, l) {
			if (selFactor > 1) {selFactor--;}
		}));
		c.labels.add(new ConsoleLink(c.width~/2+2, c.height - 1,  "+", 187, (c, l) {
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
	
	c.labels.add(new ConsoleLink(0, c.height - 1,  "ENTER) Back", 13, (c, l) {
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
			c.labels.add(new ConsoleLink(actX, 3, ",) Deconstruct", 188, (c, l) {
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