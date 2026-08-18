@tool
@icon("res://addons/at-icons/control/node_graph_root.svg")
class_name SKT_NodesParent
extends Control

@export_tool_button("Create new Node")
var but_newnode = func():
	SKT.spawner.create_node()

var node_count: int = 0:
	get:
		var result: int = 0
		for child in get_children():
			if child is SkillNode:
				result += 1
		return result
	set(_v):
		assert(false, "")


func get_nodes() -> Array[SkillNode]:
	var result: Array[SkillNode] = []
	for child in get_children():
		if child is SkillNode:
			result.append(child)
	return result
