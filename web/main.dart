import 'myca_core.dart';
import 'myca_console.dart';

String intro = "Iconmaster presents...";
String logo = r"""
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
String newGame = "1) New Game";

void main() async {
	Console c = new Console((c) {
		c.labels.add(new ConsoleLabel(c.centerJustified(intro), 1, intro));
		c.labels.addAll(new ConsoleLabel(c.width/2 - 20, 3, logo).as2DLabel());
		c.labels.add(new ConsoleLink(c.centerJustified(newGame), 16, newGame, "1", (c, link) {
			
		}));
	});
}
