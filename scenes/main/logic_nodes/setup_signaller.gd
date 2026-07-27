@tool
class_name SKT_SetupSignaller
extends Node

func _ready() -> void:
	SkillTreeEvents.data_loaded.connect(emit_tree_setup)
	emit_tree_setup()


func emit_tree_setup():
	await get_tree().create_timer(2.0).timeout
	SkillTreeEvents.tree_setup.emit()
