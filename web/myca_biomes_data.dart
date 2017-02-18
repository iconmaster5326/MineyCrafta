import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_items.dart';
import 'myca_entities.dart';
import 'myca_console.dart';
import 'myca_gamesave.dart';

import 'myca_features_data.dart';
import 'myca_item_data.dart';

class BiomeForest extends Biome {
	BiomeForest() {
		name = "Forest";
		groundColor = ConsoleColor.GREEN;
	}
	
	@override
	void generate(WorldTile tile) {
		new FeatureTrees(tile, treeBreeds["Oak"], tile.world.worldRng.nextInt(5)+4);
		new FeatureTrees(tile, treeBreeds["Birch"], tile.world.worldRng.nextInt(5)+4);
		new FeatureGrass(tile);
		
		if (tile.world.worldRng.nextDouble() < .1) {
			new FeatureLake(tile);
		}
	}
}

class BiomeDesert extends Biome {
	BiomeDesert() {
		name = "Desert";
		groundColor = ConsoleColor.OLIVE;
	}
	
	@override
	void generate(WorldTile tile) {
		
	}
}

Map<String, Biome> biomes = {
	"Forest":new BiomeForest(),
	"Desert":new BiomeDesert(),
};