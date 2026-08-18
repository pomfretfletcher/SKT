@tool
extends SKT_Button

@export var panel: SKT


func _gui_input(event: InputEvent) -> void:
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and can_be_pressed:
		if panel.tree != null:
			panel.tree.queue_free()
			await get_tree().create_timer(0.1).timeout

		var tree: SKT_Tree = SKT_Tree.new()
		panel.add_child(tree)
		panel.tree = tree
		panel.update_refs()

		print(SKT.nodes_parent)
		SkillTreeRequests.request_load_data.emit()
