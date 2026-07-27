@tool
class_name SKT_CanRegressChecker
extends Node

func can_node_be_regressed(node: SkillNode) -> bool:
	if !node:
		return false

	for connection: SkillNodeConnection in node.result_connections:
		if !connection.end_node:
			continue
		if not can_node_be_regressed(connection.end_node):
			return false
	for connection: SkillNodeConnection in node.result_connections:
		# Can level down if would not invalidise a later connection's threshold
		# level
		if connection.unlock_condition is ThresholdLevel_UC:
			var uc: ThresholdLevel_UC = connection.unlock_condition
			var start_node_lvl: int = connection.start_node.unlock_type.get("current_level")
			if uc.threshold_level < start_node_lvl:
				continue

		# Can level down a multi level skill as long as only one unlock is
		# needed
		if connection.unlock_condition is SingleUnlock_UC:
			var start_node_lvl: int = connection.start_node.unlock_type.get("current_level")
			if start_node_lvl and start_node_lvl > 1:
				continue

		if connection.end_node and connection.end_node.is_unlocked():
			return false
	return true
