@tool
@icon("res://addons/at-icons/control/node_graph_node.svg")
class_name BranchFollowPoint
extends SkillTreeControl

@export var arrow_visible := true

@export_subgroup("Visual Component References")
@export var node_arc: ColorRect
@export var shader_arc: ColorRect
@export var arrow: TextureRect
@export var shader_arrow: TextureRect

var silence_signals := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if not silence_signals:
			TreeInteractionSignals.followpoint_moved.emit(self)
