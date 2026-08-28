@tool
class_name SKT
extends Control

static var s: SKT
static var screen_SKT_tree: SKT_Tree:
	set(v):
		screen_SKT_tree = v
		if v != null:
			s.connect_skt_tree_signals()
@export var tree: SKT_Tree:
	set(v):
		tree = v
		screen_SKT_tree = v
static var screen_2D_tree: SKT_Tree
static var current_use_screen: EditorScreen

@export var camera: Camera2D

static var current_tree: SKT_Tree:
	get:
		if current_use_screen == EditorScreen.SCREEN_2D:
			return screen_2D_tree
		elif current_use_screen == EditorScreen.SCREEN_SKT:
			return screen_SKT_tree
		return null

var selected_control: SkillTreeControl:
	set(v):
		selected_control = v
		selected_control_changed.emit(v)

enum EditorScreen {
	SCREEN_2D,
	SCREEN_SKT,
	SCREEN_OTHER
}

func _init() -> void:
	if s == null:
		s = self


func connect_skt_tree_signals() -> void:
	screen_SKT_tree.node_selected.connect(
		func(node):
			selected_control = node
	)
	screen_SKT_tree.branch_selected.connect(
		func(branch):
			selected_control = branch
	)
	screen_SKT_tree.followpoint_selected.connect(
		func(follow_point):
			selected_control = follow_point
	)
	
@warning_ignore("unused_signal")
signal request_refresh_screen
@warning_ignore("unused_signal")
signal selected_control_changed(control: SkillTreeControl)
