@tool
class_name SKT_GridNodeLocker
extends Node

@export var lock_nodes_to_grid: bool = false
@export var grid_cell_size: int = 10

@export_subgroup("Inspector Node References")
@export var nodes_parent: SKT_NodesParent
@export var branches_parent: SKT_BranchesParent

var non_locked_node_positions: Dictionary[SkillNode, Vector2]
var non_locked_followpoint_positions: Dictionary[BranchFollowPoint, Vector2]


func _ready() -> void:
	if not SkillTreeEvents.draw_tree.is_connected(position_nodes_on_grid):
		SkillTreeEvents.draw_tree.connect(position_nodes_on_grid)
	if not SkillTreeRequests.request_prepare_for_save.is_connected(reset_node_positions):
		SkillTreeRequests.request_prepare_for_save.connect(reset_node_positions)
	if not SkillTreeRequests.request_prepare_for_load.is_connected(clear_dictionaries):
		SkillTreeRequests.request_prepare_for_load.connect(clear_dictionaries)


func position_nodes_on_grid():
	if lock_nodes_to_grid:
		for node: SkillNode in nodes_parent.get_nodes():
			if node not in non_locked_node_positions.keys():
				non_locked_node_positions.set(node, node.position)
			var x = int(node.position.x / grid_cell_size)
			var y = int(node.position.y / grid_cell_size)
			node.position = Vector2i(x, y) * grid_cell_size
		for branch: SkillBranch in branches_parent.get_branches():
			if not branch.branch_follow_points.is_empty():
				for fp in branch.branch_follow_points:
					if fp not in non_locked_followpoint_positions.keys():
						non_locked_followpoint_positions.set(fp, fp.position)
					var x = int(fp.position.x / grid_cell_size)
					var y = int(fp.position.y / grid_cell_size)
					fp.position = Vector2i(x, y) * grid_cell_size
	if not lock_nodes_to_grid:
		reset_node_positions()


func reset_node_positions():
	for node: SkillNode in non_locked_node_positions.keys():
		node.position = non_locked_node_positions[node]
	for fp: BranchFollowPoint in non_locked_followpoint_positions.keys():
		fp.position = non_locked_followpoint_positions[fp]


func clear_dictionaries():
	non_locked_followpoint_positions.clear()
	non_locked_node_positions.clear()
