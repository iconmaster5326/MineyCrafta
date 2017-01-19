import 'dart:math';

import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_entities.dart';

import 'myca_biomes_data.dart';

class World {
	int size;
	Map<Point<int>, WorldTile> tiles = new Map<Point<int>, WorldTile>();
	Player player;
	
	World(this.player, [this.size = 16]) {
		Biome b = new BiomeForest();
		
		for (int x = 0; x < size; x++) {
			for (int y = 0; y < size; y++) {
				WorldTile t = new WorldTile(x, y, b);
				tiles[new Point(x,y)] = t;
				b.generate(t);
			}
		}
		
		player.move(tiles[new Point(size~/2, size~/2)]);
	}
}