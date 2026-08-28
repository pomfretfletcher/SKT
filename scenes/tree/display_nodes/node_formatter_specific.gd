@tool
extends SKT_NodeFormatter

@export var tree: SKT_Tree

func _ready() -> void:
	if not tree.draw_tree.is_connected(display_node):
		tree.draw_tree.connect(display_node)
	if not tree.draw_tree.is_connected(format_visuals_of_nodes):
		tree.draw_tree.connect(format_visuals_of_nodes)


func display_node():
	for node: SkillNode in tree.nodes_parent.get_nodes():
		if node.skill_data.icon == null:
			return

		node.orb.texture = node.skill_data.icon
		node.shader_orb.texture = node.skill_data.shader_icon


func format_visuals_of_nodes():
	for node: SkillNode in tree.nodes_parent.get_nodes():
		if not node.is_unlocked():
			set_locked(node)
		else:
			set_unlocked(node)


func set_locked(node: SkillNode):
	node.shader_orb.modulate = Color(1, 1, 1, 0.5)
	for branch in node.result_branches:
		branch.shader_arc.modulate = Color(0, 0, 0, 1)
		branch.shader_arrow.modulate = Color(0, 0, 0, 1)

		for follow_point in branch.branch_follow_points:
			follow_point.shader_arc.modulate = Color(0, 0, 0, 1)
			follow_point.shader_arrow.modulate = Color(0, 0, 0, 1)


func set_unlocked(node: SkillNode):
	node.shader_orb.modulate = Color(0, 0, 0, 0)
	for branch in node.result_branches:
		if branch.start_node == null or branch.end_node == null or branch.unlock_condition == null:
			continue

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
