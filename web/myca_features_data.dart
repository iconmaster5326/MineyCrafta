import 'dart:math';

import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_items.dart';
import 'myca_entities.dart';
import 'myca_console.dart';
import 'myca_ui.dart';

/*
Trees
*/

class TreeBreed {
	String name;
	
	TreeBreed(this.name);
}

Map<String, TreeBreed> treeBreeds = {
	"Oak": new TreeBreed("Oak"),
	"Birch": new TreeBreed("Birch"),
};

class FeatureTypeTrees extends FeatureType {
	FeatureTypeTrees() {
		name = "Trees";
	}
}

class FeatureTrees extends Feature {
	TreeBreed breed;
	int numTrees = rng.nextInt(8)+1;
	
	FeatureTrees(Tile tile, this.breed) : super(tile) {
		featureType = new FeatureTypeTrees();
		name = breed.name + " Trees";
	}
	
	@override
	void addActions(List<ConsoleLink> actions) {
		actions.add(new ConsoleLink(0, 0, "Cut Down " + name, null, (c, l) {
			dialogText = "You cut down some of the trees around you. Soon, you manage to gather:\n4 wood\n5 saplings";
		}));
	}
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		Random treeRng = new Random(w * h);
		for (int tree = 0; tree < numTrees; tree++) {
			int treeX = treeRng.nextInt(w) - w~/2;
			int treeY = treeRng.nextInt(h~/2);
			
			for (int i = 0; i < 4; i++) {
				int realX = x + w~/2 + treeX;
				int realY = y + h~/2 + treeY + i - 3;
				
				if (realX >= x && realX < x + w && realY >= y && realY < y + h) {
					switch (i) {
						case 0: c.labels.add(new ConsoleLabel(realX, realY, "+-+")); break;
						case 1: c.labels.add(new ConsoleLabel(realX, realY, "+-+")); break;
						case 2: c.labels.add(new ConsoleLabel(realX + 1, realY, "|")); break;
						case 3: c.labels.add(new ConsoleLabel(realX + 1, realY, "|")); break;
					}
				}
			}
		}
	}
}