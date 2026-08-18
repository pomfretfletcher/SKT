@tool
@icon("res://addons/at-icons/node/arrow_down_from_line.svg")
class_name SKT_SkillRegressor
extends Node

func _ready() -> void:
	SkillTreeRequests.request_regress_skill.connect(request_regress_skill)


func request_regress_skill(node: SkillNode):
	if node.can_be_regressed and node.is_unlocked():
		node.unlock_type._regress_skill()
		SKT.upgrade_cost_manager.refund_unlock_cost(node.unlock_type._decide_single_upgrade_point_cost())

		# Emit event to signal skill has regressed
		SkillTreeEvents.skill_regressed.emit(node)
		# If regressing has put the skill node down to no longer being unlocked
		if not node.is_unlocked():
			SkillTreeEvents.skill_locked.emit(node)
