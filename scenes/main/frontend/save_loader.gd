@tool
@icon("res://addons/at-icons/node/file.svg")
class_name SKT_SaveLoader
extends Node

@export_subgroup("Tool Buttons")
@export_tool_button("Save Data")
var but_savedata = save_data
@export_tool_button("Load Data")
var but_loaddata = load_data

var saved_data: Dictionary
const SAVE_PATH = "user://savedata.json"


func _ready() -> void:
	if not SkillTreeRequests.request_save_data.is_connected(save_data):
		SkillTreeRequests.request_save_data.connect(save_data)
	if not SkillTreeRequests.request_load_data.is_connected(load_data):
		SkillTreeRequests.request_load_data.connect(load_data)


func save_data() -> void:
	SkillTreeRequests.request_log_process.emit("Saving Tree Data")
	saved_data.clear()

	# Allow any nodes that need to organize their data before saving data occurs
	SkillTreeRequests.request_prepare_for_save.emit()
	await get_tree().create_timer(0.5).timeout

	SkillTreeRequests.request_log_process.emit("Saving Node Data")
	var node_saved_data: Dictionary
	for node: SkillNode in SKT.nodes_parent.get_nodes():
		node_saved_data.set(
			node.name,
			{
				"skill_data_path": save_and_get_path_of_skilldata(node),
				"position": node.position,
				"progression_tier": node.progression_tier,
				"previous_branches": format_branches("end", node.previous_branches),
				"result_branches": format_branches("start", node.result_branches),
			},
		)

	SkillTreeRequests.request_log_process.emit("Saving System Data")
	var system_saved_data: Dictionary
	system_saved_data.set(
		"progression_tier_manager",
		{
			"uses_tiers": SKT.progression_tier_manager.use_progression_tiers,
			"current_tier": SKT.progression_tier_manager.current_tier,
		},
	)
	system_saved_data.set(
		"upgrade_cost_manager",
		{
			"upgrade_type": SKT.upgrade_cost_manager.upgrade_type,
			"current_sp": SKT.upgrade_cost_manager.current_sp,
		},
	)
	system_saved_data.set(
		"grid_node_locker",
		{
			"uses_lock": SKT.grid_node_locker.lock_nodes_to_grid,
			"cell_size": SKT.grid_node_locker.grid_cell_size,
		},
	)

	saved_data.set("nodes", node_saved_data)
	saved_data.set("system", system_saved_data)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(FormatJSON(saved_data, 1))
	file.close()

	SkillTreeEvents.data_saved.emit()


func FormatJSON(value, indent := 0) -> String:
	var ind = " ".repeat(indent)

	if value is Dictionary:
		var parts := []
		for key in value:
			var v = value[key]

			if v is Array or v is Dictionary:
				parts.append("\n" + ind + "  \"" + str(key) + "\": " + FormatJSON(v, indent + 2))
			else:
				parts.append("\n" + ind + "  \"" + str(key) + "\": " + FormatJSON(v, indent))

		return "{" + ",".join(parts) + "\n" + ind + "}"

	elif value is Array:
		# Detect 2D array
		if value.size() > 0 and value[0] is Array:
			var rows := []
			for row in value:
				rows.append("\n" + ind + "  " + FormatJSON(row, indent + 2))
			return "[" + ",".join(rows) + "\n" + ind + "]"
		else:
			# Normal 1D arrays stay inline
			var parts := []
			for v in value:
				parts.append(FormatJSON(v, indent))
			return "[" + ", ".join(parts) + "]"

	else:
		return JSON.stringify(value)


