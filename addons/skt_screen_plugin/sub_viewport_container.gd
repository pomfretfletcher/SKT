@tool
extends SubViewportContainer

@export var tree_parent: Control

func _gui_input(event: InputEvent) -> void:
	tree_parent.gui_input.emit(event)
