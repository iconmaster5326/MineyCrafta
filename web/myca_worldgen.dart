import 'dart:math';

import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_entities.dart';

import 'myca_biomes_data.dart';

class World {
	int size;
	Map<Point<int>, WorldTile> tiles = new Map<Point<int>, WorldTile>();
	Player player;
	Random worldRng;
	int seed;
	
	World(this.player, [this.size = 16, this.seed]) {
		Biome b = new BiomeForest();
		
		if (seed == null) {
			seed = rng.nextInt(100000000);
		}
		worldRng = new Random(seed);
		
		for (int x = 0; x < size; x++) {
			for (int y = 0; y < size; y++) {
				WorldTile t = new WorldTile(this, x, y, b);
				tiles[new Point(x,y)] = t;
				b.generate(t);
			}
		}
		
		player.move(tiles[new Point(size~/2, size~/2)]);
	}
}