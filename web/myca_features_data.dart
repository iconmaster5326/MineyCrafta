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
	ConsoleColor trunkColor;
	ConsoleColor leavesColor;
	
	TreeBreed(this.name, {this.trunkColor:  ConsoleColor.MAROON, this.leavesColor:  ConsoleColor.LIME});
}

Map<String, TreeBreed> treeBreeds = {
	"Oak": new TreeBreed("Oak"),
	"Birch": new TreeBreed("Birch", trunkColor: ConsoleColor.SILVER),
};

class FeatureTypeTrees extends FeatureType {
	FeatureTypeTrees() {
		name = "Trees";
	}
}

class FeatureTrees extends Feature {
	TreeBreed breed;
	int numTrees;
	
	FeatureTrees(Tile tile, this.breed, this.numTrees) : super(tile) {
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
}