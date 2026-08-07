@tool
class_name SKT_LayoutHandler
extends Node

@export_subgroup("Inspector Node References")
@export var nodes_parent: SKT_NodesParent
@export var branches_parent: SKT_BranchesParent


func _ready() -> void:
	store_branches_in_nodes()
	if not SkillTreeEvents.update_tree.is_connected(store_branches_in_nodes):
		SkillTreeEvents.update_tree.connect(store_branches_in_nodes)


func store_branches_in_nodes():
	for node: SkillNode in nodes_parent.get_nodes():
		node.previous_branches.clear()
		node.result_branches.clear()

	for branch: SkillBranch in branches_parent.get_branches():
		if branch.start_node:
			branch.start_node.result_branches.append(branch)
		if branch.end_node:
			branch.end_node.previous_branches.append(branch)
