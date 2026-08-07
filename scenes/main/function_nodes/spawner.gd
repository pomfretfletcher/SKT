@tool
class_name SKT_Spawner
extends Node

var NODE_SCENE: PackedScene = load("uid://2ud8xhsds1xu")
var BRANCH_SCENE: PackedScene = load("uid://d70eulefynr3")
var FOLLOWPOINT_SCENE: PackedScene = load("uid://cr4bfcpxf4ldb")

@export_subgroup("Inspector Node References")
@export var nodes_parent: SKT_NodesParent
@export var branches_parent: SKT_BranchesParent

@export_subgroup("Tool Buttons")
@export_tool_button("Create new Node")
var but_newnode = create_node
@export_tool_button("Create new Branch")
var but_newbranch = create_branch
@export_tool_button("Create new Node with Branch to it")
var but_newnodeandbranch = create_node_with_branch_to_it


func _ready() -> void:
	if not SkillTreeRequests.request_create_node.is_connected(create_node):
		SkillTreeRequests.request_create_node.connect(create_node)
	if not SkillTreeRequests.request_create_branch.is_connected(create_branch):
		SkillTreeRequests.request_create_branch.connect(create_branch)
	if not SkillTreeRequests.request_create_followpoint.is_connected(create_follow_point):
		SkillTreeRequests.request_create_followpoint.connect(create_follow_point)


func create_node() -> SkillNode:
	var node = NODE_SCENE.instantiate() as SkillNode
	nodes_parent.add_child(node)
	node.owner = get_tree().edited_scene_root

	# Formats skill node name
	node.name = "SkillNode" + str(nodes_parent.node_count)

	return node


func create_branch() -> SkillBranch:
	var branch = BRANCH_SCENE.instantiate() as SkillBranch
	branches_parent.add_child(branch)
	branch.owner = get_tree().edited_scene_root

	# Formats branch name
	branch.name = "SkillBranch" + str(branches_parent.branch_count)

	return branch


func create_node_with_branch_to_it():
	var node = create_node()

	var branch = create_branch()

	# Connect correct references for skill tree
	branch.end_node = node
	node.previous_branches.append(branch)


func create_follow_point(parent: SkillBranch) -> BranchFollowPoint:
	var follow_point = FOLLOWPOINT_SCENE.instantiate() as BranchFollowPoint
	parent.add_child(follow_point)
	follow_point.owner = get_tree().edited_scene_root

	follow_point.name = "BranchFollowPoint"

	return follow_point
