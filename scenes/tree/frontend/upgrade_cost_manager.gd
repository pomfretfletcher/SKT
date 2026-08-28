@tool
@icon("res://addons/at-icons/node/coins.svg")
class_name SKT_UpgradeCostManager
extends Node

enum UpgradeType {
	NONE,
	SP,
}
@export var upgrade_type: UpgradeType

@export var current_sp: int = 30:
	set(v):
		if v < 0:
			MessageLogger.log_issue("Cannot set current sp to a negative value.")
			return
		current_sp = v


func can_afford_node(node: SkillNode) -> bool:
	if node.unlock_type == null:
		return false
	match upgrade_type:
		UpgradeType.SP:
			return node.unlock_type._decide_single_upgrade_point_cost() <= current_sp
	return true


func purchase_unlock_cost(cost: int):
	match upgrade_type:
		UpgradeType.SP:
			current_sp -= cost


func refund_unlock_cost(cost: int):
	match upgrade_type:
		UpgradeType.SP:
			current_sp += cost
