@tool
class_name SkillData
extends Resource

@export var name: String
@export var unlock_type: UnlockType:
	set(v):
		if !check_unlock_type_valid(v):
			print("Chosen unlock type is not valid for this skill/node.")
			return
		unlock_type = v
		if unlock_type:
			unlock_type.attached_node = attached_node
@export var description: String
@export var icon: Texture2D
@export var shader_icon: Texture2D
var attached_node: SkillNode:
	set(v):
		attached_node = v
		if unlock_type:
			unlock_type.attached_node = attached_node


func check_unlock_type_valid(new_ut: UnlockType) -> bool:
	if new_ut is SingleLevel_UT:
		if attached_node:
			for connection in attached_node.result_connections:
				if connection.unlock_condition is ThresholdLevel_UC:
					print("Cannot change to a single level unlock type as a connection from this node needs a threshold level.")
					return false
	return true
