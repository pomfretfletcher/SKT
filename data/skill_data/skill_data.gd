@tool
class_name SkillData
extends Resource

@export var name: String
@export var unlock_type: UnlockType:
	set(v):
		if not _setup:
			unlock_type = v
			if unlock_type != null and attached_node != null:
				unlock_type.attached_node = attached_node
			return

		var result: ValidityStatement = SkillTreeChecks.is_new_unlock_type_valid(v, attached_node)
		if result == null:
			return
		elif result.validity == true:
			unlock_type = v
			if unlock_type != null and attached_node != null:
				unlock_type.setup_data(attached_node)
		else:
			MessageLogger.log_issue(result.reason)
@export var description: String
@export var icon: Texture2D
@export var shader_icon: Texture2D
var attached_node: SkillNode

var _setup := false


func setup_data(n: SkillNode) -> void:
	attached_node = n
	if unlock_type != null:
		unlock_type.setup_data(n)
	attached_node.tree.tree_setup.connect(
		func():
			_setup = true
	)
