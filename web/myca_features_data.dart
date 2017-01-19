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
}