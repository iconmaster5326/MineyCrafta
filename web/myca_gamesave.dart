import 'dart:convert' show JSON;
import 'dart:html';
import 'dart:math';

import 'myca_core.dart';
import 'myca_console.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_entities.dart';
import 'myca_items.dart';

import 'myca_features_data.dart';
import 'myca_item_data.dart';

String lastSavedFile;

void saveToDisk(World world, String saveName) {
	List<String> savedWorlds = getSavedWorlds();
	if (!savedWorlds.contains(saveName)) {
		savedWorlds.add(saveName);
		window.localStorage["myca_saves"] = JSON.encode(savedWorlds);
	}
	
	lastSavedFile = saveName;
	
	Object json = saveWorld(world);
	String jsonString = JSON.encode(json);
	window.localStorage["myca_savefile_" + saveName] = jsonString;
}

World loadFromDisk(String saveName) {
	List<String> savedWorlds = getSavedWorlds();
	if (!savedWorlds.contains(saveName)) {
		throw new ArgumentError("save file does not exist!");
	}
	
	lastSavedFile = saveName;
	
	String jsonString = window.localStorage["myca_savefile_" + saveName];
	Object json = JSON.decode(jsonString);
	return loadWorld(json);
}

List<String> getSavedWorlds() {
	if (window.localStorage["myca_saves"] == null) {
		window.localStorage["myca_saves"] = JSON.encode([]);
	}
	
	return JSON.decode(window.localStorage["myca_saves"]);
}

void deleteSavedWorld(String saveName) {
	List<String> savedWorlds = getSavedWorlds();
	if (!savedWorlds.contains(saveName)) {
		throw new ArgumentError("save file does not exist!");
	}
	savedWorlds.remove(saveName);
	window.localStorage["myca_saves"] = JSON.encode(savedWorlds);
	
	window.localStorage["myca_savefile_" + saveName] = null;
}

Object saveWorld(World world) {
	Map<String, Object> json = {
		"size": world.size,
		"seed": world.seed,
		"time": world.time,
	};
	
	Map<String, Object> mapJson = {}; json["map"] = mapJson;
	
	for (Point<int> pt in world.tiles.keys) {
		mapJson[pt.x.toString()+"_"+pt.y.toString()] = saveTile(world.tiles[pt]);
	}
	
	return json;
}

World loadWorld(Object json) {
	World world = new World.raw();
	world.size = json["size"];
	world.seed = json["seed"]; world.worldRng = new Random(world.seed);
	world.time = json["time"];
	
	for (String key in json["map"].keys) {
		List<String> parts = key.split("_");
		int x = int.parse(parts[0]); int y = int.parse(parts[1]);
		Tile tile = loadTile(world, json["map"][key]);
		tile.x = x; tile.y = y;
		world.tiles[new Point<int>(x, y)] = tile;
	}
	
	return world;
}

Object saveTile(Tile tile) {
	Map<String, Object> json = {
		"timeAtLastVisit": tile.timeAtLastVisit,
	};
	
	List<Object> featuresJson = []; json["features"] = featuresJson;
	for (Feature f in tile.features) {
		featuresJson.add(saveFeature(f));
	}
	
	List<Object> entitiesJson = []; json["entities"] = entitiesJson;
	for (Entity e in tile.entities) {
		entitiesJson.add(saveEntity(e));
	}
	
	tile.save(json);
	
	return json;
}

Tile loadTile(World world, Object json) {
	Tile tile = tileLoadHandlers[json["class"]](world, json);
	tile.world = world;
	
	tile.timeAtLastVisit = json["timeAtLastVisit"];
	for (Object featureJson in json["features"]) {
		tile.features.add(loadFeature(world, tile, featureJson));
	}
	for (Object entityJson in json["entities"]) {
		tile.entities.add(loadEntity(world, tile, entityJson));
	}
	
	tile.load(world, json);
	return tile;
}

Object saveFeature(Feature feature) {
	Map<String, Object> json = {
		"name": feature.name,
	};
	
	feature.save(json);
	
	return json;
}

Feature loadFeature(World world, Tile tile, Object json) {
	Feature feature = featureLoadHandlers[json["class"]](world, tile, json);
	feature.tile = tile;
	
	feature.name = json["name"];
	
	feature.load(world, tile, json);
	return feature;
}

Object saveEntity(Entity entity) {
	Map<String, Object> json = {
		"name": entity.name,
		"hp": entity.hp,
		"hpMax": entity.hpMax,
		"canCarry": entity.inventory.maxSize,
	};
	
	List<Object> itemsJson = []; json["items"] = itemsJson;
	for (ItemStack stack in entity.inventory.items) {
		itemsJson.add(saveItem(stack));
	}
	
	entity.save(json);
	
	return json;
}

Entity loadEntity(World world, Tile tile, Object json) {
	Entity entity = entityLoadHandlers[json["class"]](world, tile, json);
	entity.tile = tile;
	
	entity.name = json["name"];
	entity.hp = json["hp"];
	entity.hpMax = json["hpMax"];
	entity.inventory.maxSize = json["canCarry"];
	
	for (Object itemJson in json["items"]) {
		entity.inventory.add(loadItem(world, entity.inventory, itemJson));
	}
	
	entity.load(world, tile, json);
	return entity;
}

Object saveItem(ItemStack stack) {
	Map<String, Object> json = {
		"amt": stack.amt,
	};
	
	stack.save(json);
	
	return json;
}

ItemStack loadItem(World world, Inventory inventory, Object json) {
	ItemStack stack = itemLoadHandlers[json["class"]](world, inventory, json);
	stack.inventory = inventory;
	
	stack.amt = json["amt"];
	
	stack.load(world, inventory, json);
	
	return stack;
}