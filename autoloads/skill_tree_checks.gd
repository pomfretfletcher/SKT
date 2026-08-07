@tool
extends Node

## Used by any node that has exported data that refers to the progression tier system. If said
## system is not in use, it expects that node to set the property usage to not be shown in the
## editor.
func should_show_progression_tiers() -> bool:
	# Get the ProgressionTierManager node
	var s: Script = SKT_ProgressionTierManager.new().get_script()
	var progression_tier_manager: SKT_ProgressionTierManager = GDFunctions.GetChildOfType(
		get_tree().current_scene if not Engine.is_editor_hint() else get_tree().edited_scene_root,
		s.get_global_name(),
	)

	# If Manager not found, assert error
	assert(progression_tier_manager != null)

	# Returns whether exported data should be shown
	return progression_tier_manager.use_progression_tiers


## For use by skill data resources owned by skill nodes. Allows storing validity checking
## externally to that class, in order to abstract use of it.
## [br][br]
## This is stored in skill tree checks, and should any new unlock condition and/or unlock types
## be implemented customly, their validity for deciding whether a given unlock condition is
## suitable for the skill tree's current state can be checked here.
## [br][br]
## This is a function that should be changed by users of the SKT software if they add more
## unlock types. Do avoid interfering with already present checks in order to maintain tree
## logic.
## [br][br]
## Validity examples include deciding whether an unlock type is suitable given the unlock
## conditions reliant on it, such as not being able to have a single level skill when a branch
## resulting from that skill requires a threshold level to be active.
func is_new_unlock_type_valid(ut: UnlockType, node: SkillNode) -> ValidityStatement:
	#region Default SKT Checks
	# If a resulting branch needs this node to be a levelling skill, cannot change it to a 
	# single level type
	if ut is SingleLevel_UT and node:
		for branch in node.result_branches:
			if branch.unlock_condition is ThresholdLevel_UC:
				return ValidityStatement.new(false, "Cannot change to a single level unlock type as a branch from this node needs a threshold level.")
	#endregion
	#region Custom Checks
	""" 
	Replace this comment with any custom checks for deciding whether the unlock type is valid for
	the given node and the current skill tree overall.
	"""
	#endregion

	# If passed all checks, unlock type is a valid choice
	return ValidityStatement.new(true)


## For use by skill branches. Allows storing validity checking externally to that class, in 
## order to abstract use of it.
## [br][br]
## This is stored in skill tree checks, and should any new unlock condition and/or unlock types
## be implemented customly, their validity for deciding whether a given unlock condition is
## suitable for the skill tree's current state can be checked here.
## [br][br]
## This is a function that should be changed by users of the SKT software if they add more
## unlock conditions. Do avoid interfering with already present checks in order to maintain tree
## logic.
## [br][br]
## Validity examples include deciding whether an unlock condition requires a levelling skill
## at the start of the branch and therefore returning false validity if the start node only
## has one progress step.
func is_new_unlock_condition_valid(uc: UnlockCondition, branch: SkillBranch) -> ValidityStatement:
	# Get easier access to branch components
	var start_node: SkillNode = branch.start_node
	var end_node: SkillNode = branch.end_node

	if start_node == null or end_node == null:
		return

	#region Default SKT Checks
	# If the start node of the branch is not a levelling skill, cannot choose threshold level
	# which needs a levelling skill
	if uc is ThresholdLevel_UC and start_node and start_node.unlock_type.get("current_level") == null:
		return ValidityStatement.new(false, "Cannot choose threshold level unlock condition as start node is not a levelling skill.")

	# If the node at the end of the branch is unlocked, cannot change to a new unlock condition 
	# that would cause the branch's unlock condition to no longer be reached
	if uc is ThresholdLevel_UC and end_node and end_node.is_unlocked():
		uc = uc as ThresholdLevel_UC
		if start_node:
			var start_node_lvl = start_node.unlock_type.get("current_level")
			if uc.threshold_level > start_node_lvl:
				return ValidityStatement.new(false, "Cannot choose threshold level unlock condition as start node is not levelled up enough and it would cause invalidity with result skills.")

	# If the node at the end of the branch is unlocked, cannot change to a new unlock condition 
	# that would cause the branch's unlock condition to no longer be reached
	if uc is FullUnlock_UC and end_node and end_node.is_unlocked():
		if start_node and not start_node.is_completed():
			return ValidityStatement.new(false, "Cannot choose full unlock condition as start node is not fully unlocked and it would cause invalidity with result skills.")
	#endregion
	#region Custom Checks
	""" 
	Replace this comment with any custom checks for deciding whether the unlock condition is 
	valid for the given node and the current skill tree overall.
	"""
	#endregion

	# If passed all checks, unlock condition is a valid choice
	return ValidityStatement.new(true)


