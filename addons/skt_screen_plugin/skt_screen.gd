@tool
extends EditorPlugin

var screen_pscene: PackedScene = load("uid://b5ji5dg3uh8yk")
var screen: Control


func _enter_tree() -> void:
	screen = screen_pscene.instantiate()
	EditorInterface.get_editor_main_screen().add_child(screen)
	_make_visible(false)

	SKTScreenSignals.refresh_skt_screen.connect(
		func():
			print("Hi")
			screen.free()
			screen = screen_pscene.instantiate()
			EditorInterface.get_editor_main_screen().add_child(screen)
	)


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
