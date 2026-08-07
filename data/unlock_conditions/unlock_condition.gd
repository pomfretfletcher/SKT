@tool
@abstract
class_name UnlockCondition
extends Resource

var attached_branch: SkillBranch


@abstract
func is_condition_reached(branch: SkillBranch) -> bool
