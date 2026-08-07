@tool
class_name SKT_TreeResetter
extends Node

@export var refund_upgrade_costs := true

@export_subgroup("Inspector Node References")
@export var nodes_parent: SKT_NodesParent

@export_subgroup("Tool Buttons")
@export_tool_button("Reset Tree")
var but_resettree = reset_tree


func _ready() -> void:
	SkillTreeRequests.request_reset_tree.connect(reset_tree)


func reset_tree():
	for node: SkillNode in nodes_parent.get_nodes():
		node.can_be_regressed = true
		while node.is_unlocked():
			SkillTreeRequests.request_regress_skill.emit(node)
