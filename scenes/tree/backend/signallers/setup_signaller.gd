@tool
@icon("res://addons/at-icons/node/signal.svg")
class_name SKT_SetupSignaller
extends Node

@export var tree: SKT_Tree

func _ready() -> void:
	tree.data_loaded.connect(emit_tree_setup)


func emit_tree_setup():
	await get_tree().create_timer(2.0).timeout
	tree.tree_setup.emit()
