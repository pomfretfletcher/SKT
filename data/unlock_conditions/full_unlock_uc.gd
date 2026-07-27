@tool
class_name FullUnlock_UC
extends UnlockCondition

func is_condition_reached(connection: SkillNodeConnection) -> bool:
	return connection.start_node.is_completed()
