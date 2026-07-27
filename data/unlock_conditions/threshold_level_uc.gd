@tool
class_name ThresholdLevel_UC
extends UnlockCondition

@export var threshold_level: int


func is_condition_reached(connection: SkillNodeConnection) -> bool:
	var start_node: SkillNode = connection.start_node

	var start_node_level = start_node.unlock_type.get("current_level")
	if !start_node_level:
		pass
	return start_node_level >= threshold_level
