@tool
class_name MultiLevel_UT
extends UnlockType

# Internal status variables
var _changing_max_level_for_test := false
var _changing_current_level_by_script := false

# Variables for progressing through skill node
## The maximum amount of times the unlock type/skill node can be progressed.
@export var max_level: int:
	set(v):
		# When reconstructing a saved skill tree, we simply need to produce the saved 
		# state. However during this recreation phase, the checks done within 
		# SkillTreeChecks will almost always come out as false as only part of it is 
		# completed and 'valid' until recreation is fully done. We use the _setup 
		# variable to make sure that we can recreate the saved state without having 
		# to check validity.
		if not _setup:
			max_level = v
			size_point_cost_array()
			return

		# When checking validity of the new max level value, we must test whether the 
		# max level changing causes any invalidity. Thus, we use this boolean value to 
		# make sure it does not attempt to change max level to check the change and 
		# then ask skilltreechecks to make another validity check. Without this, it 
		# would cause a recursion loop and the software would crash.
		if _changing_max_level_for_test:
			max_level = v
			return

		# The attached node not being a value should not be an issue, however this is 
		# here in order to prevent errors or crashes should any issue with that come up. 
		# It will log this error so debugging can be taken out while not causing 
		# problems with running the validity checks.
		if attached_node == null:
			SkillTreeRequests.request_log_issue.emit("Attached node of " + str(self) + " is null.")
			return

		var result: ValidityStatement = SkillTreeChecks.is_new_max_level_valid(v, self)

		if result == null:
			return
		elif result.validity == true:
			max_level = v
			current_level = current_level
			size_point_cost_array()
		else:
			SkillTreeRequests.request_log_issue.emit(result.reason)
## The amount of times that the unlock type/skill node has been progressed.
@export var current_level: int = 0:
	set(v):
		# When reconstructing a saved skill tree, we simply need to produce the saved 
		# state. However during this recreation phase, the checks done within 
		# SkillTreeChecks will almost always come out as false as only part of it is 
		# completed and 'valid' until recreation is fully done. We use the _setup 
		# variable to make sure that we can recreate the saved state without having to 
		# check validity.
		if not _setup:
			current_level = v
			return

		# Prevents changing of current level by any means other than through this 
		# class's _progress_skill and _regress_skill methods.
		if not _changing_current_level_by_script:
			return

		# The attached node not being a value should not be an issue, however this is 
		# here in order to prevent errors or crashes should any issue with that come up. 
		# It will log this error so debugging can be taken out while not causing 
		# problems with running the validity checks.
		if attached_node == null:
			return

		var result: ValidityStatement = SkillTreeChecks.is_new_current_level_valid(v, self)

		if result == null:
			return
		elif result.validity == true:
			current_level = clampi(v, 0, max_level)
		else:
			SkillTreeRequests.request_log_issue.emit(result.reason)
## The cost to progress to each level. Each element represents the cost to progress
## to the next level. Due to zero-indexing, the 0-index element is the cost to level
## to level 1, etc.
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

#region Inspector Tool Buttons
@export_tool_button("Level Up")
var but_levelup = func():
	SkillTreeRequests.request_progress_skill.emit(attached_node)
@export_tool_button("Level Down")
var but_leveldown = func():
	SkillTreeRequests.request_regress_skill.emit(attached_node)
#endregion

## Internal function that will add or remove elements from the point_cost_per_level
## in order to have a point cost available for each level up to this skill's
## max level. Called whenever max level is changed in order to keep inspector parity.
func size_point_cost_array():
	var temp: Array[int] = point_cost_per_level.duplicate()

	# Fill the array with 0-costs or remove cost element until there is an
	# element for each level up to max level. For example, if max level is now 3 and
	# was priorly 5, it will pop the last two cost elements. Or if max level goes from
	# 4 to 7, three 0-cost elements will be appended to correspond to the new levels
	while len(temp) < max_level:
		temp.append(0)
	while len(temp) > max_level:
		temp.pop_back()

	point_cost_per_level = temp
	# Forces new array to be displayed in inspector
	notify_property_list_changed()

#region Override Unlock Type Methods
func _is_completed() -> bool:
	return current_level == max_level


func _is_unlocked() -> bool:
	return current_level > 0


func _progress_skill():
	_changing_current_level_by_script = true
	current_level += 1
	_changing_current_level_by_script = false


func _regress_skill():
	_changing_current_level_by_script = true
	current_level -= 1
	_changing_current_level_by_script = false


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


func _store_upgrade_cost_property_name():
	UPGRADE_COST_PROPERTY_NAME = "point_cost_per_level"
#endregion
