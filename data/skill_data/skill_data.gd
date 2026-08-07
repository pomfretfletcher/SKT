@tool
class_name SkillData
extends Resource

@export var name: String
@export var unlock_type: UnlockType:
	set(v):
		var result: ValidityStatement = SkillTreeChecks.is_new_unlock_type_valid(v, attached_node)
		if result == null:
			return
		elif result.validity:
			unlock_type = v
			if unlock_type and attached_node:
				unlock_type.attached_node = attached_node
		else:
			print(result.reason)
@export var description: String
@export var icon: Texture2D
@export var shader_icon: Texture2D
var attached_node: SkillNode:
	set(v):
		attached_node = v
		if unlock_type:
			unlock_type.attached_node = attached_node
