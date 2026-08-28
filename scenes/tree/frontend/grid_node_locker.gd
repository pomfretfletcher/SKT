@tool
@icon("res://addons/at-icons/node/grid_fine.svg")
class_name SKT_GridNodeLocker
extends Node

@export var lock_nodes_to_grid := false:
	set(v):
		lock_nodes_to_grid = v
		if not lock_nodes_to_grid:
			reset_node_positions()

@export var grid_cell_size: int = 10

@export var tree: SKT_Tree

var non_locked_node_positions: Dictionary[SkillNode, Vector2]
var non_locked_followpoint_positions: Dictionary[BranchFollowPoint, Vector2]


func _ready() -> void:
	if not tree.draw_tree.is_connected(position_nodes_on_grid):
		tree.draw_tree.connect(position_nodes_on_grid)
	tree.request_prepare_for_load.connect(
		func():
			non_locked_node_positions.clear()
			non_locked_followpoint_positions.clear()
	)
	tree.request_prepare_for_save.connect(
		func():
			reset_node_positions()
			if lock_nodes_to_grid:
				lock_nodes_to_grid = false
				await tree.data_saved
				lock_nodes_to_grid = true
	)

	tree.node_moved.connect(
		func(node: SkillNode):
			if node in non_locked_node_positions.keys():
				non_locked_node_positions.set(node, node.position)
	)
	tree.followpoint_moved.connect(
		func(fp: BranchFollowPoint):
			if fp in non_locked_followpoint_positions.keys():
				non_locked_followpoint_positions.set(fp, fp.position)
	)


func position_nodes_on_grid():
	if not lock_nodes_to_grid:
		return

	for node: SkillNode in tree.nodes_parent.get_nodes():
		if node not in non_locked_node_positions.keys():
			non_locked_node_positions.set(node, node.position)
		if int(node.position.x / grid_cell_size) == node.position.x / grid_cell_size:
			if int(node.position.y / grid_cell_size) == node.position.y / grid_cell_size:
				return

		var x: int
		var y: int
		# Reset node position before locking to grid
		node.position = non_locked_node_positions[node]

		if (node.position.x - int(node.position.x) < (0.5 * grid_cell_size)):
			x = int(node.position.x / grid_cell_size) + 1
		else:
			x = int(node.position.x / grid_cell_size)
		if (node.position.y - int(node.position.y) < (0.5 * grid_cell_size)):
			y = int(node.position.y / grid_cell_size) + 1
		else:
			y = int(node.position.y / grid_cell_size)

		var v = Vector2i(x, y) * grid_cell_size
		change_node_position_without_emitting_signal(node, v)

	for branch: SkillBranch in tree.branches_parent.get_branches():
		for fp: BranchFollowPoint in branch.branch_follow_points:
			if fp not in non_locked_followpoint_positions.keys():
				non_locked_followpoint_positions.set(fp, fp.position)
			if int(fp.position.x / grid_cell_size) == fp.position.x / grid_cell_size:
				if int(fp.position.y / grid_cell_size) == fp.position.y / grid_cell_size:
					return

			var x: int
			var y: int
			# Reset follow point position before locking to grid
			fp.position = non_locked_followpoint_positions[fp]

			if (fp.position.x - int(fp.position.x) < (0.5 * grid_cell_size)):
				x = int(fp.position.x / grid_cell_size) + 1
			else:
				x = int(fp.position.x / grid_cell_size)
			if (fp.position.y - int(fp.position.y) < (0.5 * grid_cell_size)):
				y = int(fp.position.y / grid_cell_size) + 1
			else:
				y = int(fp.position.y / grid_cell_size)

			var v = Vector2i(x, y) * grid_cell_size
			change_followpoint_position_without_emitting_signal(fp, v)


func reset_node_positions():
	for node: SkillNode in non_locked_node_positions.keys():
		node.position = non_locked_node_positions[node]
	for fp: BranchFollowPoint in non_locked_followpoint_positions.keys():
		fp.position = non_locked_followpoint_positions[fp]


func change_node_position_without_emitting_signal(node: SkillNode, new_position: Vector2):
	if node.position == new_position:
		return

	node.silence_signals = true
	node.position = new_position
	node.silence_signals = false


func change_followpoint_position_without_emitting_signal(fp: BranchFollowPoint, new_position: Vector2):
	if fp.position == new_position:
		return

	fp.silence_signals = true
	fp.position = new_position
	fp.silence_signals = false
