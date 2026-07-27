@tool
class_name SkillNodeConnection
extends Control

@export var start_node: SkillNode:
	set(v):
		start_node = v
@export var end_node: SkillNode:
	set(v):
		end_node = v
@export var unlock_condition: UnlockCondition:
	set(v):
		if v is ThresholdLevel_UC and start_node and start_node.unlock_type is SingleLevel_UT:
			print("Cannot choose threshold level unlock condition as start node is not a levelling skill.")
			return
		if v is ThresholdLevel_UC and end_node and end_node.is_unlocked():
			var uc: ThresholdLevel_UC = v
			if start_node:
				var start_node_lvl = start_node.unlock_type.get("current_level")
				if uc.threshold_level > start_node_lvl:
					print("Cannot choose threshold level unlock condition as start node is not levelled up enough and it would cause invalidity with result skills.")
					return
		if v is FullUnlock_UC and end_node and end_node.is_unlocked():
			if start_node and !start_node.is_completed():
				print("Cannot choose full unlock condition as start node is not fully unlocked and it would cause invalidity with result skills.")
				return
		unlock_condition = v
var arc_sub_nodes: Array[ConnectionSubNode]:
	set(_v):
		return
	get:
		var result: Array[ConnectionSubNode] = []
		for child in get_children():
			if child is ConnectionSubNode:
				result.append(child)
		return result

@export var node_arc: ColorRect
@export var shader_arc: ColorRect
@export var arrow: TextureRect
@export var shader_arrow: TextureRect

@export var arrow_visible: bool = true
