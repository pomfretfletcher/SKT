@tool
extends SKT_Button

func _gui_input(event: InputEvent) -> void:
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and can_be_pressed:
		SKTScreenSignals.refresh_skt_screen.emit()
