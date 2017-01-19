import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_items.dart';
import 'myca_entities.dart';

import 'myca_features_data.dart';
import 'myca_item_data.dart';

class BiomeForest extends Biome {
	BiomeForest() {
		name = "Forest";
	}
	
	@override
	void generate(WorldTile tile) {
		new FeatureTrees(tile, treeBreeds["Oak"]);
	}
}