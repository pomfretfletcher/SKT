@tool
extends Control

@export var panel: SKT
@export var tree: SKT_Tree

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		panel.selected_control = null


#func _process(delta: float) -> void:
	#for branch: SkillBranch in tree.branches_parent.get_branches():
		#print(branch.position)
