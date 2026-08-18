@tool
@icon("res://addons/at-icons/node/arrow_up_from_line.svg")
class_name SKT_CanProgressChecker
extends Node

func _ready() -> void:
	if not SkillTreeEvents.update_tree.is_connected(check_nodes_can_progress):
		SkillTreeEvents.update_tree.connect(check_nodes_can_progress)


func check_nodes_can_progress():
	for node: SkillNode in SKT.nodes_parent.get_nodes():
		var can_be_progressed = can_node_be_progressed(node)
		node.can_be_progressed = can_be_progressed


func can_node_be_progressed(node: SkillNode) -> bool:
	if node == null:
		return false

	for branch: SkillBranch in node.previous_branches:
		if not can_node_be_progressed(branch.start_node):
			return false
		if branch.unlock_condition == null:
			return false
		if not branch.unlock_condition.is_condition_reached(branch):
			return false
	if SKT.progression_tier_manager.use_progression_tiers:
		if node.progression_tier > SKT.progression_tier_manager.current_tier:
			return false
	if not SKT.upgrade_cost_manager.can_afford_node(node) and not node.is_completed():
		return false

	return true
