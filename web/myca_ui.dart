import 'myca_core.dart';
import 'myca_console.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_entities.dart';

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
	
	c.labels.add(new ConsoleLabel(c.centerJustified(intro), 1, intro));
	c.labels.addAll(new ConsoleLabel(c.width~/2 - 20, 3, logo).as2DLabel());
	c.labels.add(new ConsoleLink(c.centerJustified(newGame), 16, newGame, "1", (c, link) {
		Player player = new Player();
		player.name = "Bungus";
		
		world = new World(player);
		c.onRefresh = handleTileView;
	}));
}

String dialogText;

void handleTileView(Console c) {
	/// gather possible actions for the action bar
	List<ConsoleLink> actions = new List<ConsoleLink>();
	
	for (Feature f in world.player.tile.features) {
		f.addActions(actions);
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
	c.labels.add(new ConsoleLink(c.width-6, 0,  "?) MAP ", "?", (c, l) {}));
	c.labels.add(new ConsoleLabel(c.width-6, 1, "+-----+"));
	c.labels.add(new ConsoleLabel(c.width-6, 2, "|.....|"));
	c.labels.add(new ConsoleLabel(c.width-6, 3, "|.....|"));
	c.labels.add(new ConsoleLabel(c.width-6, 4, "|..@..|"));
	c.labels.add(new ConsoleLabel(c.width-6, 5, "|.....|"));
	c.labels.add(new ConsoleLabel(c.width-6, 6, "|.....|"));
	c.labels.add(new ConsoleLabel(c.width-6, 7, "+-----+"));
	
	/// display the movement compass
	c.labels.add(new ConsoleLink(c.width-3, 9,  "^", 38, (c, l) {}));
	c.labels.add(new ConsoleLink(c.width-5, 10, "<", 37, (c, l) {}));
	c.labels.add(new ConsoleLink(c.width-3, 10, ".", ".".codeUnitAt(0), (c, l) {}));
	c.labels.add(new ConsoleLink(c.width-1, 10, ">", 39, (c, l) {}));
	c.labels.add(new ConsoleLink(c.width-3, 11, "V", 40, (c, l) {}));
	
	/// display the status HUD
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 0,  world.player.name));
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 1,  "HP: 100/100"));
	c.labels.add(new ConsoleLabel(actionsMaxLen+4, 2,  "Hunger: 0%"));
	
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 0,  world.player.tile.biome.name));
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 1,  "Light: Bright"));
	c.labels.add(new ConsoleLabel(actionsMaxLen+22, 2,  "Time: Day"));
	
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
	
	if (dialogText != null) {
		// display dialog
		c.labels.addAll(new ConsoleLabel(boxX+1, boxY+1, fitToWidth(dialogText, boxW-2)).as2DLabel());
		c.labels.add(new ConsoleLink(boxX+1, boxY+boxH-2, "ENTER) OK", 13, (c, l) {
			dialogText = null;
		}));
	} else {
		// display ACSII art
		world.player.tile.drawPicture(c, boxX+1, boxY+1, boxW-2, boxH-2);
	}
}