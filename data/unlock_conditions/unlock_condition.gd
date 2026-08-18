@tool
@abstract
class_name UnlockCondition
extends Resource

var attached_branch: SkillBranch
var _setup := false


func _init() -> void:
	SkillTreeEvents.tree_setup.connect(
		func():
			_setup = true
	)


@abstract
func is_condition_reached(branch: SkillBranch) -> bool
