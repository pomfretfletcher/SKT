@tool
class_name GDFunctions
extends Node

static func GetChildOfType(node: Node, type: StringName) -> Node:
	if node == null:
		return

	var node_list: Array[Node]
	AccessAllChildrenRecursive(node, node_list)
	for n in node_list:
		var s: Script = n.get_script()
		if s:
			var global_name = s.get_global_name()
			if global_name == type:
				return n
	return


static func AccessAllChildrenRecursive(node: Node, node_list: Array[Node]) -> void:
	if node == null:
		return

	node_list.append(node)
	for child in node.get_children():
		if child is Node:
			AccessAllChildrenRecursive(child, node_list)
