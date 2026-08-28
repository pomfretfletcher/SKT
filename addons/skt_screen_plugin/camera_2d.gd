@tool
extends Camera2D

@export var drag_speed: float = 10.0
@export var viewport: SubViewport
var last_drag_pos: Vector2
var dragging := false

func _on_gui_input(event: InputEvent) -> void:
	if SKT.current_use_screen == SKT.EditorScreen.SCREEN_SKT:
		if event is InputEventMouseButton and event.pressed:
			event = event as InputEventMouseButton
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom = zoom + Vector2(0.1, 0.1)
				offset += (event.position - Vector2(viewport.size / 2)) * 0.1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom = zoom - Vector2(0.1, 0.1) if zoom.x > 0.1 else zoom
				offset += 0.1 * (event.position - Vector2(viewport.size / 2))
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if not dragging:
					dragging = true
					last_drag_pos = event.position
		if event is InputEventMouseButton and not event.pressed: # Released
			event = event as InputEventMouseButton
			if event.button_index == MOUSE_BUTTON_LEFT:
				if dragging:
					dragging = false
					last_drag_pos = Vector2.ZERO
		if event is InputEventMouseMotion:
			event = event as InputEventMouseMotion
			if event.button_mask == MOUSE_BUTTON_LEFT and dragging:
				offset += event.position.direction_to(last_drag_pos) * drag_speed
				last_drag_pos = event.position
