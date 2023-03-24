extends Node

signal item_selected(item)
var root_list
var active_item : Entry
const INDENT = 20

@onready var input = preload("res://lib/input.tscn")

func _ready():
	item_selected.connect(func(item): active_item = item)

func _unhandled_input(event):		
	if event.is_action_pressed("add_below"):
		if active_item:
			if active_item.get_meta("subgroup"):
				new_input(active_item.get_meta("subgroup"))
			else:
				var group = MarginContainer.new()
				group.add_theme_constant_override("margin_left", INDENT)
				var sub_list = VBoxContainer.new()
				group.add_child(sub_list)
				
				active_item.set_meta("subgroup", sub_list)
				active_item.add_sibling(group)
				new_input(sub_list)
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
