@tool
class_name SKT_NodesParent
extends Control

@export var spawner: SKT_Spawner

@export_tool_button("Create new Node")
var but_newnode = func():
	spawner.create_node()

var node_count: int = 0:
	get:
		return get_child_count()
	set(_v):
		assert(false, "")


func get_nodes() -> Array[SkillNode]:
	var result: Array[SkillNode] = []
	for child in get_children():
		if child is SkillNode:
			result.append(child)
	return result
