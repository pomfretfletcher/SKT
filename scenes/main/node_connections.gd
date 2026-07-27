@tool
class_name SKT_NodeConnectionsParent
extends Control

@export var spawner: SKT_Spawner

@export_tool_button("Create new Connection")
var but_newconnection = func():
	spawner.create_connection()

var connection_count: int = 0:
	get:
		return get_child_count()
	set(_v):
		assert(false, "")


func get_connections() -> Array[SkillNodeConnection]:
	var result: Array[SkillNodeConnection] = []
	for child in get_children():
		if child is SkillNodeConnection:
			result.append(child)
	return result
