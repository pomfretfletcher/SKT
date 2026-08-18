@tool
@icon("res://addons/at-icons/node/staircase.svg")
class_name SKT_ProgressionTierManager
extends Node

## Tells the skill tree whether progression tier data should be shown, allowed to change, and
## used within logic processes.
## [br][br]
## Toggling this off will automatically hide any progression tier data from being shown on
## nodes that would have them, such as the SkillNode control where its progression_tier int will
## be hidden in the inspector.
## [br][br]
## Progression tiers are explained more in main documentation but simply, a progression tier acts
## as a way to stop the user progressing in skills that are a higher tier than the current tier
## decided within this manager. If the user has access to tier 3 and below, they are not able
## to progress in skills that are tier 4 or higher. Check documentation for this manager's
## current_tier property for how to advance in tiers.
@export var use_progression_tiers: bool

## This is a 2D array structure designed to display the nodes that are present within each
## progression tier. This serves no functional use, but simply allows a better visualization
## of the tiers for use of the skill tree system in a project.
## [br][br]
## This structure should not, and cannot be changed manually in the inspector, and should only
## be changed by the internal function display_tiers(). This will be updated whenever the
## update_tree SkillTreeEvent is called.
@export var tiers: Array[Array]:
	set(v):
		if not _changing_by_code:
			return
		tiers = v

## Stores the current progression tier of nodes that can be unlocked if progression tiers are
## in use within the current tree. If the current tier is 3 for example, skill nodes with a
## progression tier of 3 or below are able to be progressed (assuming all other requirements for
## them being progressed are also true), and skill nodes with tiers of 4 or higher can't be
## progressed.
## [br][br]
## Current tier can be set manually, this could be done by for example a levelling system could
## open another tier for progressing when a certain level milestone is reached. There is no
## proper way to make conditions for this within the SKT system as it would not be able to be 
## suitable for any project it is in use for, thus this is one of the features that skill tree
## creators will externally interact with within the SKT system.
## [br][br]
## Importantly, when externally changing the current tier of the progression tier manager, if a
## new value would cause any nodes that are already unlocked to be invalid, the change will be
## rejected. This means if there is a skill node with progression tier 4 unlocked, and the current
## tier is attempted to change to tier 3, the change would be rejected as then that node would
## be labelled as invalid. In order to avoid issues like this, you must first regress any skills
## that are of a higher progression tier than the new value.
@export var current_tier: int:
	set(v):
		if not _setup:
			current_tier = v
			return

		for node in SKT.nodes_parent.get_nodes():
			if node.is_unlocked() and node.progression_tier > v:
				SkillTreeRequests.request_log_issue.emit("Cannot change current tier as there are unlocked nodes with a progression tier that would be invalid at the new tier.")
				return
		current_tier = v

@export_subgroup("Tool Buttons")
@export_tool_button("Update Tiers")
var but_updatetiers = display_tiers

var _changing_by_code := false
var _setup := false


func _ready() -> void:
	if not SkillTreeEvents.update_tree.is_connected(display_tiers):
		SkillTreeEvents.update_tree.connect(display_tiers)
	SkillTreeRequests.request_prepare_for_load.connect(
		func():
			_setup = false
	)
	SkillTreeEvents.data_loaded.connect(
		func():
			_setup = true
	)
	display_tiers()


func display_tiers():
	var seen_tiers: Array[int] = []
	var tiers_dict: Dictionary[int, Array]
	_changing_by_code = true
	tiers.clear()

	if not use_progression_tiers or SKT.tree == null:
		return
	for node in SKT.nodes_parent.get_nodes():
		if node.progression_tier not in seen_tiers:
			seen_tiers.append(node.progression_tier)
			var new_array: Array[NodePath]
			new_array.append("Tier " + str(node.progression_tier))
			tiers_dict.set(node.progression_tier, new_array)
		var array: Array = tiers_dict.get(node.progression_tier)
		array.append(node.get_path())

	for tier in tiers_dict.values():
		tiers.append(tier)

	_changing_by_code = false
