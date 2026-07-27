@tool
class_name MultiLevel_UT
extends UnlockType

@export var max_level: int:
	set(v):
		if !setup:
			max_level = v

		var prev_value := max_level
		var keep_change := true

		if attached_node and !override_checks:
			var cur_condition_bools: Array[bool] = []
			var new_condition_bools: Array[bool] = []

			for connection in attached_node.result_connections:
				cur_condition_bools.append(connection.unlock_condition.is_condition_reached(connection))

			max_level = v

			for connection in attached_node.result_connections:
				new_condition_bools.append(connection.unlock_condition.is_condition_reached(connection))

			if cur_condition_bools != new_condition_bools:
				print("Cannot change max level as it would cause invalidity for result skills.")
				keep_change = false

		if !keep_change:
			max_level = prev_value
		else:
			max_level = v
			current_level = current_level
			size_point_cost_array()

var changing_current_level_by_script := false
@export var current_level: int = 0:
	set(v):
		if !setup:
			current_level = v
			return
		# Do not allow changing the value of current level in inspector alone
		# Must use buttons to use level_up and level_down functions
		if !changing_current_level_by_script:
			return

		var keep_change := true

		if !override_checks:
			if v > max_level:
				print("Cannot be levelled up as cannot be higher than max level.")
				keep_change = false
			elif v < 0:
				print("Cannot be levelled down as cannot be lower than 0.")
				keep_change = false

		# Cannot decrease level if cannot be regressed
		if v < current_level and !override_checks:
			if attached_node and !attached_node.can_be_regressed:
				print("Cannot be levelled down as that would cause issues for result skills.")
				keep_change = false
		if v > current_level and !override_checks:
			if attached_node and !attached_node.can_be_progressed:
				print("Cannot be levelled up as previous skills not all unlocked.")
				keep_change = false

		if !keep_change:
			return
		else:
			current_level = clampi(v, 0, max_level)

@export_tool_button("Level Up")
var but_levelup = _progress_skill

@export_tool_button("Level Down")
var but_leveldown = _regress_skill

@export_tool_button("Increase Max and Current Level")
var but_increasemaxandcurrentlevel = func():
	override_checks = true
	max_level += 1
	current_level += 1
	override_checks = false

@export_tool_button("Decrease Max and Current Level")
var but_decreasemaxandcurrentlevel = func():
	override_checks = true
	if current_level != max_level:
		current_level -= 1
	max_level -= 1
	override_checks = false

@export var point_cost_per_level: Array[int]:
	set(v):
		# Prevents setting any point costs to negative values
		for c in v:
			if c < 0:
				return
		# Prevent adding or removing point costs from the array
		# This keeps the array the same length as max level
		if len(v) != max_level:
			return
		point_cost_per_level = v


func size_point_cost_array():
	while len(point_cost_per_level) < max_level:
		point_cost_per_level.append(0)
	while len(point_cost_per_level) > max_level:
		point_cost_per_level.pop_back()

	notify_property_list_changed()


func _is_completed() -> bool:
	return current_level == max_level


func _is_unlocked() -> bool:
	return current_level > 0


func _progress_skill():
	if !attached_node or attached_node.can_be_progressed:
		changing_current_level_by_script = true
		current_level += 1
		changing_current_level_by_script = false


func _regress_skill():
	if !attached_node or attached_node.can_be_regressed:
		changing_current_level_by_script = true
		current_level -= 1
		changing_current_level_by_script = false


func _get_progress_text() -> String:
	return "LVL " + str(current_level) + "/" + str(max_level)


func _decide_single_upgrade_point_cost() -> int:
	# Currently Level 0 - Return 1st element (0 index) for cost to up to level 1
	# Currently Level 1 - Return 2nd element (1 index) for cost to up to level 2
	# etc
	if current_level == max_level:
		return 0
	return point_cost_per_level[current_level]


func _decide_full_upgrade_point_cost() -> int:
	# Currently Level 0 - Return total elements from index 0 -> End
	# Currently Level 1 - Return total elements from index 1 -> End
	# etc
	var result: int = 0
	for i in range(len(point_cost_per_level)):
		if i >= current_level:
			result += point_cost_per_level[i]
	return result
