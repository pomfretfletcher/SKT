@tool
class_name SKT_Spawner
extends Node

var node_pscene: PackedScene = load("uid://2ud8xhsds1xu")
var connection_pscene: PackedScene = load("uid://d70eulefynr3")
var subnode_pscene: PackedScene = load("uid://cr4bfcpxf4ldb")

@export_tool_button("Create new Node")
var but_newnode = create_node

@export_tool_button("Create new Connection")
var but_newconnection = create_connection

@export_tool_button("Create new Node with Connection to it")
var but_newnodeandconnection = create_node_with_connection_to_it

@export var nodes_parent: SKT_NodesParent
@export var node_connections_parent: SKT_NodeConnectionsParent


func create_node() -> SkillNode:
	var node = node_pscene.instantiate() as SkillNode
	nodes_parent.add_child(node)
	node.owner = get_tree().edited_scene_root

	# Formats skill node name
	node.name = "SkillNode" + str(nodes_parent.node_count)

	return node


func create_connection() -> SkillNodeConnection:
	var node_connection = connection_pscene.instantiate() as SkillNodeConnection
	node_connections_parent.add_child(node_connection)
	node_connection.owner = get_tree().edited_scene_root

	# Formats connection name
	node_connection.name = "SkillNodeConnection" + str(node_connections_parent.connection_count)

	return node_connection


func create_node_with_connection_to_it():
	var node = create_node()

	var connection_to_node = create_connection()

	# Connect correct references for skill tree
	connection_to_node.end_node = node
	node.previous_connections.append(connection_to_node)


func create_sub_node(parent: SkillNodeConnection) -> ConnectionSubNode:
	var sub_node = subnode_pscene.instantiate() as ConnectionSubNode
	parent.add_child(sub_node)
	sub_node.owner = get_tree().edited_scene_root

	sub_node.name = "ConnectionSubNode"

	return sub_node
