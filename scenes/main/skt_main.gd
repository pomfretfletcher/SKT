@tool
@icon("res://addons/at-icons/node/node_graph.svg")
class_name SKT_Tree
extends Node

static var main: SKT_Tree = null

# Backend Signallers
@export var _tree_update_signaller: SKT_TreeUpdateSignaller:
	set(v):
		tree_update_signaller = v
		_tree_update_signaller = v
static var tree_update_signaller: SKT_TreeUpdateSignaller = null
@export var _tree_draw_signaller: SKT_TreeDrawSignaller:
	set(v):
		tree_draw_signaller = v
		_tree_draw_signaller = v
static var tree_draw_signaller: SKT_TreeDrawSignaller = null

# Frontend Function Nodes
@export var _spawner: SKT_Spawner:
	set(v):
		spawner = v
		_spawner = v
static var spawner: SKT_Spawner = null

# Frontend Managers
@export var _progression_tier_manager: SKT_ProgressionTierManager:
	set(v):
		progression_tier_manager = v
		_progression_tier_manager = v
static var progression_tier_manager: SKT_ProgressionTierManager = null
@export var _upgrade_cost_manager: SKT_UpgradeCostManager:
	set(v):
		upgrade_cost_manager = v
		_upgrade_cost_manager = v
static var upgrade_cost_manager: SKT_UpgradeCostManager = null
@export var _grid_node_locker: SKT_GridNodeLocker:
	set(v):
		grid_node_locker = v
		_grid_node_locker = v
static var grid_node_locker: SKT_GridNodeLocker = null

# Parents
@export var _nodes_parent: SKT_NodesParent:
	set(v):
		nodes_parent = v
		_nodes_parent = v
static var nodes_parent: SKT_NodesParent = null
@export var _branches_parent: SKT_BranchesParent:
	set(v):
		branches_parent = v
		_branches_parent = v
static var branches_parent: SKT_BranchesParent = null


func _enter_tree() -> void:
	main = self
	tree_update_signaller = _tree_update_signaller
	tree_draw_signaller = _tree_draw_signaller
	spawner = _spawner
	progression_tier_manager = _progression_tier_manager
	upgrade_cost_manager = _upgrade_cost_manager
	grid_node_locker = _grid_node_locker
	nodes_parent = _nodes_parent
	branches_parent = _branches_parent
