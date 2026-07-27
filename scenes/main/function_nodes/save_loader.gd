@tool
class_name SKT_SaveLoader
extends Node

var saved_data: Dictionary
const SAVE_PATH = "user://savedata.json"
@export_tool_button("Save Data")
var but_savedata = save_data
@export_tool_button("Load Data")
var but_loaddata = load_data

@export var spawner: SKT_Spawner
@export var nodes_parent: SKT_NodesParent
@export var node_connections_parent: SKT_NodeConnectionsParent


func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		load_data()

	SkillTreeRequests.request_save_data.connect(save_data)
	SkillTreeRequests.request_load_data.connect(load_data)


func save_data() -> void:
	print("Saving Tree Data")
	saved_data.clear()
	for node: SkillNode in nodes_parent.get_nodes():
		saved_data.set(
			node.name,
			{
				"skill_data_path": save_and_get_path_of_skilldata(node),
				"previous_connections": format_connections("start", node.previous_connections),
				"result_connections": format_connections("end", node.result_connections),
				"control_position": node.position,
			},
		)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(FormatJSON(saved_data))
	file.close()

	SkillTreeEvents.data_saved.emit()


func FormatJSON(value, indent := 0) -> String:
	var ind = "  ".repeat(indent)

	if value is Dictionary:
		var parts := []
		for key in value:
			var v = value[key]

			if v is Array or v is Dictionary:
				parts.append("\n" + ind + "  \"" + str(key) + "\": " + FormatJSON(v, indent + 1))
			else:
				parts.append("\n" + ind + "  \"" + str(key) + "\": " + FormatJSON(v, 0))

		return "{" + ",".join(parts) + "\n" + ind + "}"

	elif value is Array:
		# Detect 2D array
		if value.size() > 0 and value[0] is Array:
			var rows := []
			for row in value:
				rows.append("\n" + ind + "  " + FormatJSON(row, 0))
			return "[" + ",".join(rows) + "\n" + ind + "]"
		else:
			# Normal 1D arrays stay inline
			var parts := []
			for v in value:
				parts.append(FormatJSON(v, 0))
			return "[" + ", ".join(parts) + "]"

	else:
		return JSON.stringify(value)


func load_data():
	# Open and read json file of save data
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	saved_data = JSON.parse_string(file.get_as_text())
	file.close()

	for child in nodes_parent.get_nodes():
		child.queue_free()
	for child in node_connections_parent.get_connections():
		child.queue_free()
	await get_tree().create_timer(0.5).timeout

	var created_nodes: Dictionary[String, SkillNode]
	for node_key in saved_data:
		var entry = saved_data[node_key]
		var node: SkillNode = spawner.create_node()
		created_nodes.set(node_key, node)

		var skill_data: SkillData = load(entry["skill_data_path"])
		var temp = skill_data.duplicate(true)
		node.skill_data = temp

		node.position = SkillTreeFunctions.stringified_vector_to_v2(entry["control_position"])

	var created_connections: Dictionary[String, SkillNodeConnection]
	for node_key in saved_data:
		var entry = saved_data[node_key]
		var prev_connections = entry.get("previous_connections")
		for p_connection in prev_connections:
			var connection_name = p_connection["connection_name"]
			var connection: SkillNodeConnection
			var connected_node = p_connection["connected_node"]

			if connection_name not in created_connections:
				connection = spawner.create_connection()
				if "sub_node_positions" in p_connection.keys():
					create_sub_nodes_for_skill_node_connection(connection, p_connection)
			if connection_name in created_connections:
				connection = created_connections[connection_name]

			if p_connection["connection_position"] == "start":
				connection.start_node = created_nodes[connected_node]
			elif p_connection["connection_position"] == "end":
				connection.end_node = created_nodes[connected_node]

			created_connections.set(connection_name, connection)

	for node_key in saved_data:
		var entry = saved_data[node_key]
		var res_connections = entry.get("result_connections")
		for r_connection in res_connections:
			var connection_name = r_connection["connection_name"]
			var connection: SkillNodeConnection
			var connected_node = r_connection["connected_node"]

			if connection_name not in created_connections:
				connection = spawner.create_connection()
				if "sub_node_positions" in r_connection.keys():
					create_sub_nodes_for_skill_node_connection(connection, r_connection)
			if connection_name in created_connections:
				connection = created_connections[connection_name]

			if r_connection["connection_position"] == "start":
				connection.start_node = created_nodes[connected_node]
			elif r_connection["connection_position"] == "end":
				connection.end_node = created_nodes[connected_node]

			created_connections.set(connection_name, connection)

	SkillTreeEvents.data_loaded.emit()


func format_connections(mode: String, connections: Array[SkillNodeConnection]) -> Array[Dictionary]:
	var return_array: Array[Dictionary] = []
	for connection in connections:
		var con: Dictionary = { }
		con.set("connected_node", connection.start_node.name if mode == "start" else connection.end_node.name)
		con.set(
			"unlock_condition_path",
			save_and_get_path_of_connection(connection),
		)
		con.set("connection_name", connection.name)
		con.set("connection_position", mode)
		con.set("arrow_visible", connection.arrow_visible)
		if !connection.arc_sub_nodes.is_empty():
			con.set("sub_node_positions", format_sub_nodes_of_connection(connection))
		return_array.append(con)
	return return_array


func save_and_get_path_of_skilldata(node: SkillNode) -> String:
	if !node:
		return ""

	var save_path = "user://saved_skill_data"
	var dir = DirAccess.open("user://")

	if not dir.dir_exists(save_path):
		dir.make_dir(save_path)

	var path = "user://saved_skill_data/" + node.name + ".tres"
	if !ResourceLoader.exists(path):
		# Save a new node's skill data
		ResourceSaver.save(node.skill_data, path)
	else:
		# Delete and save the node's saves data, essentially
		# overrides
		DirAccess.remove_absolute(path)
		ResourceSaver.save(node.skill_data, path)
	return path


func save_and_get_path_of_connection(connection: SkillNodeConnection) -> String:
	if !connection:
		return ""

	var save_path = "user://saved_skill_connections"
	var dir = DirAccess.open("user://")

	if not dir.dir_exists(save_path):
		dir.make_dir(save_path)

	var path = "user://saved_skill_connections/" + connection.name + ".tres"
	if !ResourceLoader.exists(path):
		# Save a new node's skill data
		ResourceSaver.save(connection.unlock_condition, path)
	else:
		# Delete and save the node's saves data, essentially
		# overrides
		DirAccess.remove_absolute(path)
		ResourceSaver.save(connection.unlock_condition, path)
	return path


func format_sub_nodes_of_connection(connection: SkillNodeConnection) -> Dictionary:
	var result: Dictionary

	var order_entry: Array[String]

	for sub_node in connection.arc_sub_nodes:
		order_entry.append(sub_node.name)
		var entry: Dictionary
		entry.set("position", sub_node.position)
		entry.set("arrow_visible", sub_node.arrow_visible)
		result.set(sub_node.name, entry)

	result.set("order", order_entry)

	return result


func create_sub_nodes_for_skill_node_connection(connection: SkillNodeConnection, save_data_entry: Dictionary):
	var sub_node_positions = save_data_entry["sub_node_positions"]
	var order = sub_node_positions["order"]

	for sub_node_name in order:
		var sub_node_entry = sub_node_positions.get(sub_node_name)

		var sub_node = spawner.create_sub_node(connection)
		sub_node.position = SkillTreeFunctions.stringified_vector_to_v2(
			sub_node_entry["position"],
		)
		sub_node.arrow_visible = sub_node_entry["arrow_visible"]
