@tool
class_name SKT_TreeDrawer
extends Node

@export var can_draw: bool = true
var prev_state: bool = true

var draw_interval: float = 0.01


func _ready() -> void:
	await SkillTreeEvents.tree_setup
	SkillTreeEvents.toggle_drawing.connect(
		func(active):
			can_draw = active
	)
	draw()


func _process(_delta: float) -> void:
	if can_draw and can_draw != prev_state:
		prev_state = can_draw
		draw()
	if !can_draw and can_draw != prev_state:
		prev_state = can_draw


func draw() -> void:
	while can_draw:
		if get_tree():
			await get_tree().create_timer(draw_interval).timeout
			SkillTreeEvents.draw_tree.emit()
