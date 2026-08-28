@tool
@icon("res://addons/at-icons/node/arrow_clockwise.svg")
class_name SKT_TreeResetter
extends Node

@export var tree: SKT_Tree

@export_subgroup("Tool Buttons")
@export_tool_button("Reset Tree")
var but_resettree = reset_tree


func _ready() -> void:
	tree.request_reset_tree.connect(reset_tree)


func reset_tree():
	for node: SkillNode in tree.nodes_parent.get_nodes():
		node.can_be_regressed = true
		while node.is_unlocked():
			tree.request_regress_skill.emit(node)
