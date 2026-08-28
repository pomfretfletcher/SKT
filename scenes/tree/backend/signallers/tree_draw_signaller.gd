@tool
@icon("res://addons/at-icons/node/signal.svg")
class_name SKT_TreeDrawSignaller
extends Node

@export var _can_draw := true
@export var tree: SKT_Tree
var _timer: float = 0.0
var draw_interval: float = 0.01


func _ready() -> void:
	await tree.tree_setup
	tree.request_toggle_tree_drawing.connect(
		func(active: bool):
			_can_draw = active
	)
	if SKT.current_use_screen == SKT.EditorScreen.SCREEN_2D and tree == SKT.screen_2D_tree:
		_can_draw = true
	elif SKT.current_use_screen == SKT.EditorScreen.SCREEN_SKT and tree == SKT.screen_SKT_tree:
		_can_draw = true


func _process(delta: float) -> void:
	if not _can_draw:
		return

	_timer += delta
	if _timer >= draw_interval:
		_timer = 0.0
		tree.draw_tree.emit()
