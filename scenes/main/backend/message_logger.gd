@tool
@icon("res://addons/at-icons/node/speech_bubble_ellipsis.svg")
class_name SKT_MessageLogger
extends Node

func _ready() -> void:
	if not SkillTreeRequests.request_log_process.is_connected(log_process):
		SkillTreeRequests.request_log_process.connect(log_process)
	if not SkillTreeRequests.request_log_issue.is_connected(log_issue):
		SkillTreeRequests.request_log_issue.connect(log_issue)


func log_process(s: String):
	print(s)


func log_issue(s: String):
	print(s)
