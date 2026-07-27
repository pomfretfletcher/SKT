@tool
class_name SKT_TreeUpdator
extends Node

@export var can_update: bool = true
var prev_state: bool = true

var update_interval: float = 0.1


func _ready() -> void:
	await SkillTreeEvents.tree_setup
	SkillTreeEvents.toggle_updating.connect(
		func(active):
			can_update = active
	)
	update()


func _process(_delta: float) -> void:
	if can_update and can_update != prev_state:
		prev_state = can_update
		update()
	if !can_update and can_update != prev_state:
		prev_state = can_update


func update() -> void:
	while can_update:
		if get_tree():
			await get_tree().create_timer(update_interval).timeout
			SkillTreeEvents.update_tree.emit()
