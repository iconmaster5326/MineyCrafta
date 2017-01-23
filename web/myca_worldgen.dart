import 'dart:math';

import 'myca_core.dart';
import 'myca_world.dart';
import 'myca_entities.dart';
import 'myca_console.dart';

import 'myca_biomes_data.dart';

class VoronoiGrid<T> {
	List<Point<int>> points;
	List<T> data;
	
	VoronoiGrid(Random rng, int size, int n, Function generator) {
		points = new List.generate(n, (i) => new Point<int>(rng.nextInt(size), rng.nextInt(size)));
		data = new List.generate(n, (i) => generator(points[i]));
	}
	
	double distance(Point<int> a, Point<int> b) => sqrt((a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y));
	
	T operator [](Point<int> target) {
		T minData;
		double minDist;
		
		int i = 0;
		for (Point pt in points) {
			if (minDist == null || distance(target, pt) < minDist) {
				minDist = distance(target, pt);
				minData = data[i];
			}
			i++;
		}
		
		return minData;
	}
}

class World {
	int size;
	Map<Point<int>, WorldTile> tiles = new Map<Point<int>, WorldTile>();
	Player player;
	Random worldRng;
	int seed;
	int time = 0;
	
	static const int TICKS_PER_DAY = 500;
	
	World(this.player, [this.size = 16, this.seed]) {
		if (seed == null) {
			seed = rng.nextInt(100000000);
		}
		worldRng = new Random(seed);
		
		VoronoiGrid<Biome> biomeMap = new VoronoiGrid<Biome>(worldRng, size, size*size~/10, (pt) =>
			new List.from(biomes.values)[worldRng.nextInt(biomes.length)]
		);
		
		for (int x = 0; x < size; x++) {
			for (int y = 0; y < size; y++) {
				WorldTile t = new WorldTile(this, x, y, biomeMap[new Point<int>(x, y)]);
				tiles[new Point(x,y)] = t;
				t.biome.generate(t);
			}
		}
		
		player.move(tiles[new Point(size~/2, size~/2)]);
	}
	World.raw();
	
	bool get isDaytime => (time % TICKS_PER_DAY / TICKS_PER_DAY < .5);
	int get day => time ~/ TICKS_PER_DAY;
	double get naturalLight {
		double timeInDay = time % TICKS_PER_DAY / TICKS_PER_DAY;
		if (timeInDay < .5) {
			return 1.0;
		} else if (timeInDay < .6) {
			return 0.4;
		} else if (timeInDay < .9) {
			return 0.2;
		} else {
			return 0.4;
		}
	}
	
	String lightDescriptor(double n) {
		if (n < .25) {
			return "Dark";
		} else if (n < .5) {
			return "Dim";
		} else {
			return "Bright";
		}
	}
	String timeDescriptor() {
		double timeInDay = time % TICKS_PER_DAY / TICKS_PER_DAY;
		if (timeInDay < .5) {
			return "Day";
		} else if (timeInDay < .6) {
			return "Dusk";
		} else if (timeInDay < .9) {
			return "Night";
		} else {
			return "Dawn";
		}
	}
	
	void passTime(Console c, [int amt = 1]) {
		// call onTick...
		for (Feature f in player.tile.features) {
			f.onTick(c, amt);
		}
		for (Entity e in player.tile.entities) {
			e.onTick(c, amt);
		}
		
		time += amt;
		player.tile.timeAtLastVisit = time;
	}
}