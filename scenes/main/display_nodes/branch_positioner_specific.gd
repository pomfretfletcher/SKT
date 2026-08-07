@tool
extends SKT_BranchPositioner

@export_subgroup("Inspector Node References")
@export var branches_parent: SKT_BranchesParent


func _ready() -> void:
	if not SkillTreeEvents.draw_tree.is_connected(position_branches):
		SkillTreeEvents.draw_tree.connect(position_branches)


func position_branches():
	for branch: SkillBranch in branches_parent.get_branches():
		position_branch(branch)


func position_branch(skill_branch: SkillBranch):
	var start_node = skill_branch.start_node
	var end_node = skill_branch.end_node

	if end_node == null or start_node == null:
		skill_branch.visible = false
		return
	skill_branch.visible = true

	if skill_branch.branch_follow_points.is_empty():
		position_branch_between_nodes(skill_branch)
	else:
		position_branch_follow_point(skill_branch)


func position_branch_follow_point(skill_branch: SkillBranch):
	var snc = skill_branch

	var start_position: Vector2 = snc.start_node.position
	var arc = snc.node_arc
	var shader_arc = snc.shader_arc
	var arrow = snc.arrow
	var end_position: Vector2
	var start_node = skill_branch.start_node

	var position_a = skill_branch.start_node.position + (start_node.size / 2.0)
	var position_b = snc.branch_follow_points[0].position

	var angle = atan2(
		position_b.y - position_a.y,
		position_b.x - position_a.x,
	)

	arc.size.x = (position_b - position_a).length()
	shader_arc.size = arc.size

	snc.size = arc.size
	snc.size.y *= 2.0

	arrow.visible = snc.arrow_visible
	arrow.position.x = (snc.size.x / 2) - (arrow.size.x / 2)

	snc.rotation = 0
	snc.position = position_a - Vector2(0, snc.size.y / 2.0) # + (start_node.size / 2)
	snc.pivot_offset_ratio = Vector2(0.0, 0.5)
	snc.rotation = angle
	arc.position = Vector2(0, snc.size.y / 4.0)

	for i in range(len(snc.branch_follow_points)):
		if snc.branch_follow_points[i] == null:
			continue

		var follow_point: BranchFollowPoint = snc.branch_follow_points[i]
		start_position = follow_point.position
		if i < len(snc.branch_follow_points) - 1:
			end_position = snc.branch_follow_points[i + 1].position
		else:
			end_position = snc.end_node.position + snc.end_node.size / 2

		angle = atan2(
			end_position.y - start_position.y,
			end_position.x - start_position.x,
		)

		arc = follow_point.node_arc
		shader_arc = follow_point.shader_arc
		arrow = follow_point.arrow

		arc.size.x = (end_position - start_position).length()
		shader_arc.size = arc.size

		arrow.visible = follow_point.arrow_visible
		arrow.position.x = (arc.size.x / 2) - (arrow.size.x / 2)
		arrow.position.y = (arc.size.y / 2) - (arrow.size.y / 2)

		follow_point.size = arc.size
		follow_point.rotation = 0
		follow_point.position = start_position
		follow_point.pivot_offset_ratio = Vector2(0.0, 0.5)
		follow_point.rotation = angle


func position_branch_between_nodes(branch: SkillBranch):
	var arc = branch.node_arc
	var shader_arc = branch.shader_arc
	var arrow = branch.arrow
	var position_a = branch.start_node.position
	var position_b = branch.end_node.position
	var start_node = branch.start_node

	var angle = atan2(
		position_b.y - position_a.y,
		position_b.x - position_a.x,
	)

	arc.size.x = (position_b - position_a).length()
	shader_arc.size = arc.size

	branch.size = arc.size
	branch.size.y *= 2.0

	arrow.visible = branch.arrow_visible
	arrow.position.x = (branch.size.x / 2) - (arrow.size.x / 2)

	branch.rotation = 0
	branch.position = start_node.position - Vector2(0, branch.size.y / 2.0) + (start_node.size / 2)
	branch.pivot_offset_ratio = Vector2(0.0, 0.5)
	branch.rotation = angle
	arc.position = Vector2(0, branch.size.y / 4.0)
