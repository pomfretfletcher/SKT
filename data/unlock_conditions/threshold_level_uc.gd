@tool
class_name ThresholdLevel_UC
extends UnlockCondition

var changing_threshold_level_for_test: bool = false
@export var threshold_level: int:
	set(v):
		if changing_threshold_level_for_test:
			threshold_level = v
			return

		var result: ValidityStatement = SkillTreeChecks.is_new_threshold_level_valid(v, self)
		if result == null:
			return
		elif result.validity:
			threshold_level = v
		else:
			print(result.reason)


func is_condition_reached(branch: SkillBranch) -> bool:
	var start_node: SkillNode = branch.start_node

	var start_node_level = start_node.unlock_type.get("current_level")
	if start_node_level == null:
		pass
	return start_node_level >= threshold_level and start_node.is_unlocked()
