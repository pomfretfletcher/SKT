@tool
extends SKT_NodeFormatter

func display_node(node: SkillNode):
	if !node.skill_data.icon:
		return

	node.orb.texture = node.skill_data.icon
	node.shader_orb.texture = node.skill_data.shader_icon
