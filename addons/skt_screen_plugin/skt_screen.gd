@tool
extends EditorPlugin

var screen_pscene: PackedScene = load("uid://b5ji5dg3uh8yk")
var screen: SKT

var editor_screen: String
var editor_scene: Node


func _enter_tree() -> void:
	screen = screen_pscene.instantiate() as SKT
	EditorInterface.get_editor_main_screen().add_child(screen)
	_make_visible(false)
	screen.request_refresh_screen.connect(refresh_screen)

	main_screen_changed.connect(handle_main_screen_changed)
	scene_changed.connect(handle_scene_changed)


func refresh_screen():
	screen.queue_free()
	await get_tree().create_timer(0.1).timeout
	screen = screen_pscene.instantiate() as SKT
	EditorInterface.get_editor_main_screen().add_child(screen)
	screen.request_refresh_screen.connect(refresh_screen)


func handle_main_screen_changed(screen: String):
	editor_screen = screen

	if screen == "2D":
		SKT.current_use_screen = SKT.EditorScreen.SCREEN_2D
	elif screen == "SKT":
		SKT.current_use_screen = SKT.EditorScreen.SCREEN_SKT
	else:
		SKT.current_use_screen = SKT.EditorScreen.SCREEN_OTHER

	if editor_scene is SKT_Tree and screen == "2D":
		if SKT.screen_2D_tree != null:
			SKT.screen_2D_tree.request_toggle_tree_drawing.emit(true)
			SKT.screen_2D_tree.request_toggle_tree_updating.emit(true)
	elif screen == "SKT":
		if SKT.screen_SKT_tree != null:
			SKT.screen_SKT_tree.request_toggle_tree_drawing.emit(true)
			SKT.screen_SKT_tree.request_toggle_tree_updating.emit(true)
	else:
		if SKT.screen_2D_tree != null:
			SKT.screen_2D_tree.request_toggle_tree_drawing.emit(false)
			SKT.screen_2D_tree.request_toggle_tree_updating.emit(false)
		if SKT.screen_SKT_tree != null:
			SKT.screen_SKT_tree.request_toggle_tree_drawing.emit(false)
			SKT.screen_SKT_tree.request_toggle_tree_updating.emit(false)
			

func handle_scene_changed(scene: Node):
	if editor_scene is SKT_Tree and editor_screen == "":
		editor_screen = "2D"

	if scene is SKT_Tree:
		SKT.screen_2D_tree = scene
	editor_scene = scene
	
	if scene is SKT_Tree and editor_screen == "2D":
		if SKT.screen_2D_tree != null:
			SKT.screen_2D_tree.request_toggle_tree_drawing.emit(true)
			SKT.screen_2D_tree.request_toggle_tree_updating.emit(true)
	elif editor_screen == "SKT":
		pass
	else:
		if SKT.screen_2D_tree != null:
			SKT.screen_2D_tree.request_toggle_tree_drawing.emit(false)
			SKT.screen_2D_tree.request_toggle_tree_updating.emit(false)
		if SKT.screen_SKT_tree != null:
			SKT.screen_SKT_tree.request_toggle_tree_drawing.emit(false)
			SKT.screen_SKT_tree.request_toggle_tree_updating.emit(false)


func _exit_tree() -> void:
	screen.free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible):
	if screen:
		screen.visible = visible


func _get_plugin_name() -> String:
	return "SKT"


func _get_plugin_icon():
	return load("res://addons/at-icons/node/node_graph.svg")
