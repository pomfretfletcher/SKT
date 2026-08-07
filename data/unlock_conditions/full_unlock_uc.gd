@tool
class_name FullUnlock_UC
extends UnlockCondition

func is_condition_reached(branch: SkillBranch) -> bool:
	return branch.start_node.is_completed()
