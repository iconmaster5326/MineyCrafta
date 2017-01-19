import 'dart:convert' show JSON;
import 'dart:html';

import 'myca_core.dart';
import 'myca_console.dart';
import 'myca_world.dart';
import 'myca_worldgen.dart';
import 'myca_entities.dart';
import 'myca_items.dart';

void saveToDisk(World world) {
	Object json = saveWorld(world);
	String jsonString = JSON.encode(json);
	window.localStorage["world"] = jsonString;
	
	querySelector("body").children.clear();
	querySelector("body").text = jsonString;
}

World loadFromDisk() {
	String jsonString = window.localStorage["world"];
	Object json = JSON.decode(jsonString);
	return loadWorld(json);
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

Tile loadTile(Object json) {
	
}

Object saveFeature(Feature feature) {
	Map<String, Object> json = {
		"name": feature.name,
	};
	
	feature.save(json);
	
	return json;
}

Feature loadFeature(Object json) {
	
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

Entity loadEntity(Object json) {
	
}

Object saveItem(ItemStack stack) {
	Map<String, Object> json = {
		"amt": stack.amt,
	};
	
	stack.save(json);
	
	return json;
}

ItemStack loadItem(Object json) {
	
}