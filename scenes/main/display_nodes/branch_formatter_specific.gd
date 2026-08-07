@tool
extends SKT_BranchFormatter

@export_subgroup("Inspector Node References")
@export var branches_parent: SKT_BranchesParent


func _ready() -> void:
	if not SkillTreeEvents.draw_tree.is_connected(format_visuals_of_branch):
		SkillTreeEvents.draw_tree.connect(format_visuals_of_branch)


func format_visuals_of_branch():
	for branch in branches_parent.get_branches():
		if branch.unlock_condition == null or not branch.unlock_condition.is_condition_reached(branch):
			set_locked(branch)
		else:
			set_unlocked(branch)


func set_locked(branch: SkillBranch):
	if branch.end_node == null or branch.start_node == null:
		return

	branch.shader_arc.modulate = Color(0, 0, 0, 1)
	branch.shader_arrow.modulate = Color(0, 0, 0, 1)

	for follow_point in branch.branch_follow_points:
		follow_point.shader_arc.modulate = Color(0, 0, 0, 1)
		follow_point.shader_arrow.modulate = Color(0, 0, 0, 1)


func set_unlocked(branch: SkillBranch):
	if branch.end_node == null or branch.start_node == null:
		return

	if branch.unlock_condition.is_condition_reached(branch):
		branch.shader_arc.modulate = Color(0, 0, 0, 0)
		branch.shader_arrow.modulate = Color(0, 0, 0, 0)

		for follow_point in branch.branch_follow_points:
			follow_point.shader_arc.modulate = Color(0, 0, 0, 0)
			follow_point.shader_arrow.modulate = Color(0, 0, 0, 0)
	else:
		branch.shader_arc.modulate = Color(0, 0, 0, 1)
		branch.shader_arrow.modulate = Color(0, 0, 0, 1)

		for follow_point in branch.branch_follow_points:
			follow_point.shader_arc.modulate = Color(0, 0, 0, 1)
			follow_point.shader_arrow.modulate = Color(0, 0, 0, 1)
