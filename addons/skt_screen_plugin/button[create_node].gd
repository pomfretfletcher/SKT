@tool
extends SKT_Button

@export var panel: SKT

func _ready() -> void:
	set_button_active()
	panel.selected_control_changed.connect(
		func(control):
			if control == null:
				set_button_active()
			else:
				set_button_inactive()
	)
