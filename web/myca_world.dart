import 'myca_core.dart';
import 'myca_items.dart';
import 'myca_entities.dart';
import 'myca_console.dart';
import 'myca_worldgen.dart';

/// A tile represents a location the player can be located in.
class Tile {
	World world;
	/// Every tile can have features added onto it, such as trees, buildings, torches, etc.
	List<Feature> features = new List<Feature>();
	List<Entity> entities = new List<Entity>();
	/// The light level. 0 is completely dark.
	int light = 0;
	/// A tile only has so much room for features.
	int featureSpace = 0; int maxFeatureSpace = 0;
	
	/// These properties will delegate to the enclosing WorldTile.
	int x; int y;
	Biome biome;
	
	Tile(this.world);
	
	// draws the ASCII art box.
	void drawPicture(Console c, int x, int y, int w, int h) {}
}

/// A WorldTile is a Tile on the world map. It has a coordinate, biome, etc.
class WorldTile extends Tile {
	WorldTile(World world, int nx, int ny, Biome nbiome) : super(world) {
		x = nx; y = ny; biome = nbiome;
	}
	
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
	
	get mapIcon {
		for (Feature f in features) {
			ConsoleLabel icon = f.mapIcon;
			if (icon != null) {
				return icon;
			}
		}
		
		return new ConsoleLabel(0, 0, ".", biome.groundColor);
	}
}

/// A FeatureTile is a Tile inside of a Feature.
class FeatureTile extends Tile {
	Feature feature;
	
	FeatureTile(World world) : super(world);
	
	int get x => feature.tile.x;
	void set x(int value) {feature.tile.x = value;}
	int get y => feature.tile.y;
	void set y(int value) {feature.tile.y = value;}
	Biome get biome => feature.tile.biome;
	void set biome(Biome value) {feature.tile.biome = value;}
}

/// A biome is a world tile's biome, such as desert, forest, etc.
class Biome {
	String name;
	ConsoleColor groundColor;
	
	void generate(WorldTile tile) {}
}

/// This represents a class of features.
class FeatureType {
	String name;
	/// The space required to host this feature.
	int featureSpace = 0;
	
	/// Returns true if this feature can be placed in this tile. Override this for your custom features.
	bool canPlaceIn(Tile tile) {
		return true;
	}
}

/// This represents a feature instance in the world.
class Feature {
	String name;
	/// This is the tile the feature is INSIDE.
	Tile tile;
	FeatureType featureType;
	
	Feature(this.tile) {
		tile.features.add(this);
	}
	
	void addActions(List<ConsoleLink> actions) {}
	// draws inside the ASCII art box.
	void drawPicture(Console c, int x, int y, int w, int h) {}
	// If not NULL, overrides the icon on the map.
	get mapIcon => null as ConsoleLabel;
}