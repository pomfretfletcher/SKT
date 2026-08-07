@tool
class_name SKT_TreeUpdator
extends Node

@export var _can_update: bool = true
var _prev_state: bool = true

var update_interval: float = 0.1


func _ready() -> void:
	if Engine.is_editor_hint():
		await SkillTreeEvents.tree_setup
	SkillTreeRequests.request_toggle_tree_updating.connect(
		func(active: bool):
			_can_update = active
	)
	update()


func _process(_delta: float) -> void:
	if _can_update and _can_update != _prev_state:
		_prev_state = _can_update
		update()
	if not _can_update and _can_update != _prev_state:
		_prev_state = _can_update


func update() -> void:
	while _can_update:
		if get_tree():
			await get_tree().create_timer(update_interval).timeout
			SkillTreeEvents.update_tree.emit()
