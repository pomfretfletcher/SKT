@tool
@icon("res://addons/at-icons/node/arrow_down_from_line.svg")
class_name SKT_CanRegressChecker
extends Node

func _ready() -> void:
	if not SkillTreeEvents.update_tree.is_connected(check_nodes_can_regress):
		SkillTreeEvents.update_tree.connect(check_nodes_can_regress)


func check_nodes_can_regress():
	for node: SkillNode in SKT.nodes_parent.get_nodes():
		var can_be_regressed = can_node_be_regressed(node)
		node.can_be_regressed = can_be_regressed


func can_node_be_regressed(node: SkillNode) -> bool:
	if node == null:
		return false

	for branch: SkillBranch in node.result_branches:
		if branch.end_node == null:
			continue
		if not can_node_be_regressed(branch.end_node):
			return false
	for branch: SkillBranch in node.result_branches:
		# Can level down if would not invalidise a later branch's threshold
		# level
		if branch.unlock_condition is ThresholdLevel_UC:
			var uc: ThresholdLevel_UC = branch.unlock_condition
			var start_node_lvl: int = branch.start_node.unlock_type.get("current_level")
			if uc.threshold_level < start_node_lvl:
				continue

		# Can level down a multi level skill if only one unlock is
		# needed
		if branch.unlock_condition is SingleUnlock_UC:
			var start_node_lvl = branch.start_node.unlock_type.get("current_level")
			if start_node_lvl != null and start_node_lvl > 1:
				continue

		if branch.end_node != null and branch.end_node.is_unlocked():
			return false
	return true