## For use by the threshold level unlock condition of branches. Allows storing validity checking 
## externally to that class, in order to abstract use of it.
## [br][br]
## This is stored in skill tree checks, and should any new unlock type be implemented customly 
## that would interact with the threshold level for whether nodes are unlocked (such as a new 
## levelling skill unlock type), the validity for deciding whether the new threshold level is
## suitable for the skill tree's current state can be checked here.
## [br][br]
## This is a function that should be changed by users of the SKT software if they add more
## interactions with the threshold level unlock condition. Do avoid interfering with already 
## present checks in order to maintain tree logic.
func is_new_threshold_level_valid(new_v: int, uc: ThresholdLevel_UC) -> ValidityStatement:
	var branch: SkillBranch = uc.attached_branch
	var old_v: int = uc.threshold_level

	if branch == null or branch.start_node == null:
		return

	#region Default SKT Checks
	if branch.start_node.unlock_type.get("max_level"):
		var m = branch.start_node.unlock_type.get("max_level")
		if new_v > m:
			return ValidityStatement.new(false, "Cannot change threshold level as cannot be higher than start nodes's maximum level.")

	# Checks whether changing threshold level would cause end node of branch to be invalid (where
	# it should not be able to be unlocked, but is)
	if uc.is_condition_reached(branch) and branch.end_node.is_unlocked():
		uc.changing_threshold_level_for_test = true
		uc.threshold_level = new_v
		if not uc.is_condition_reached(branch):
			uc.threshold_level = old_v
			uc.changing_threshold_level_for_test = false
			return ValidityStatement.new(false, "Cannot change threshold level as would cause invalidity for end node on branch.")
		uc.threshold_level = old_v
		uc.changing_threshold_level_for_test = false
	#endregion
	#region Custom Checks
	""" 
	Replace this comment with any custom checks for deciding whether the new threshold level is 
	valid for the given unlock type and the current skill tree overall.
	"""
	#endregion

	# If passed all checks, theshold level is valid
	return ValidityStatement.new(true)


## For use by the multi level unlock type for skills. Allows storing validity checking externally 
## to that class, in order to abstract use of it.
## [br][br]
## This is stored in skill tree checks, and should any new unlock condition be implemented 
## customly that would interact with the max level for whether nodes are unlocked, the validity 
## for deciding whether the new threshold level is suitable for the skill tree's current state 
## can be checked here.
## [br][br]
## This is a function that should be changed by users of the SKT software if they add more
## interactions with the multi level unlock type and its max level property. Do avoid interfering 
## with already present checks in order to maintain tree logic.
func is_new_max_level_valid(new_v: int, ut: MultiLevel_UT) -> ValidityStatement:
	var node: SkillNode = ut.attached_node

	if node == null:
		return

	#region Default SKT Checks
	for branch in node.result_branches:
		if branch.unlock_condition is ThresholdLevel_UC:
			if new_v < branch.unlock_condition.get("threshold_level"):
				return ValidityStatement.new(false, "Cannot change max level as it would be lower than a threshold level resulting from this skill.")

	# Checks whether changing the max level would change any of the branch conditions from being
	# reached to not reached. (Going from not reached to reached is fine)
	var cur_condition_bools: Array[bool] = []
	var new_condition_bools: Array[bool] = []

	for branch in node.result_branches:
		cur_condition_bools.append(branch.unlock_condition.is_condition_reached(branch))

	var prev_value: int = ut.max_level
	ut._changing_max_level_for_test = true
	ut.max_level = new_v
	ut._changing_max_level_for_test = false

	for branch in node.result_branches:
		new_condition_bools.append(branch.unlock_condition.is_condition_reached(branch))

	ut._changing_max_level_for_test = true
	ut.max_level = prev_value
	ut._changing_max_level_for_test = false

	if cur_condition_bools != new_condition_bools:
		for i in range(len(cur_condition_bools)):
			if cur_condition_bools[i] != new_condition_bools[i]:
				if new_condition_bools[i] == false:
					return ValidityStatement.new(false, "Cannot change max level as it would cause invalidity for result skills.")
	#endregion
	#region Custom Checks
	""" 
	Replace this comment with any custom checks for deciding whether the new max level is 
	valid for the given unlock type and the current skill tree overall.
	"""
	#endregion

	# If passed all checks, theshold level is valid
	return ValidityStatement.new(true)


## For use by the multi level unlock type for skills. Allows storing validity checking externally 
## to that class, in order to abstract use of it.
## [br][br]
## This is stored in skill tree checks, and should any new unlock condition be implemented 
## customly that would interact with the current level for whether nodes are unlocked, the validity 
## for deciding whether the new threshold level is suitable for the skill tree's current state 
## can be checked here.
## [br][br]
## This is a function that should be changed by users of the SKT software if they add more
## interactions with the multi level unlock type and its current level property. Do avoid 
## interfering with already present checks in order to maintain tree logic.
func is_new_current_level_valid(new_v: int, ut: MultiLevel_UT) -> ValidityStatement:
	var max_level: int = ut.max_level
	var cur_v: int = ut.current_level
	var node: SkillNode = ut.attached_node

	if node == null:
		return

	#region Default SKT Checks
	if new_v > max_level:
		return ValidityStatement.new(false, "Cannot be levelled up as cannot be higher than max level.")
	elif new_v < 0:
		return ValidityStatement.new(false, "Cannot be levelled down as cannot be lower than 0.")

	if new_v < cur_v and not node.can_be_regressed:
		return ValidityStatement.new(false, "Cannot be levelled down as that would cause issues for result skills.")
	if new_v > cur_v and not node.can_be_progressed:
		return ValidityStatement.new(false, "Cannot be levelled up as previous skills not all unlocked.")
	#endregion
	#region Custom Checks
	""" 
	Replace this comment with any custom checks for deciding whether the new current level is 
	valid for the given unlock type and the current skill tree overall.
	"""
	#endregion

	# If passed all checks, theshold level is valid
	return ValidityStatement.new(true)
