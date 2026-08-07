@tool
class_name SKT_SkillProgressor
extends Node

@export_subgroup("Inspector Node References")
@export var upgrade_cost_manager: SKT_UpgradeCostManager


func _ready() -> void:
	SkillTreeRequests.request_progress_skill.connect(request_progress_skill)


func request_progress_skill(node: SkillNode):
	if node.can_be_progressed and not node.is_completed():
		var previous_state: bool = node.is_unlocked()
		upgrade_cost_manager.purchase_unlock_cost(node.unlock_type._decide_single_upgrade_point_cost())
		node.unlock_type._progress_skill()

		# Emit event to signal skill has progressed
		SkillTreeEvents.skill_progressed.emit(node)

		# If wasn't unlocked, but now is, emit that event
		if previous_state != node.is_unlocked():
			SkillTreeEvents.skill_unlocked.emit(node)
		# If now fully unlocked, emit that event
		if node.is_completed():
			SkillTreeEvents.skill_completed.emit(node)
