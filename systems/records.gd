class_name Records
extends RefCounted
## Per-level best time and best (lowest) max detection, kept in user://best.cfg.
## Plain class with static functions, not an autoload. Section = level id, keys `time`, `detection`.

const PATH := "user://best.cfg"
const NONE := -1.0   # value when no best is stored yet


## Returns {"time": float, "detection": float}; NONE (-1.0) when nothing is stored.
static func load_best(level_id: String) -> Dictionary:
	var cfg := _load()
	return {
		"time": float(cfg.get_value(level_id, "time", NONE)),
		"detection": float(cfg.get_value(level_id, "detection", NONE)),
	}


## Stores `time` / `detection` for the level when they beat the saved values.
## Returns the resulting bests plus `new_time` / `new_detection` flags.
static func save_if_better(level_id: String, time: float, detection: float) -> Dictionary:
	var cfg := _load()
	var best_time := float(cfg.get_value(level_id, "time", NONE))
	var best_detection := float(cfg.get_value(level_id, "detection", NONE))
	var new_time := best_time < 0.0 or time < best_time
	var new_detection := best_detection < 0.0 or detection < best_detection
	if new_time:
		best_time = time
		cfg.set_value(level_id, "time", time)
	if new_detection:
		best_detection = detection
		cfg.set_value(level_id, "detection", detection)
	if new_time or new_detection:
		var err := cfg.save(PATH)
		if err != OK:
			push_warning("Records: could not save %s (error %d)" % [PATH, err])
	return {
		"time": best_time,
		"detection": best_detection,
		"new_time": new_time,
		"new_detection": new_detection,
	}


## Forgets every stored best (all levels). Debug key 9 calls this.
static func clear_all() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var err := DirAccess.remove_absolute(PATH)
	if err != OK:
		push_warning("Records: could not delete %s (error %d)" % [PATH, err])


static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(PATH):
		var err := cfg.load(PATH)
		if err != OK:
			push_warning("Records: could not read %s (error %d)" % [PATH, err])
	return cfg
