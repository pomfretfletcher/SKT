@tool
@icon("res://addons/at-icons/node/signal.svg")
class_name SKT_TreeDrawSignaller
extends Node

@export var _can_draw := true
var _timer: float = 0.0
var draw_interval: float = 0.01


func _ready() -> void:
	if Engine.is_editor_hint():
		await SkillTreeEvents.tree_setup
	SkillTreeRequests.request_toggle_tree_drawing.connect(
		func(active: bool):
			_can_draw = active
	)


func _process(delta: float) -> void:
	if not _can_draw:
		return

	_timer += delta
	if _timer >= draw_interval:
		_timer = 0.0
		SkillTreeEvents.draw_tree.emit()
