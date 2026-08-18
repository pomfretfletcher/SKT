@tool
@abstract
class_name UnlockType
extends Resource

var UPGRADE_COST_PROPERTY_NAME: String

var attached_node: SkillNode

var _setup := false


func _init() -> void:
	SkillTreeEvents.tree_setup.connect(
		func():
			_setup = true
	)
	_store_upgrade_cost_property_name()


@abstract
func _is_unlocked() -> bool


@abstract
func _is_completed() -> bool


@abstract
func _progress_skill()


@abstract
func _regress_skill()


@abstract
func _get_progress_text() -> String


@abstract
func _decide_single_upgrade_point_cost() -> int


@abstract
func _decide_full_upgrade_point_cost() -> int


@abstract
func _store_upgrade_cost_property_name()


func _validate_property(property: Dictionary) -> void:
	if not _setup:
		return
	if property.name == UPGRADE_COST_PROPERTY_NAME:
		if not SkillTreeChecks.should_show_upgrade_costs():
			property.usage = PROPERTY_USAGE_NO_EDITOR