func load_data():
	SkillTreeRequests.request_log_process.emit("Loading Tree Data")

	# Open and read json file of save data
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	saved_data = JSON.parse_string(file.get_as_text())
	file.close()

	# Pause updating and drawing until loading is finished - Prevents skt logic nodes
	# attempt to run processes on control nodes that are being deleted or are not completely
	# setup yet
	SkillTreeRequests.request_toggle_tree_updating.emit(false)
	SkillTreeRequests.request_toggle_tree_drawing.emit(false)

	SkillTreeRequests.request_log_process.emit("Clearing Current Controls")
	# Delete all current skill tree controls. Will be remade within loading process
	for child in SKT.nodes_parent.get_nodes():
		if child is SkillNode:
			child.free()
	for child in SKT.branches_parent.get_branches():
		if child is SkillBranch:
			child.free()

	# Use a short delay in order to allow for child.free() to process correctly and for no
	# logic issues to take place while tree is incomplete
	# Also allows any nodes that need to prepare for loading data to do so
	SkillTreeRequests.request_prepare_for_load.emit()
	await get_tree().create_timer(0.5).timeout

	SkillTreeRequests.request_log_process.emit("Recreating Nodes")
	var created_nodes: Dictionary[String, SkillNode]
	recreate_nodes(saved_data["nodes"], created_nodes)

	SkillTreeRequests.request_log_process.emit("Recreating Branches")
	var created_branches: Dictionary[String, SkillBranch]
	recreate_branches(saved_data["nodes"], created_nodes, created_branches)

	SkillTreeRequests.request_log_process.emit("Loading System Data")
	load_system_data(saved_data["system"])

	# Allow updating and drawing to occur again, no logic errors should happen from now on
	SkillTreeRequests.request_toggle_tree_updating.emit(true)
	SkillTreeRequests.request_toggle_tree_drawing.emit(true)
	SkillTreeEvents.data_loaded.emit()


func format_branches(mode: String, branches: Array[SkillBranch]) -> Array[Dictionary]:
	var return_array: Array[Dictionary] = []
	for branch in branches:
		var entry: Dictionary = { }
		entry.set("connected_node", branch.start_node.name if mode == "start" else branch.end_node.name)
		entry.set("unlock_condition_path", save_and_get_path_of_uc(branch))
		entry.set("branch_name", branch.name)
		entry.set("branch_mode", mode)
		entry.set("arrow_visible", branch.arrow_visible)
		if not branch.branch_follow_points.is_empty():
			entry.set("follow_point_positions", format_follow_points_of_branch(branch))
		return_array.append(entry)
	return return_array


func save_and_get_path_of_skilldata(node: SkillNode) -> String:
	if node == null:
		return ""

	var save_path = "user://saved_skill_data"
	var dir = DirAccess.open("user://")

	if not dir.dir_exists(save_path):
		dir.make_dir(save_path)

	var path = "user://saved_skill_data/" + node.name + ".tres"
	ResourceSaver.save(node.skill_data, path)
	return path


func save_and_get_path_of_uc(branch: SkillBranch) -> String:
	if branch == null:
		return ""

	var save_path = "user://saved_skill_branches"
	var dir = DirAccess.open("user://")

	if not dir.dir_exists(save_path):
		dir.make_dir(save_path)

	var path = "user://saved_skill_branches/" + branch.name + ".tres"
	ResourceSaver.save(branch.unlock_condition, path)
	return path


func format_follow_points_of_branch(branch: SkillBranch) -> Dictionary:
	var result: Dictionary

	for follow_point in branch.branch_follow_points:
		var entry: Dictionary
		entry.set("position", follow_point.position)
		entry.set("arrow_visible", follow_point.arrow_visible)
		result.set(follow_point.name, entry)

	return result


func recreate_nodes(node_saved_data: Dictionary, node_dict: Dictionary[String, SkillNode]):
	for node_key in node_saved_data:
		var entry = node_saved_data[node_key]
		var node: SkillNode = SKT.spawner.create_node()
		node_dict.set(node_key, node)

		var skill_data: SkillData = ResourceLoader.load(entry["skill_data_path"], "", ResourceLoader.CACHE_MODE_IGNORE)
		node.skill_data = skill_data.duplicate(true)

		node.position = SkillTreeFunctions.stringified_vector_to_v2(entry["position"])
		node.progression_tier = entry["progression_tier"]


