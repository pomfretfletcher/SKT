@tool
@icon("res://addons/at-icons/node/signal.svg")
class_name SKT_TreeUpdateSignaller
extends Node

@export var _can_update := true
@export var tree: SKT_Tree
var _timer: float = 0.0
var update_interval: float = 0.1


func _ready() -> void:
	await tree.tree_setup
	tree.request_toggle_tree_updating.connect(
		func(active: bool):
			_can_update = active
	)
	if SKT.current_use_screen == SKT.EditorScreen.SCREEN_2D and tree == SKT.screen_2D_tree:
		_can_update = true
	elif SKT.current_use_screen == SKT.EditorScreen.SCREEN_SKT and tree == SKT.screen_SKT_tree:
		_can_update = true


func _process(delta: float) -> void:
	if not _can_update:
		return

	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		tree.update_tree.emit()
