extends Node
## Scene flow: menu <-> levels. Owns the level list; nobody else hardcodes scene paths.

const LEVELS := {
	"tutorial": "res://scenes/test_world.tscn",   # Katya's real level replaces this later
}
const LEVEL_ORDER := ["tutorial"]   # "master" gets appended when Katya's level lands
const MENU_SCENE := "res://ui/screens/main_menu.tscn"

var current_level_id: String = "tutorial"


func start_level(id: String) -> void:
	if not LEVELS.has(id):
		push_error("SceneManager: unknown level id '%s'" % id)
		return
	current_level_id = id
	GameManager.reset()
	_change_scene_deferred.call_deferred(LEVELS[id])


## reset() first (un-pauses, sets PLAYING, emits run_reset), then reload, so the
## new scene's _ready() sees a clean GameManager. Deferred: callers are button
## signals and nodes inside the tree being torn down.
func restart_level() -> void:
	GameManager.reset()
	_reload_deferred.call_deferred()


func has_next_level() -> bool:
	return current_level_id != LEVEL_ORDER.back()


func next_level() -> void:
	if has_next_level():
		start_level(LEVEL_ORDER[LEVEL_ORDER.find(current_level_id) + 1])
	else:
		go_to_menu()


func go_to_menu() -> void:
	GameManager.enter_menu()
	_change_scene_deferred.call_deferred(MENU_SCENE)


func _change_scene_deferred(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _reload_deferred() -> void:
	get_tree().reload_current_scene()
