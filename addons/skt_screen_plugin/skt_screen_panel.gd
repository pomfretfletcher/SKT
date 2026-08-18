@tool
class_name SKT
extends Control

static var tree: SKT_Tree

# Backend Signallers
var _tree_update_signaller: SKT_TreeUpdateSignaller:
	get:
		return tree._tree_update_signaller if tree != null else null
	set(v):
		tree_update_signaller = v
		_tree_update_signaller = v
static var tree_update_signaller: SKT_TreeUpdateSignaller = null
var _tree_draw_signaller: SKT_TreeDrawSignaller:
	get:
		return tree._tree_draw_signaller if tree != null else null
	set(v):
		tree_draw_signaller = v
		_tree_draw_signaller = v
static var tree_draw_signaller: SKT_TreeDrawSignaller = null

# Frontend Function Nodes
var _spawner: SKT_Spawner:
	get:
		return tree._spawner if tree != null else null
	set(v):
		spawner = v
		_spawner = v
static var spawner: SKT_Spawner = null

# Frontend Managers
var _progression_tier_manager: SKT_ProgressionTierManager:
	get:
		return tree._progression_tier_manager if tree != null else null
	set(v):
		progression_tier_manager = v
		_progression_tier_manager = v
static var progression_tier_manager: SKT_ProgressionTierManager = null
var _upgrade_cost_manager: SKT_UpgradeCostManager:
	get:
		return tree._upgrade_cost_manager if tree != null else null
	set(v):
		upgrade_cost_manager = v
		_upgrade_cost_manager = v
static var upgrade_cost_manager: SKT_UpgradeCostManager = null
var _grid_node_locker: SKT_GridNodeLocker:
	get:
		return tree._grid_node_locker if tree != null else null
	set(v):
		grid_node_locker = v
		_grid_node_locker = v
static var grid_node_locker: SKT_GridNodeLocker = null

# Parents
var _nodes_parent: SKT_NodesParent:
	get:
		return tree._nodes_parent if tree != null else null
	set(v):
		nodes_parent = v
		_nodes_parent = v
static var nodes_parent: SKT_NodesParent = null
var _branches_parent: SKT_BranchesParent:
	get:
		return tree._branches_parent if tree != null else null
	set(v):
		branches_parent = v
		_branches_parent = v
static var branches_parent: SKT_BranchesParent = null


func _enter_tree() -> void:
	update_refs()


func update_refs() -> void:
	tree_update_signaller = _tree_update_signaller
	tree_draw_signaller = _tree_draw_signaller
	spawner = _spawner
	progression_tier_manager = _progression_tier_manager
	upgrade_cost_manager = _upgrade_cost_manager
	grid_node_locker = _grid_node_locker
	nodes_parent = _nodes_parent
	branches_parent = _branches_parent
	print(branches_parent)
