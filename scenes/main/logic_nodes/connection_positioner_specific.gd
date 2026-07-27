@tool
extends SKT_ConnectionPositioner

func position_connection(skill_node_connection: SkillNodeConnection):
	var start_node = skill_node_connection.start_node
	var end_node = skill_node_connection.end_node

	if !end_node or !start_node:
		skill_node_connection.visible = false
		return
	skill_node_connection.visible = true

	if skill_node_connection.arc_sub_nodes.is_empty():
		position_connection_between_nodes(skill_node_connection)
	else:
		position_arc_sub_nodes(skill_node_connection)


func position_arc_sub_nodes(skill_node_connection: SkillNodeConnection):
	var snc = skill_node_connection

	var start_position: Vector2 = snc.start_node.position
	var arc = snc.node_arc
	var shader_arc = snc.shader_arc
	var arrow = snc.arrow
	var end_position: Vector2
	var start_node = skill_node_connection.start_node

	var position_a = skill_node_connection.start_node.position + (start_node.size / 2.0)
	var position_b = snc.arc_sub_nodes[0].position

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

	for i in range(len(snc.arc_sub_nodes)):
		if !snc.arc_sub_nodes[i]:
			continue

		var sub_node: ConnectionSubNode = snc.arc_sub_nodes[i]
		start_position = sub_node.position
		if i < len(snc.arc_sub_nodes) - 1:
			end_position = snc.arc_sub_nodes[i + 1].position
		else:
			end_position = snc.end_node.position + snc.end_node.size / 2

		angle = atan2(
			end_position.y - start_position.y,
			end_position.x - start_position.x,
		)

		arc = sub_node.node_arc
		shader_arc = sub_node.shader_arc
		arrow = sub_node.arrow

		arc.size.x = (end_position - start_position).length()
		shader_arc.size = arc.size

		arc.position.y = -arc.size.y / 2

		arrow.visible = sub_node.arrow_visible
		arrow.position.x = (arc.size.x / 2) - (arrow.size.x / 2)
		arrow.position.y = -arrow.size.x / 2

		sub_node.rotation = 0
		sub_node.position = start_position
		sub_node.pivot_offset_ratio = Vector2(0.0, 0.5)
		sub_node.rotation = angle


func position_connection_between_nodes(connection: SkillNodeConnection):
	var arc = connection.node_arc
	var shader_arc = connection.shader_arc
	var arrow = connection.arrow
	var snc = connection
	var position_a = connection.start_node.position
	var position_b = connection.end_node.position
	var start_node = connection.start_node

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
	snc.position = start_node.position - Vector2(0, snc.size.y / 2.0) + (start_node.size / 2)
	snc.pivot_offset_ratio = Vector2(0.0, 0.5)
	snc.rotation = angle
	arc.position = Vector2(0, snc.size.y / 4.0)


func position_subnode_arc_between_positions(arc: ColorRect, shader_arc: ColorRect, arrow: TextureRect, shader_arrow: TextureRect, position_a: Vector2, position_b: Vector2):
	pass
