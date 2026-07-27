@tool
class_name SingleUnlock_UC
extends UnlockCondition

func is_condition_reached(connection: SkillNodeConnection) -> bool:
	return connection.start_node._is_unlocked()
