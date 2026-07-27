@tool
extends SKT_ConnectionFormatter

func format_visuals_of_node(node: SkillNode):
	if not node.is_unlocked():
		set_locked(node)
	else:
		set_unlocked(node)


func set_locked(node: SkillNode):
	node.shader_orb.modulate = Color(1, 1, 1, 0.5)
	for connection in node.result_connections:
		connection.shader_arc.modulate = Color(0, 0, 0, 1)
		connection.shader_arrow.modulate = Color(0, 0, 0, 1)

		for sub_node in connection.arc_sub_nodes:
			sub_node.shader_arc.modulate = Color(0, 0, 0, 1)
			sub_node.shader_arrow.modulate = Color(0, 0, 0, 1)


func set_unlocked(node: SkillNode):
	node.shader_orb.modulate = Color(0, 0, 0, 0)
	for connection in node.result_connections:
		if !connection.start_node or !connection.end_node:
			continue

		if connection.unlock_condition.is_condition_reached(connection):
			connection.shader_arc.modulate = Color(0, 0, 0, 0)
			connection.shader_arrow.modulate = Color(0, 0, 0, 0)

			for sub_node in connection.arc_sub_nodes:
				sub_node.shader_arc.modulate = Color(0, 0, 0, 0)
				sub_node.shader_arrow.modulate = Color(0, 0, 0, 0)
		else:
			connection.shader_arc.modulate = Color(0, 0, 0, 1)
			connection.shader_arrow.modulate = Color(0, 0, 0, 1)

			for sub_node in connection.arc_sub_nodes:
				sub_node.shader_arc.modulate = Color(0, 0, 0, 1)
				sub_node.shader_arrow.modulate = Color(0, 0, 0, 1)
