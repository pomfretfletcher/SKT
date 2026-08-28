@tool
@icon("res://addons/at-icons/node/arrow_up_from_line.svg")
class_name SKT_SkillProgressor
extends Node

@export var tree: SKT_Tree

func _ready() -> void:
	tree.request_progress_skill.connect(request_progress_skill)


func request_progress_skill(node: SkillNode):
	if node.can_be_progressed and not node.is_completed():
		var previous_state: bool = node.is_unlocked()
		tree.upgrade_cost_manager.purchase_unlock_cost(node.unlock_type._decide_single_upgrade_point_cost())
		node.unlock_type._progress_skill()

		# Emit event to signal skill has progressed
		node.skill_progressed.emit()

		# If wasn't unlocked, but now is, emit that event
		if previous_state != node.is_unlocked():
			node.skill_unlocked.emit()
		# If now fully unlocked, emit that event
		if node.is_completed():
			node.skill_completed.emit()
