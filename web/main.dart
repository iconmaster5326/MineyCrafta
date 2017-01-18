import 'myca_core.dart';
import 'myca_console.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_entities.dart';

World world;

void main() {
	Console c = new Console(handleTitleScreen);
}

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
  \____|_| \_/_/   \_|_|     |_/_/   \_\                                        
	""";
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

void handleTileView(Console c) {
	c.labels.add(new ConsoleLabel(0, 0, world.player.name));
	c.labels.add(new ConsoleLabel(0, 1, world.player.tile.biome.name));
	c.labels.add(new ConsoleLabel(0, 2, world.player.tile.x.toString()));
	c.labels.add(new ConsoleLabel(0, 3, world.player.tile.y.toString()));
}
