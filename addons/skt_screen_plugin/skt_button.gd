@tool
class_name SKT_Button
extends Panel

@export var label_text: String:
	set(v):
		label_text = v
		if v != "" and label != null:
			label.text = v
@export var label: Label

var can_be_pressed := true


# Default GUI Input function, makes sure button data is stored correctly even if no logic
# has been coded in child button class
func _gui_input(event: InputEvent) -> void:
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and can_be_pressed:
		print(label_text)


func set_button_inactive(_context = null):
	can_be_pressed = false
	modulate = Color(0.5, 0.5, 0.5, 0.5)


func set_button_active(_context = null):
	can_be_pressed = true
	modulate = Color(1, 1, 1, 1)
