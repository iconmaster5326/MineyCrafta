import 'myca_core.dart';
import 'myca_items.dart';
import 'myca_entities.dart';
import 'myca_console.dart';
import 'myca_worldgen.dart';
import 'myca_gamesave.dart';

import 'myca_biomes_data.dart';

/// A tile represents a location the player can be located in.
class Tile {
	World world;
	/// Every tile can have features added onto it, such as trees, buildings, torches, etc.
	List<Feature> features = new List<Feature>();
	List<Entity> entities = new List<Entity>();
	/// The light level. 0 is completely dark, 1 is compltetley light.
	double baseLight;
	double get light {
		double sum = baseLight;
		for (Feature f in features) {
			sum += f.lightProvided;
		}
		return sum;
	}
	/// A tile only has so much room for features.
	int maxFeatureSpace = 20;
	int get featureSpace {
		int sum = 0;
		for (Feature f in features) {
			sum += f.space;
		}
		return sum;
	}
	/// Some features can only be placed outdoors or underground.
	bool outdoors;
	bool underground;
	/// Some tiles allow you enter or exit them, or go up or down... Anything that's not a WorldTile can use these.
	Tile customUp;
	Tile customDown;
	/// Tiles can provide custom actions.
	void addActions(List<ConsoleLink> actions) {}
	
	/// These properties will delegate to the enclosing WorldTile.
	int x; int y;
	Biome biome;
	
	int timeAtLastVisit;
	Tile(this.world) {
		timeAtLastVisit = world.time;
	}
	Tile.raw();
	
	/// draws the ASCII art box.
	void drawPicture(Console c, int x, int y, int w, int h) {}
	void drawBattlePicture(Console c, int x, int y, int w, int h) {}
	
	// ALWAYS override this. Set "class" to your class name, so it can be loaded later.
	void save(Map<String, Object> json) {
		throw new UnimplementedError("This subclass of Tile did not implement a save handler.");
	}
	void load(World world, Map<String, Object> json) {
		throw new UnimplementedError("This subclass of Tile did not implement a load handler.");
	}
	
	/// This is called when an encounter happens on this tile.
	List<List<Entity>> randomEncounter() {
		List<List<Entity>> enemies = [];
		enemies.add(new List.generate(rng.nextInt(3)+1, (i) => new EntityZombie()));
		enemies.add(new List.generate(rng.nextInt(3), (i) => new EntityZombie()));
		enemies.add(new List.generate(rng.nextInt(2), (i) => new EntityZombie()));
		return enemies;
	}
}

/// A WorldTile is a Tile on the world map. It has a coordinate, biome, etc.
class WorldTile extends Tile {
	WorldTile(World world, int nx, int ny, Biome nbiome) : super(world) {
		x = nx; y = ny; biome = nbiome;
	}
	
	double get baseLight => world.naturalLight;
	
	@override
	void drawPicture(Console c, int x, int y, int w, int h) {
		c.labels.add(new ConsoleLabel(x, y + h~/2 - 1, repeatString("-", w), biome.groundColor));
		for (int row = y + h~/2; row < y + h; row++) {
			c.labels.add(new ConsoleLabel(x, row, repeatString(".", w), biome.groundColor));
		}
		
		for (Feature f in features) {
			f.drawPicture(c, x, y, w, h);
		}
		
		c.labels.add(new ConsoleLabel(x + w~/2, y + h*3~/4, "@"));
	}
	
	@override
	void drawBattlePicture(Console c, int x, int y, int w, int h) {
		for (int row = y; row < y + h; row++) {
			c.labels.add(new ConsoleLabel(x, row, repeatString(".", w), biome.groundColor));
		}
	}
	
	get mapIcon {
		for (Feature f in features) {
			ConsoleLabel icon = f.mapIcon;
			if (icon != null) {
				return icon;
			}
		}
		
		return new ConsoleLabel(0, 0, ".", biome.groundColor);
	}
	
	@override
	void save(Map<String, Object> json) {
		json["class"] = "WorldTile";
		json["biome"] = biome.name;
	}
	@override
	void load(World world, Map<String, Object> json) {
		biome = biomes[json["biome"]];
	}
	
	WorldTile.raw() : super.raw();
	static Tile loadClass(World world, Map<String, Object> json) {
		return new WorldTile.raw();
	}
	
	bool get outdoors => true;
	bool get underground => false;
}

/// A FeatureTile is a Tile inside of a Feature.
class FeatureTile extends Tile {
	Feature feature;
	
	FeatureTile(this.feature) : super(feature.tile.world);
	FeatureTile.raw() : super.raw();
	
	int get x => feature.tile.x;
	void set x(int value) {feature.tile.x = value;}
	int get y => feature.tile.y;
	void set y(int value) {feature.tile.y = value;}
	Biome get biome => feature.tile.biome;
	void set biome(Biome value) {feature.tile.biome = value;}
	
	bool get outdoors => false;
	bool get underground => false;
}

/// A biome is a world tile's biome, such as desert, forest, etc.
class Biome {
	String name;
	ConsoleColor groundColor;
	
	void generate(WorldTile tile) {}
}

/// This represents a feature instance in the world.
class Feature {
	String name;
	/// This is the tile the feature is INSIDE.
	Tile tile;
	/// The space this tile uses up.
	int space = 0;
	
	/// For the inspect view, features can have colors and descriptions.
	ConsoleColor color;
	String desc;
	
	/// A Recipe telling us how we can deconstruct this feature. Null if non-deconstructable.
	DeconstructionRecipe toDeconstruct;
	
	/// A Feauture can provide light to the tile it's in.
	double lightProvided = 0.0;
	
	Feature.raw();
	Feature(this.tile) {
		tile.features.add(this);
	}
	
	void onTick(Console c, int delta) {}
	void addActions(List<ConsoleLink> actions) {}
	// draws inside the ASCII art box.
	void drawPicture(Console c, int x, int y, int w, int h) {}
	// If not NULL, overrides the icon on the map.
	get mapIcon => null as ConsoleLabel;
	
	// ALWAYS override this. Set "class" to your class name, so it can be loaded later.
	void save(Map<String, Object> json) {
		throw new UnimplementedError("This subclass of Feature did not implement a save handler.");
	}
	void load(World world, Tile tile, Map<String, Object> json) {
		throw new UnimplementedError("This subclass of Feature did not implement a load handler.");
	}
}