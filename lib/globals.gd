extends Node

signal item_selected(item)
signal item_changed() # TODO, remove
signal save_data()
signal change_workspace(direction : int)
signal rename_workspace(new_name)

var root_list
var menu
var active_item : Entry
var labels = {}
const INDENT = 20
const SAVE_FILE = "user://godo_%d.json"
const LABEL_FILE = "user://labels.json"
var global_task_id = 0
var current_workspace_id = 0

@onready var entry = preload("res://lib/entry.tscn")
@onready var input = preload("res://lib/input.tscn")

func _ready():
	item_selected.connect(func(item): active_item = item)
	save_data.connect(func(): save_tasks(current_workspace_id))
	change_workspace.connect(func (dir : int): load_or_create_workspace(dir))
	load_labels()

func _unhandled_input(event):		
	if event.is_action_pressed("add_below"):
		if active_item:
			var sub_list = active_item.add_subtask_container()
			new_input(sub_list)
		else:
			new_input(root_list)
		return
	if event.is_action_pressed("add_same_level"):
		if active_item:
			new_input(active_item.get_parent())
		else:
			new_input(root_list)
		return
		
	if event.is_action_pressed("rename"):
		if active_item:
			active_item.rename()
			return
		else:
			print_debug("Rename workspace")
			rename_workspace.emit(false)
			return
	
	var number_key = int(event.as_text())
	if event.is_pressed() and number_key >= 0 and number_key <= 9:
		if active_item:
			active_item.set_label(number_key)
		return
			
func _input(event):
	if event.is_action_pressed("deselect"):
		item_selected.emit(null)
		return

	# Save/Load via buttons is only intended for debugging
	if OS.has_feature("editor"):
		if event.is_action_pressed("save"):
			save_tasks(0)

		if event.is_action_pressed("load"):
			load_tasks(0)

func new_input(parent):
	var inp = input.instantiate()
	inp.set_meta("parent", parent)
	parent.add_child(inp)
	inp.grab_focus()
	
func add_task(ref, new_text) -> Entry:	
	var item = entry.instantiate()
	item.name = "task-%d" % next_global_task_id()
	item.text = new_text
	ref.add_child(item)
	return item
	
func next_global_task_id() -> int:
	global_task_id += 1
	return global_task_id
	
func save_tasks(file_id):
	var data = { 
		"exported_at": Time.get_datetime_string_from_system(),
		"workspace": menu.workspace_name(),
		"tasks": _save_nested_tasks(root_list),
	}
	if len(data["tasks"]) == 0:
		return false
		
	var file = FileAccess.open(SAVE_FILE % file_id, FileAccess.WRITE)	
	file.store_line(JSON.stringify(data))

func _save_nested_tasks(list) -> Array:
	var tasks = []
	for ele in list.get_children():
		if ele is Entry and not ele.is_queued_for_deletion():
			tasks.push_back(ele.to_dict())	
	return tasks

func load_tasks(file_id):
	var save_file = SAVE_FILE % file_id
	print_debug("Load file %s" % save_file)
	
	if not FileAccess.file_exists(save_file):
		return false
				
	var file = FileAccess.open(save_file, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_line())
	file = null
	
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message())
		return false
	
	var data = json.get_data()
	var workspace_title = data.get("workspace")
	if workspace_title == null:
		workspace_title = "Workspace %d" % file_id
	rename_workspace.emit(workspace_title)
	
	var tasks = data.get("tasks")
	if tasks is Array and len(tasks) > 0:
		clear_list()
		_load_nested_tasks(root_list, tasks)
	
	return true
		
func clear_list():
	for ele in root_list.get_children():
		ele.queue_free()	

func _load_nested_tasks(ref, list):
	for ele in list:
		var item = add_task(ref, ele["name"])
		if ele.get("tasks"):
			var sub_list = item.add_subtask_container()
			_load_nested_tasks(sub_list, ele["tasks"])
			if ele.get("collapsed"):
				item.toggle_children_visibility()
		if ele.get("label_id"):
			item.set_label(ele.get("label_id"))

func load_or_create_workspace(dt_index):
	if current_workspace_id == 0 and dt_index == -1:
		return

	# Save before changing workspace
	save_tasks(current_workspace_id)

	current_workspace_id += dt_index
	print_debug("Change workspace to %d" % current_workspace_id)
	if load_tasks(current_workspace_id):
		return
	else: # Workspace does not exist yet
		clear_list()
		%WorkspaceTitle.text = "Workspace %d" % current_workspace_id
		new_input(root_list)

func load_labels():
	if not FileAccess.file_exists(LABEL_FILE):
		return false
				
	var file = FileAccess.open(LABEL_FILE, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_line())
	file = null
	
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message())
		return false

	var data = json.get_data()
	for key in data: 
		var lbl = TaskLabel.new()
		lbl.id = int(key)
		lbl.name = data[key]["name"]
		lbl.color = Color(data[key]["color"])
		labels[int(key)] = lbl
