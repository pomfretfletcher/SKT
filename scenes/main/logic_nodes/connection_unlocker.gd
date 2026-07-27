@tool
class_name SKT_ConnectionUnlocker
extends Node

@export var connection_formatter: SKT_ConnectionFormatter
@export var can_progress_checker: SKT_CanProgressChecker
@export var can_regress_checker: SKT_CanRegressChecker
@export var nodes_parent: SKT_NodesParent


func _ready() -> void:
	if not SkillTreeEvents.update_tree.is_connected(decide_whether_connections_unlocked):
		SkillTreeEvents.update_tree.connect(decide_whether_connections_unlocked)


func decide_whether_connections_unlocked():
	for node: SkillNode in nodes_parent.get_nodes():
		var can_be_progressed_result: bool = can_progress_checker.can_node_be_progressed(node)
		node.can_be_progressed = can_be_progressed_result
		var can_be_regressed_result: bool = can_regress_checker.can_node_be_regressed(node)
		node.can_be_regressed = can_be_regressed_result
		connection_formatter.format_visuals_of_node(node)
