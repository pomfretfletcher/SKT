@tool
class_name SKT_TreeDrawer
extends Node

@export var _can_draw: bool = true
var _prev_state: bool = true

var draw_interval: float = 0.01


func _ready() -> void:
	if Engine.is_editor_hint():
		await SkillTreeEvents.tree_setup
	SkillTreeRequests.request_toggle_tree_drawing.connect(
		func(active: bool):
			_can_draw = active
	)
	draw()


func _process(_delta: float) -> void:
	if _can_draw and _can_draw != _prev_state:
		_prev_state = _can_draw
		draw()
	if not _can_draw and _can_draw != _prev_state:
		_prev_state = _can_draw


func draw() -> void:
	while _can_draw:
		if get_tree():
			await get_tree().create_timer(draw_interval).timeout
			SkillTreeEvents.draw_tree.emit()
