class_name UserSettings
extends RefCounted
## Player preferences, kept in user://settings.cfg. Plain class with static functions,
## not an autoload (same shape as Records). Every setter applies the value and saves.
## [audio] master / music / sfx: floats 0..1.  [display] fullscreen: bool.

const PATH := "user://settings.cfg"
const VOLUME_DEFAULTS := {"master": 1.0, "music": 0.7, "sfx": 1.0}
## The "Effects" slider drives the SFX bus.
const VOLUME_BUSES := {"master": ["Master"], "music": ["Music"], "sfx": ["SFX"]}
const MUTE_BELOW := 0.001
const SILENT_LINEAR := 0.0001   # -80 dB; keeps linear_to_db() away from -inf

static var _cfg: ConfigFile   # loaded once, so sliders don't re-read the file


## Applies everything that is saved. GameManager calls this once at boot.
static func apply() -> void:
	for key: String in VOLUME_BUSES:
		_apply_volume(key)
	# Boot only ever switches *to* fullscreen: a windowed preference leaves the
	# project's own window mode alone. Browsers refuse fullscreen without a user
	# gesture, so on Web it waits for the toggle.
	if is_fullscreen() and not OS.has_feature("web"):
		_apply_fullscreen(true)


static func get_volume(key: String) -> float:
	var value := float(_config().get_value("audio", key, VOLUME_DEFAULTS.get(key, 1.0)))
	return clampf(value, 0.0, 1.0)


static func set_volume(key: String, value: float) -> void:
	if not VOLUME_BUSES.has(key):
		push_warning("UserSettings: unknown volume key '%s'" % key)
		return
	_config().set_value("audio", key, clampf(value, 0.0, 1.0))
	_apply_volume(key)
	_save()


## The saved preference. The real window can differ (a browser leaves fullscreen
## on its own); see window_is_fullscreen().
static func is_fullscreen() -> bool:
	return bool(_config().get_value("display", "fullscreen", false))


static func set_fullscreen(on: bool) -> void:
	_config().set_value("display", "fullscreen", on)
	_apply_fullscreen(on)
	_save()


static func window_is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


static func _apply_volume(key: String) -> void:
	var value := get_volume(key)
	for bus_name: String in VOLUME_BUSES[key]:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			push_warning("UserSettings: audio bus '%s' not found" % bus_name)
			continue
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, SILENT_LINEAR)))
		AudioServer.set_bus_mute(index, value <= MUTE_BELOW)


static func _apply_fullscreen(on: bool) -> void:
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif window_is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


static func _config() -> ConfigFile:
	if _cfg == null:
		_cfg = ConfigFile.new()
		if FileAccess.file_exists(PATH):
			var err := _cfg.load(PATH)
			if err != OK:
				push_warning("UserSettings: could not read %s (error %d)" % [PATH, err])
	return _cfg


static func _save() -> void:
	var err := _config().save(PATH)
	if err != OK:
		push_warning("UserSettings: could not save %s (error %d)" % [PATH, err])
