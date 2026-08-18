@tool
@icon("res://addons/at-icons/node/signal.svg")
class_name SKT_TreeUpdateSignaller
extends Node

@export var _can_update := true
var _timer: float = 0.0
var update_interval: float = 0.1


func _ready() -> void:
	if Engine.is_editor_hint():
		await SkillTreeEvents.tree_setup
	SkillTreeRequests.request_toggle_tree_updating.connect(
		func(active: bool):
			_can_update = active
	)


func _process(delta: float) -> void:
	if not _can_update:
		return

	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		SkillTreeEvents.update_tree.emit()
