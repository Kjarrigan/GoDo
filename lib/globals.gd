extends Node

signal item_selected(item)
signal item_changed()

var root_list
var active_item : Entry
const INDENT = 20
const SAVE_FILE = "user://godo.json"
var task_id = 0

@onready var entry = preload("res://lib/entry.tscn")
@onready var input = preload("res://lib/input.tscn")

func _ready():
	item_selected.connect(func(item): active_item = item)
	item_changed.connect(func(): save_tasks())

func _unhandled_input(event):		
	if event.is_action_pressed("add_below"):
		if active_item:
			if active_item.get_meta("subgroup"):
				new_input(active_item.get_meta("subgroup"))
			else:
				var sub_list = add_nested_list(active_item)
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
		item_selected.emit(null)
		return

	# Save/Load via buttons is only intended for debugging
	if OS.has_feature("editor"):
		if event.is_action_pressed("save"):
			save_tasks()

		if event.is_action_pressed("load"):
			load_tasks()

func new_input(parent):
	var inp = input.instantiate()
	inp.set_meta("parent", parent)
	parent.add_child(inp)
	inp.grab_focus()
	
func add_task(ref, new_text) -> Entry:	
	var item = entry.instantiate()
	item.name = "task-%d" % next_task_id()
	item.text = new_text
	ref.add_child(item)
	return item
	
func next_task_id() -> int:
	task_id += 1
	return task_id
	
func add_nested_list(ref) -> VBoxContainer:
	var group = MarginContainer.new()
	group.add_theme_constant_override("margin_left", INDENT)
	group.name = ref.name + "-children"
	var sub_list = VBoxContainer.new()
	group.add_child(sub_list)
	ref.set_meta("subgroup", sub_list)
	ref.add_sibling(group)
	return sub_list

func save_tasks():
	var save_data = { 
		"exported_at": Time.get_datetime_string_from_system(),
		"tasks": _save_nested_tasks(root_list),
	}
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)	
	file.store_line(JSON.stringify(save_data))

func _save_nested_tasks(list) -> Array:
	var tasks = []
	for ele in list.get_children():
		if ele is Entry:
			tasks.push_back(ele.save())	
	return tasks

func load_tasks():
	if not FileAccess.file_exists(SAVE_FILE):
		return
				
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_line())
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message())
		return

	var data = json.get_data().get("tasks")
	if data is Array and len(data) > 0:	
		for ele in root_list.get_children():
			ele.queue_free()
		_load_nested_tasks(root_list, data)
		
func _load_nested_tasks(ref, list):
	for ele in list:
		var item = add_task(ref, ele["name"])
		if ele.get("tasks"):
			var sub_list = add_nested_list(item)
			_load_nested_tasks(sub_list, ele["tasks"])
