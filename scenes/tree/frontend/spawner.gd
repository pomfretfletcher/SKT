@tool
@icon("res://addons/at-icons/node/plus_sign_in_square.svg")
class_name SKT_Spawner
extends Node

var NODE_SCENE: PackedScene = load("uid://2ud8xhsds1xu")
var BRANCH_SCENE: PackedScene = load("uid://d70eulefynr3")
var FOLLOWPOINT_SCENE: PackedScene = load("uid://cr4bfcpxf4ldb")

@export var tree: SKT_Tree

@export_subgroup("Tool Buttons")
@export_tool_button("Create new Node")
var but_newnode = create_node
@export_tool_button("Create new Branch")
var but_newbranch = create_branch
@export_tool_button("Create new Node with Branch to it")
var but_newnodeandbranch = create_node_with_branch_to_it


func _ready() -> void:
	if not tree.request_create_node.is_connected(create_node):
		tree.request_create_node.connect(create_node)
	if not tree.request_create_branch.is_connected(create_branch):
		tree.request_create_branch.connect(create_branch)
	if not tree.request_create_followpoint.is_connected(create_follow_point):
		tree.request_create_followpoint.connect(create_follow_point)


func create_node() -> SkillNode:
	var node = NODE_SCENE.instantiate() as SkillNode
	node.setup_data(tree)
	tree.nodes_parent.add_child(node)
	node.owner = tree
	# Formats skill node name
	node.name = "SkillNode" + str(tree.nodes_parent.node_count)
	return node


func create_branch() -> SkillBranch:
	var branch = BRANCH_SCENE.instantiate() as SkillBranch
	branch.setup_data(tree)
	tree.branches_parent.add_child(branch)
	branch.owner = tree
	# Formats branch name
	branch.name = "SkillBranch" + str(tree.branches_parent.branch_count)
	return branch


func create_node_with_branch_to_it():
	var node = create_node()

	var branch = create_branch()

	# Connect correct references for skill tree
	branch.end_node = node
	node.previous_branches.append(branch)


func create_follow_point(parent: SkillBranch) -> BranchFollowPoint:
	var follow_point = FOLLOWPOINT_SCENE.instantiate() as BranchFollowPoint
	follow_point.setup_data(tree)
	parent.add_child(follow_point)
	follow_point.owner = get_tree().edited_scene_root
	follow_point.name = "BranchFollowPoint"
	return follow_point