func recreate_branches(node_saved_data: Dictionary, node_dict: Dictionary[String, SkillNode], branch_dict: Dictionary[String, SkillBranch]):
	for node_key in node_saved_data:
		var entry = node_saved_data[node_key]
		var prev_branches = entry.get("previous_branches")
		for p_branch in prev_branches:
			var branch_name = p_branch["branch_name"]
			var branch: SkillBranch
			var connected_node = p_branch["connected_node"]

			if branch_name not in branch_dict:
				branch = SKT.spawner.create_branch()
				var unlock_condition = ResourceLoader.load(p_branch["unlock_condition_path"], "", ResourceLoader.CACHE_MODE_IGNORE)
				branch.unlock_condition = unlock_condition.duplicate(true)

				if "follow_point_positions" in p_branch.keys():
					recreate_follow_points_for_branch(branch, p_branch)
			if branch_name in branch_dict:
				branch = branch_dict[branch_name]

			if p_branch["branch_mode"] == "start":
				branch.start_node = node_dict[connected_node]
			elif p_branch["branch_mode"] == "end":
				branch.end_node = node_dict[connected_node]

			branch_dict.set(branch_name, branch)

	for node_key in node_saved_data:
		var entry = node_saved_data[node_key]
		var res_branches = entry.get("result_branches")
		for r_branch in res_branches:
			var branch_name = r_branch["branch_name"]
			var branch: SkillBranch
			var connected_node = r_branch["connected_node"]

			if branch_name not in branch_dict:
				branch = SKT.spawner.create_branch()
				var unlock_condition = ResourceLoader.load(r_branch["unlock_condition_path"], "", ResourceLoader.CACHE_MODE_IGNORE)
				branch.unlock_condition = unlock_condition.duplicate(true)

				if "follow_point_positions" in r_branch.keys():
					recreate_follow_points_for_branch(branch, r_branch)
			if branch_name in branch_dict:
				branch = branch_dict[branch_name]

			if r_branch["branch_mode"] == "start":
				branch.start_node = node_dict[connected_node]
			elif r_branch["branch_mode"] == "end":
				branch.end_node = node_dict[connected_node]

			branch_dict.set(branch_name, branch)


func recreate_follow_points_for_branch(branch: SkillBranch, save_data_entry: Dictionary):
	var follow_point_positions = save_data_entry["follow_point_positions"]

	for follow_point_name in follow_point_positions:
		var follow_point_entry = follow_point_positions.get(follow_point_name)

		var follow_point: BranchFollowPoint = SKT.spawner.create_follow_point(branch)
		follow_point.position = SkillTreeFunctions.stringified_vector_to_v2(follow_point_entry["position"])
		follow_point.arrow_visible = follow_point_entry["arrow_visible"]


func load_system_data(system_saved_data: Dictionary):
	# Progression Tier Manager
	var ptm_data: Dictionary = system_saved_data["progression_tier_manager"]
	SKT.progression_tier_manager.use_progression_tiers = ptm_data["uses_tiers"]
	SKT.progression_tier_manager.current_tier = int(ptm_data["current_tier"])

	# Upgrade Cost Manager
	var ucm_data: Dictionary = system_saved_data["upgrade_cost_manager"]
	var upgrade_type = int(ucm_data["upgrade_type"])
	SKT.upgrade_cost_manager.upgrade_type = SKT_UpgradeCostManager.UpgradeType[SKT_UpgradeCostManager.UpgradeType.find_key(upgrade_type)]
	SKT.upgrade_cost_manager.current_sp = int(ucm_data["current_sp"])

	# Grid Node Locker
	var gnl_data: Dictionary = system_saved_data["grid_node_locker"]
	SKT.grid_node_locker.lock_nodes_to_grid = gnl_data["uses_lock"]
	SKT.grid_node_locker.grid_cell_size = gnl_data["cell_size"]
