@tool
class_name SKT_CanProgressChecker
extends Node

@export var upgrade_cost_handler: SKT_UpgradeCostHandler


func can_node_be_progressed(node: SkillNode) -> bool:
	if !node:
		return false

	for connection: SkillNodeConnection in node.previous_connections:
		if not can_node_be_progressed(connection.start_node):
			return false
	for connection: SkillNodeConnection in node.previous_connections:
		if not connection.unlock_condition.is_condition_reached(connection):
			return false
	if not upgrade_cost_handler.can_afford_node(node) and !node.is_completed():
		return false

	return true
