extends Node

signal item_selected(item)
var root_list
var active_item : Entry

@onready var input = preload("res://input.tscn")

func _ready():
	item_selected.connect(func(item): active_item = item)

func _unhandled_input(event):		
	# TODO, formatting of subgroups is currently broken
	if event.is_action_pressed("add_below"):
		if active_item:
			new_input(active_item)
		else:
			new_input(root_list)
		return
	if event.is_action_pressed("add_same_level"):
		if active_item:
			new_input(active_item.get_parent())
		else:
			new_input(root_list)

func _input(event):
	if event.is_action_pressed("deselect"):
		print_debug("RMB")
		item_selected.emit(null)

func new_input(parent):
	var inp = input.instantiate()
	inp.set_meta("parent", parent)
	parent.add_child(inp)
	inp.grab_focus()
