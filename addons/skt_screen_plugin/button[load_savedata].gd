@tool
extends SKT_Button

@export var panel: SKT
@export var tree: SKT_Tree
var tree_scene: PackedScene:
	get:
		return load("uid://b2f11wyd6ktkd")

func _gui_input(event: InputEvent) -> void:
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and can_be_pressed:
		tree.request_load_data.emit()
