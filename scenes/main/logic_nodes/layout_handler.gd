@tool
class_name SKT_LayoutHandler
extends Node

# Control Packed Scenes
var node_pscene: PackedScene = load("uid://2ud8xhsds1xu")
var connection_pscene: PackedScene = load("uid://d70eulefynr3")

@export var connection_positioner: SKT_ConnectionPositioner
@export var node_formatter: SKT_NodeFormatter
@export var nodes_parent: SKT_NodesParent
@export var node_connections_parent: SKT_NodeConnectionsParent


func _ready() -> void:
	store_connections_in_nodes()
	if not SkillTreeEvents.update_tree.is_connected(store_connections_in_nodes):
		SkillTreeEvents.update_tree.connect(store_connections_in_nodes)
	if not SkillTreeEvents.draw_tree.is_connected(position_arcs_to_nodes):
		SkillTreeEvents.draw_tree.connect(position_arcs_to_nodes)
	if not SkillTreeEvents.draw_tree.is_connected(set_node_display):
		SkillTreeEvents.draw_tree.connect(set_node_display)


func position_arcs_to_nodes():
	for connection: SkillNodeConnection in node_connections_parent.get_connections():
		connection_positioner.position_connection(connection)


func set_node_display():
	for node: SkillNode in nodes_parent.get_nodes():
		node_formatter.display_node(node)


func store_connections_in_nodes():
	for node: SkillNode in nodes_parent.get_nodes():
		node.previous_connections.clear()
		node.result_connections.clear()

	for connection: SkillNodeConnection in node_connections_parent.get_connections():
		if connection.start_node:
			connection.start_node.result_connections.append(connection)
		if connection.end_node:
			connection.end_node.previous_connections.append(connection)
